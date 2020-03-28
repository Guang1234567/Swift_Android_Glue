# Swift_Android_Glue


Reimplement [Google NDK Sample /NativeActivity](https://developer.android.com/ndk/samples/sample_na)  by Swift Lang.


## Usage

- Swift Package Manager  (SPM)

```swift
// package.swift
// ---------------------
//

let package = Package(
    name: YourAppName,

    // ...

    dependencies: [
        // ...
        .package(url: "https://github.com/Guang1234567/Swift_OpenGL.git", .branch("gles32_egl15_android")),
        .package(url: "https://github.com/Guang1234567/swift-backtrace.git", .branch("master")),
    ],

    targets: [
        .target(name: packageName,
                dependencies: [
                    // ...
                    "SGLEGL",
                    "SGLOpenGL",
                    "Swift_Android_Glue",
                ]
        ),
    ]
) // Package
```


```swift
// native-activity.swift
// --------------------------
//

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

    AndroidLogcat.i(MyNativeActivity.TAG, "eglDisplay = 0x\(String(eglDisplay, radix: 16))")

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

    AndroidLogcat.i(MyNativeActivity.TAG, "eglSurface = 0x\(String(eglSurface, radix: 16))")

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

    AndroidLogcat.i(MyNativeActivity.TAG, "eglContext = 0x\(String(eglContext, radix: 16))")

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
    
    // ....

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
   
    // ....
}

@_silgen_name("create_custom_native_activity")
func create_custom_native_activity(_ pNativeApp: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
    let app: NativeApplication = pNativeApp.bindMemory(to: NativeApplication.self, capacity: 1).pointee
    
    let nativeActivity: NativeActivity = MyNativeActivity(app)
    
    let pNativeActivity: UnsafeMutablePointer<NativeActivity> = UnsafeMutablePointer.allocate(capacity: 1)
    pNativeActivity.pointee = nativeActivity
    return UnsafeMutableRawPointer(pNativeActivity)
}
```

## Compare

-  Cpp Version

```
/**
 * This is the main entry point of a native application that is using
 * android_native_app_glue.  It runs in its own thread, with its own
 * event loop for receiving input events and doing other things.
 */
void android_main(struct android_app* pApp) {
    struct engine engine{};

    memset(&engine, 0, sizeof(engine));
    pApp->userData = &engine;
    pApp->onAppCmd = engine_handle_cmd;
    pApp->onInputEvent = engine_handle_input;
    engine.app = pApp;

    // Prepare to monitor accelerometer
    engine.sensorManager = AcquireASensorManagerInstance(pApp);
    engine.accelerometerSensor = ASensorManager_getDefaultSensor(
                                        engine.sensorManager,
                                        ASENSOR_TYPE_ACCELEROMETER);
    engine.sensorEventQueue = ASensorManager_createEventQueue(
                                    engine.sensorManager,
                                    pApp->looper, LOOPER_ID_USER,
                                    nullptr, nullptr);

    if (pApp->savedState != nullptr) {
        // We are starting with a previous saved state; restore from it.
        engine.state = *(struct saved_state*)pApp->savedState;
    }

    // loop waiting for stuff to do.

    while (true) {
        // Read all pending events.
        int ident;
        int events;
        struct android_poll_source* source;

        // If not animating, we will block forever waiting for events.
        // If animating, we loop until all events are read, then continue
        // to draw the next frame of animation.
        while ((ident=ALooper_pollAll(engine.animating ? 0 : -1, nullptr, &events,
                                      (void**)&source)) >= 0) {

            // Process this event.
            if (source != nullptr) {
                source->process(pApp, source);
            }

            // If a sensor has data, process it now.
            if (ident == LOOPER_ID_USER) {
                if (engine.accelerometerSensor != nullptr) {
                    ASensorEvent event;
                    while (ASensorEventQueue_getEvents(engine.sensorEventQueue,
                                                       &event, 1) > 0) {
                        LOGI("accelerometer: x=%f y=%f z=%f",
                             event.acceleration.x, event.acceleration.y,
                             event.acceleration.z);
                    }
                }
            }

            // Check if we are exiting.
            if (pApp->destroyRequested != 0) {
                engine_term_display(&engine);
                return;
            }
        }

        if (engine.animating) {
            // Done with events; draw next animation frame.
            engine.state.angle += .01f;
            if (engine.state.angle > 1) {
                engine.state.angle = 0;
            }

            // Drawing is throttled to the screen update rate, so there
            // is no need to do timing here.
            engine_draw_frame(&engine);
        }
    }
}
```


- Swift Version

Api become more humanization and like `android.app.Activity` on java.

Of course you can also implement it as  c++ class.

```swift

class NativeActivity {
    static let TAG = "NativeActivity.swift"
    
    // ...
    
    func onInputEvent(_ app: android_app, _ x: Float, _ y: Float) -> Int32 {
        AndroidLogcat.w(NativeActivity.TAG, "onInputEvent: x = \(x), y = \(y)")
        return 0
    }
    
    func onDrawFrame(_ app: android_app) {
        // AndroidLogcat.w(Engine.TAG, "onDrawFrame")
    }
    
    func onAppCmdStart(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdStart")
    }
    
    func onAppCmdResume(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdResume")
    }
    
    func onAppCmdInitWindow(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdInitWindow")
    }
    
    func onAppCmdGainedFocus(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdGainedFocus")
    }
    
    func onAppCmdWindowResized(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdWindowResized")
    }
    
    func onAppCmdConfigChanged(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdConfigChanged")
    }
    
    func onAppCmdPause(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdPause")
    }
    
    func onAppCmdLostFocus(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdLostFocus")
    }
    
    func onAppCmdTermWindow(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdTermWindow")
    }
    
    func onAppCmdStop(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdStop")
    }
    
    func onAppCmdSaveState(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdSaveState")
    }
    
    func onAppCmdDestroy(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdDestroy")
    }
    
    func onAppCmdLowMemory(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdLowMemory")
    }
    
    func onAppCmdWindowRedrawNeeded(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdWindowRedrawNeeded")
    }
    
    func onAppCmdContentRectChanged(_ app: android_app) {
        AndroidLogcat.w(NativeActivity.TAG, "onAppCmdContentRectChanged")
    }
}
```
