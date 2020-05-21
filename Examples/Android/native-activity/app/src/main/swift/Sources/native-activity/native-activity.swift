import Foundation
import AndroidSwiftLogcat
import SGLEGL
import SGLOpenGL
import Swift_Android_Glue
import SkiaSwift

public enum DemoError: Error {
    case INIT_EGL_FAIlURE(reason: String)
    case DEINIT_EGL_FAIlURE(reason: String)
}

public protocol SkEglRenderer {
    func onSurfaceCreated(_ surface: Surface) -> Void

    func onSurfaceChanged(_ width: EGLint, _ height: EGLint) -> Void

    func onDrawFrame(_ canvas: Canvas) -> Void
}

public class SkEglSurface {
    static let TAG = "SkEglSurface.swift"

    private var mEglDisplay: EGLDisplay = EGL_NO_DISPLAY
    private var mEglContext: EGLContext = EGL_NO_CONTEXT
    private var mEglSurface: EGLSurface = EGL_NO_SURFACE
    private var mSurfaceWidth: EGLint = 0
    private var mSurfaceHeight: EGLint = 0

    private var mSkContext: Context?
    private var mSkSurface: Surface?

    private var mRenderer: SkEglRenderer

    deinit {
        onTermWindow()
    }

    public init(_ renderer: SkEglRenderer) {
        mRenderer = renderer
    }

    func draw() {
        guard EGL_NO_DISPLAY != mEglDisplay else {
            return
        }

        if let skCanvas = mSkSurface?.canvas {
            mRenderer.onDrawFrame(skCanvas)
        }

        if let skContext = mSkContext {
            skContext.flush()
        }

        eglSwapBuffers(dpy: mEglDisplay, surface: mEglSurface);
    }

    public func onInitWindow(window: EGLNativeWindowType) {
        do {
            let skEglObjs: (EGLDisplay, EGLContext, EGLSurface, EGLint, EGLint, Context, Surface) = try initEglEnv(eglWindow: window)

            mEglDisplay = skEglObjs.0
            mEglContext = skEglObjs.1
            mEglSurface = skEglObjs.2
            mSurfaceWidth = skEglObjs.3
            mSurfaceHeight = skEglObjs.4

            mSkContext = skEglObjs.5
            mSkSurface = skEglObjs.6

            if let surface = mSkSurface {
                mRenderer.onSurfaceCreated(surface)
            }

        } catch DemoError.INIT_EGL_FAIlURE(let reason) {
            AndroidLogcat.e(SkEglSurface.TAG, reason)
        } catch {
            AndroidLogcat.e(SkEglSurface.TAG, "Unknown EGL Init Error!")
        }
    }

    public func onTermWindow() {
        do {
            try deinitEglEnv()
        } catch DemoError.DEINIT_EGL_FAIlURE(let reason) {
            AndroidLogcat.e(SkEglSurface.TAG, reason)
        } catch {
            AndroidLogcat.e(SkEglSurface.TAG, "Unknow EGL Deinit Error!")
        }
    }

    func initEglEnv(eglWindow: EGLNativeWindowType) throws -> (EGLDisplay, EGLContext, EGLSurface, EGLint, EGLint, Context, Surface) {
        //
        // ---------------------------
        let attribs: [EGLint] = [
            EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
            EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
            EGL_BLUE_SIZE, 8,
            EGL_GREEN_SIZE, 8,
            EGL_RED_SIZE, 8,
            EGL_ALPHA_SIZE, 8,
            EGL_STENCIL_SIZE, 8,
            EGL_NONE
        ]

        // Create EGLDisplay
        // ----------------------------
        let eglDisplay: EGLDisplay = eglGetDisplay(display_id: EGL_DEFAULT_DISPLAY)

        guard EGL_NO_DISPLAY != eglDisplay else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglGetDisplay")
        }

        AndroidLogcat.i(SkEglSurface.TAG, "eglDisplay = \(eglDisplay)")

