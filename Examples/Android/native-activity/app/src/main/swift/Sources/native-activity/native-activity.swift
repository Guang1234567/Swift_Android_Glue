import Foundation
import AndroidSwiftLogcat
import SGLEGL
import SGLOpenGL
import Swift_Android_Glue

enum DemoError: Error {
    case INIT_EGL_FAIlURE(reason: String)
    case DEINIT_EGL_FAIlURE(reason: String)
}

func initEglEnv(hostActivity: MyNativeActivity) throws {
    //
    // ---------------------------
    let attribs: [EGLint] = [
        EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
        EGL_BLUE_SIZE, 8,
        EGL_GREEN_SIZE, 8,
        EGL_RED_SIZE, 8,
        EGL_NONE
    ]

    // Create EGLDisplay
    // ----------------------------
    let eglDisplay: EGLDisplay = eglGetDisplay(display_id: EGL_DEFAULT_DISPLAY)

    guard EGL_NO_DISPLAY != eglDisplay else {
        throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglGetDisplay")
    }

    AndroidLogcat.i(MyNativeActivity.TAG, "eglDisplay = \(eglDisplay)")

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
        //AndroidLogcat.w(MyNativeActivity.TAG, "initEglEnved numConfig[\(idx)] = \(pSupportedConfigs[idx])")
        let cfg: EGLConfig = pSupportedConfigs[idx]
        var r: EGLint = 0
        var g: EGLint = 0
        var b: EGLint = 0
        var d: EGLint = 0

        if EGL_TRUE == eglGetConfigAttrib(dpy: eglDisplay, config: cfg, attribute: EGL_RED_SIZE, value: &r)
                   && EGL_TRUE == eglGetConfigAttrib(dpy: eglDisplay, config: cfg, attribute: EGL_RED_SIZE, value: &g)
                   && EGL_TRUE == eglGetConfigAttrib(dpy: eglDisplay, config: cfg, attribute: EGL_RED_SIZE, value: &b)
                   && EGL_TRUE == eglGetConfigAttrib(dpy: eglDisplay, config: cfg, attribute: EGL_RED_SIZE, value: &d)
                   && r == 8 && g == 8 && b == 8 && d == 8 {
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
    let eglSurface: EGLSurface = eglCreateWindowSurface(
            dpy: eglDisplay,
            config: config!,
            win: hostActivity.app.window!,
            attrib_list: nil)

    guard EGL_NO_SURFACE != eglSurface else {
        throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglCreateWindowSurface")
    }

    AndroidLogcat.i(MyNativeActivity.TAG, "eglSurface = \(eglSurface)")

    var width: EGLint = 0
    guard EGL_TRUE == eglQuerySurface(dpy: eglDisplay, surface: eglSurface, attribute: EGL_WIDTH, value: &width) else {
        throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglQuerySurface")
    }
    AndroidLogcat.i(MyNativeActivity.TAG, "width = \(width)")

    var height: EGLint = 0
    guard EGL_TRUE == eglQuerySurface(dpy: eglDisplay, surface: eglSurface, attribute: EGL_HEIGHT, value: &height) else {
        throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglQuerySurface")
    }
    AndroidLogcat.i(MyNativeActivity.TAG, "height = \(height)")

    // Create EGLContext
    // ----------------------------
    /*let shareContext: UnsafeMutablePointer<Void> = UnsafeMutablePointer.allocate(capacity: 1)
    shareContext.initialize(to: ())
    defer {
        shareContext.deinitialize(count: 1)
        shareContext.deallocate()
    }*/
    let eglContext: EGLContext = eglCreateContext(dpy: eglDisplay, config: config!, share_context: EGL_NO_CONTEXT, attrib_list: nil)

    guard EGL_NO_CONTEXT != eglContext else {
        throw DemoError.INIT_EGL_FAIlURE(reason: "Unable to eglCreateContext")
    }

    AndroidLogcat.i(MyNativeActivity.TAG, "eglContext = \(eglContext)")

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
        AndroidLogcat.i(MyNativeActivity.TAG, "OpenGL Info: \(String(cString: info))")
    }

    // Initialize GL state.
    // ---------------------------
    glEnable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);

    //
    // ---------------------------
    hostActivity.mEglDisplay = eglDisplay
    hostActivity.mEglSurface = eglSurface
    hostActivity.mSurfaceWidth = width
    hostActivity.mSurfaceHeight = height
    hostActivity.mEglContext = eglContext

    AndroidLogcat.w(MyNativeActivity.TAG, "initEglEnved numConfig = \(numConfig)")
}

func deinitEglEnv(hostActivity: MyNativeActivity) throws {
    let display = hostActivity.mEglDisplay
    if EGL_NO_DISPLAY != display {
        // Unbind eglDisplay + eglSurface + EGLContext
        // ----------------------------
        guard EGL_TRUE == eglMakeCurrent(dpy: display, draw: EGL_NO_SURFACE, read: EGL_NO_SURFACE, ctx: EGL_NO_CONTEXT) else {
            throw DemoError.DEINIT_EGL_FAIlURE(reason: "Unable to eglMakeCurrent")
        }

        let context = hostActivity.mEglContext
        if EGL_NO_CONTEXT != context {
            guard EGL_TRUE == eglDestroyContext(dpy: display, ctx: context) else {
                throw DemoError.DEINIT_EGL_FAIlURE(reason: "Unable to eglDestroyContext")
            }
        }

        let surface = hostActivity.mEglSurface
        if EGL_NO_SURFACE != surface {
            guard EGL_TRUE == eglDestroySurface(dpy: display, surface: surface) else {
                throw DemoError.DEINIT_EGL_FAIlURE(reason: "Unable to eglDestroySurface")
            }
        }

        guard EGL_TRUE == eglTerminate(dpy: display) else {
            throw DemoError.DEINIT_EGL_FAIlURE(reason: "Unable to eglTerminate")
        }
    }
    hostActivity.mEglDisplay = EGL_NO_DISPLAY
    hostActivity.mEglContext = EGL_NO_CONTEXT
    hostActivity.mEglSurface = EGL_NO_SURFACE

    AndroidLogcat.w(MyNativeActivity.TAG, "deinitEglEnv")
}