        guard EGL_TRUE == eglInitialize(dpy: eglDisplay, major: nil, minor: nil) else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to initialize EGLDisplay: Call `eglInitialize` fail")
        }

        //
        // ----------------------------
        var numConfig: EGLint = 0
        guard EGL_TRUE == eglChooseConfig(dpy: eglDisplay,
                                          attrib_list: attribs,
                                          configs: nil,
                                          config_size: 0,
                                          num_config: &numConfig) else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to initialize EGLConfig: Call `eglChooseConfig` fail")
        }

        guard numConfig > 0 else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to initialize EGLConfig: Not exist any available EGLConfig.")
        }

        let pSupportedConfigs: UnsafeMutablePointer<EGLConfig> = UnsafeMutablePointer.allocate(capacity: Int(numConfig))
        defer {
            pSupportedConfigs.deinitialize(count: Int(numConfig))
            pSupportedConfigs.deallocate()
        }
        guard EGL_TRUE == eglChooseConfig(dpy: eglDisplay,
                                          attrib_list: attribs,
                                          configs: pSupportedConfigs,
                                          config_size: numConfig,
                                          num_config: &numConfig) else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to initialize EGLConfig: Call `eglChooseConfig` fail")
        }

        var config: EGLConfig? = nil
        for idx in 0..<Int(numConfig) {
            //AndroidLogcat.w(SkEglSurface.TAG, "initEglEnved numConfig[\(idx)] = \(pSupportedConfigs[idx])")
            let cfg: EGLConfig = pSupportedConfigs[idx]
            var r: EGLint = 0
            var g: EGLint = 0
            var b: EGLint = 0
            var a: EGLint = 0

            if EGL_TRUE == eglGetConfigAttrib(dpy: eglDisplay, config: cfg, attribute: EGL_RED_SIZE, value: &r)
               && EGL_TRUE == eglGetConfigAttrib(dpy: eglDisplay, config: cfg, attribute: EGL_GREEN_SIZE, value: &g)
               && EGL_TRUE == eglGetConfigAttrib(dpy: eglDisplay, config: cfg, attribute: EGL_BLUE_SIZE, value: &b)
               && EGL_TRUE == eglGetConfigAttrib(dpy: eglDisplay, config: cfg, attribute: EGL_ALPHA_SIZE, value: &a)
               && r == 8 && g == 8 && b == 8 && a == 8 {
                config = cfg;
                break
            }
        }

        if config == nil {
            config = pSupportedConfigs[0]
        }

        //
        // ----------------------------
        var format: EGLint = 0
        guard EGL_TRUE == eglGetConfigAttrib(dpy: eglDisplay, config: config!, attribute: EGL_NATIVE_VISUAL_ID, value: &format) else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to initialize EGLConfig: Call `eglGetConfigAttrib` fail")
        }

        // Create EGLSurface
        // ----------------------------
        let surfaceAttribs: [EGLint] = [
            EGL_RENDER_BUFFER, EGL_BACK_BUFFER,
            EGL_NONE
        ]
        let eglSurface: EGLSurface = eglCreateWindowSurface(
                dpy: eglDisplay,
                config: config!,
                win: eglWindow,
                attrib_list: surfaceAttribs)

        guard EGL_NO_SURFACE != eglSurface else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglCreateWindowSurface")
        }

        AndroidLogcat.i(SkEglSurface.TAG, "eglSurface = \(eglSurface)")

        // eglSwapBuffers should not automatically clear the screen
        eglSurfaceAttrib(eglDisplay, eglSurface, EGL_SWAP_BEHAVIOR, EGL_BUFFER_PRESERVED);

        var width: EGLint = 0
        guard EGL_TRUE == eglQuerySurface(dpy: eglDisplay, surface: eglSurface, attribute: EGL_WIDTH, value: &width) else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglQuerySurface")
        }
        AndroidLogcat.i(SkEglSurface.TAG, "width = \(width)")

        var height: EGLint = 0
        guard EGL_TRUE == eglQuerySurface(dpy: eglDisplay, surface: eglSurface, attribute: EGL_HEIGHT, value: &height) else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglQuerySurface")
        }
        AndroidLogcat.i(SkEglSurface.TAG, "height = \(height)")

        // Create EGLContext
        // ----------------------------
        let contextAttribs: [EGLint] = [
            EGL_CONTEXT_CLIENT_VERSION, 2,
            EGL_NONE
        ]
        let eglContext: EGLContext = eglCreateContext(dpy: eglDisplay, config: config!, share_context: EGL_NO_CONTEXT, attrib_list: contextAttribs)

        guard EGL_NO_CONTEXT != eglContext else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglCreateContext")
        }

        AndroidLogcat.i(SkEglSurface.TAG, "eglContext = \(eglContext)")

        // Bind eglDisplay + eglSurface + EGLContext
        // ----------------------------
        guard EGL_TRUE == eglMakeCurrent(dpy: eglDisplay, draw: eglSurface, read: eglSurface, ctx: eglContext) else {
            throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglMakeCurrent")
        }

        // Check openGL on the system
        // ----------------------------
        let openglInfo = [GL_VENDOR, GL_RENDERER, GL_VERSION, GL_EXTENSIONS]
        for name in openglInfo {
            let info: UnsafePointer<GLubyte> = glGetString(name)
            AndroidLogcat.i(SkEglSurface.TAG, "OpenGL Info: \(String(cString: info))")
        }

        // Bind skia and opengl
        // ---------------------
        let grContext = Context(backend: Backend.openGl)
        var fbo: GLint = 0
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &fbo)
        var sampleCount: GLint = 0
        glGetIntegerv(GL_SAMPLES, &sampleCount)
        var stencilBits: GLint = 0
        glGetIntegerv(GL_STENCIL_BITS, &sampleCount)
        let renderTarget: RenderTarget = RenderTarget(width: width, height: height, sampleCount: sampleCount, stencilBits: stencilBits, glInfo: GlFramebufferInfo(fFBOID: UInt32(fbo), fFormat: UInt32(ColorType.rgba8888.toGlSizedFormat())))
        let gpuSurface = Surface.gpu(grContext, renderTarget)

        AndroidLogcat.w(SkEglSurface.TAG, "initEglEnved numConfig = \(numConfig), eglWindow = \(eglWindow)")

        return (eglDisplay, eglContext, eglSurface, width, height, grContext, gpuSurface)
    }

    func deinitEglEnv() throws {
        let display = mEglDisplay
        if EGL_NO_DISPLAY != display {
            // Unbind eglDisplay + eglSurface + EGLContext
            // ----------------------------
            guard EGL_TRUE == eglMakeCurrent(dpy: display, draw: EGL_NO_SURFACE, read: EGL_NO_SURFACE, ctx: EGL_NO_CONTEXT) else {
                throw DemoError.DEINIT_EGL_FAIlURE(reason: "Unable to eglMakeCurrent")
            }

            let context = mEglContext
            if EGL_NO_CONTEXT != context {
                guard EGL_TRUE == eglDestroyContext(dpy: display, ctx: context) else {
                    throw DemoError.DEINIT_EGL_FAIlURE(reason: "Unable to eglDestroyContext")
                }
            }

            let surface = mEglSurface
            if EGL_NO_SURFACE != surface {
                guard EGL_TRUE == eglDestroySurface(dpy: display, surface: surface) else {
                    throw DemoError.DEINIT_EGL_FAIlURE(reason: "Unable to eglDestroySurface")
                }
            }

            guard EGL_TRUE == eglTerminate(dpy: display) else {
                throw DemoError.DEINIT_EGL_FAIlURE(reason: "Unable to eglTerminate")
            }

            AndroidLogcat.w(SkEglSurface.TAG, "deinitEglEnv")
        }

        mEglDisplay = EGL_NO_DISPLAY
        mEglContext = EGL_NO_CONTEXT
        mEglSurface = EGL_NO_SURFACE
        mSurfaceWidth = 0
        mSurfaceHeight = 0
    }

}

class SkEglRendererImpl: SkEglRenderer {
    func onSurfaceCreated(_ surface: Surface) {}

    func onSurfaceChanged(_ width: EGLint, _ height: EGLint) {}

    func onDrawFrame(_ canvas: Canvas) {
        // Initialize GL state.
        /*glDisable(GL_DEPTH_TEST);
        glEnable(GL_CULL_FACE);
        glClearColor(
                red: 1.0,
                green: 1.0,
                blue: 1.0,
                alpha: 1.0)
        glClear(mask: GL_COLOR_BUFFER_BIT);*/

        canvas.clear(Color(r: 0, g: 0xB9, b: 0x5B))
        drawBySkiaEngine(canvas)
    }

    func drawBySkiaEngine(_ canvas: Canvas) {
        let fill = Paint()
        fill.color = Color(r: 0, g: 0, b: 0xFF)
        canvas.drawPaint(fill)

        fill.color = Color(r: 0, g: 0xFF, b: 0xFF)
        let rect = Rect(100.0, 100.0, 540.0, 380.0)
        canvas.drawRect(rect, fill)

        let stroke = Paint()
        stroke.color = Color(r: 0xFF, g: 0, b: 0)
        stroke.antialias = true
        stroke.stroke = true
        stroke.strokeWidth = 5.0

        let path = Path()
        path
                .moveTo(50.0, 50.0)
                .lineTo(590.0, 50.0)
                .cubicTo(-490.0, 50.0, 1130.0, 430.0, 50.0, 430.0)
                .lineTo(590.0, 430.0)
        canvas.drawPath(path, stroke)

        fill.color = Color(r: 0, g: 0xFF, b: 0, a: 0x80)
        let rect2 = Rect(120.0, 120.0, 520.0, 360.0)
        canvas.drawOval(rect2, fill)
    }
}