class MyNativeActivity: NativeActivity {
    static let TAG = "MyNativeActivity.swift"

    var mEglDisplay: EGLDisplay = EGL_NO_DISPLAY
    var mEglSurface: EGLSurface = EGL_NO_SURFACE
    var mSurfaceWidth: EGLint = 0
    var mSurfaceHeight: EGLint = 0
    var mEglContext: EGLContext = EGL_NO_CONTEXT

    var mAngle: Float = 0.0
    var mX: Float = 0.0
    var mY: Float = 0.0

    override init(_ app: NativeApplication) {
        super.init(app)
    }

    deinit {
    }

    override func onKeyEvent(_ app: NativeApplication, _ event: KeyEvent) -> Int32 {
        AndroidLogcat.w(MyNativeActivity.TAG, "onKeyEvent: \(event)")
        return 0
    }

    override func onMotionEvent(_ app: NativeApplication, _ event: MotionEvent) -> Int32 {
        if event.action != MotionEvent.Action.MOVE {
            AndroidLogcat.w(MyNativeActivity.TAG, "onMotionEvent: \(event)")
            if event.action == MotionEvent.Action.DOWN {
                mX = event.x
                mY = event.y
            }
        }
        return 0
    }

    override func onDrawFrame(_ app: NativeApplication) {
        // AndroidLogcat.w(MyNativeActivity.TAG, "onDrawFrame")

        guard EGL_NO_DISPLAY != mEglDisplay else {
            return
        }

        mAngle += 0.01
        if mAngle > 1 {
            mAngle = 0.0
        }

        glClearColor(
                red: mX / Float(mSurfaceWidth),
                green: mAngle,
                blue: mY / Float(mSurfaceHeight),
                alpha: 1.0)

        glClear(mask: GL_COLOR_BUFFER_BIT);

        eglSwapBuffers(dpy: mEglDisplay, surface: mEglSurface);
    }

    override func onAppCmdStart(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdStart")

        #if ENABLE_SOMETHING
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdStart:  ENABLE_SOMETHING")
        #endif
    }

    override func onAppCmdResume(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdResume")
    }

    override func onAppCmdInitWindow(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdInitWindow")

        do {
            try initEglEnv(hostActivity: self)
        } catch DemoError.INIT_EGL_FAIlURE(let reason) {
            AndroidLogcat.e(MyNativeActivity.TAG, reason)
        } catch {
            AndroidLogcat.e(MyNativeActivity.TAG, "Unknow EGL Init Error!")
        }
    }

    override func onAppCmdGainedFocus(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdGainedFocus")
    }

    override func onAppCmdWindowResized(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdWindowResized")
    }

    override func onAppCmdConfigChanged(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdConfigChanged")
    }

    override func onAppCmdPause(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdPause")
    }

    override func onAppCmdLostFocus(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdLostFocus")
    }

    override func onAppCmdTermWindow(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdTermWindow")

        do {
            try deinitEglEnv(hostActivity: self)
        } catch DemoError.DEINIT_EGL_FAIlURE(let reason) {
            AndroidLogcat.e(MyNativeActivity.TAG, reason)
        } catch {
            AndroidLogcat.e(MyNativeActivity.TAG, "Unknow EGL Deinit Error!")
        }
    }

    override func onAppCmdStop(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdStop")
    }

    override func onAppCmdSaveState(_ app: NativeApplication) -> CustomStringConvertible? {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdSaveState")

        let savedata: String = "321"
        return savedata
    }

    override func onAppCmdRestoreState(_ app: NativeApplication, _ savedata: CustomStringConvertible) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdRestoreState: savedata = \(savedata)")
    }

    override func onAppCmdDestroy(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdDestroy")
    }

    override func onAppCmdLowMemory(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdLowMemory")
    }

    override func onAppCmdWindowRedrawNeeded(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdWindowRedrawNeeded")
    }

    override func onAppCmdContentRectChanged(_ app: NativeApplication) {
        AndroidLogcat.w(MyNativeActivity.TAG, "onAppCmdContentRectChanged")
    }
}

@_silgen_name("create_custom_native_activity")
func create_custom_native_activity(_ pNativeApp: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
    let app: NativeApplication = pNativeApp.bindMemory(to: NativeApplication.self, capacity: 1).pointee

    let nativeActivity: NativeActivity = MyNativeActivity(app)

    let pNativeActivity: UnsafeMutablePointer<NativeActivity> = UnsafeMutablePointer.allocate(capacity: 1)
    pNativeActivity.pointee = nativeActivity
    return UnsafeMutableRawPointer(pNativeActivity)
}