class EglNativeActivity: NativeActivity {
    static let TAG = "EglNativeActivity.swift"

    let mSkEglSurface: SkEglSurface

    init(app: NativeApplication) {

        mSkEglSurface = SkEglSurface(SkEglRendererImpl())

        super.init(app)
    }

    deinit {
    }

    override func onKeyEvent(_ app: NativeApplication, _ event: KeyEvent) -> Int32 {
        AndroidLogcat.w(EglNativeActivity.TAG, "onKeyEvent: \(event)")
        return 0
    }

    override func onMotionEvent(_ app: NativeApplication, _ event: MotionEvent) -> Int32 {
        if event.action != MotionEvent.Action.MOVE {
            AndroidLogcat.w(EglNativeActivity.TAG, "onMotionEvent: \(event)")
            if event.action == MotionEvent.Action.DOWN {
                //mX = event.x
                //mY = event.y
            }
        }
        return 0
    }

    override func onDrawFrame(_ app: NativeApplication) {
        // AndroidLogcat.w(MyNativeActivity.TAG, "onDrawFrame")
        mSkEglSurface.draw()
    }

    override func onAppCmdStart(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdStart")

        #if ENABLE_SOMETHING
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdStart:  ENABLE_SOMETHING")
        #endif
    }

    override func onAppCmdResume(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdResume")
    }

    override func onAppCmdInitWindow(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdInitWindow")
        if let window = app.window {
            mSkEglSurface.onInitWindow(window: window)
        }
    }

    override func onAppCmdGainedFocus(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdGainedFocus")
    }

    override func onAppCmdWindowResized(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdWindowResized")
    }

    override func onAppCmdConfigChanged(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdConfigChanged")
    }

    override func onAppCmdPause(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdPause")
    }

    override func onAppCmdLostFocus(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdLostFocus")
    }

    override func onAppCmdTermWindow(_ app: NativeApplication) {
        mSkEglSurface.onTermWindow()
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdTermWindow")
    }

    override func onAppCmdStop(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdStop")
    }

    override func onAppCmdSaveState(_ app: NativeApplication) -> CustomStringConvertible? {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdSaveState")

        let savedata: String = "321"
        return savedata
    }

    override func onAppCmdRestoreState(_ app: NativeApplication, _ savedata: CustomStringConvertible) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdRestoreState: savedata = \(savedata)")
    }

    override func onAppCmdDestroy(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdDestroy")
    }

    override func onAppCmdLowMemory(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdLowMemory")
    }

    override func onAppCmdWindowRedrawNeeded(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdWindowRedrawNeeded")
    }

    override func onAppCmdContentRectChanged(_ app: NativeApplication) {
        AndroidLogcat.w(EglNativeActivity.TAG, "onAppCmdContentRectChanged")
    }
}

@_silgen_name("create_custom_native_activity")
func create_custom_native_activity(_ pNativeApp: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {

    let app: NativeApplication = pNativeApp.bindMemory(to: NativeApplication.self, capacity: 1).pointee
    let nativeActivity: NativeActivity = EglNativeActivity(app: app)
    let pNativeActivity: UnsafeMutablePointer<NativeActivity> = UnsafeMutablePointer.allocate(capacity: 1)
    pNativeActivity.pointee = nativeActivity
    return UnsafeMutableRawPointer(pNativeActivity)
}
