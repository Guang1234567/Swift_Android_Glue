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
        .package(url: "https://github.com/Guang1234567/swift-backtrace.git", .branch("master")),
    ],

    targets: [
        .target(name: packageName,
                dependencies: [
                    "java_swift",
                    "JavaCoder",
                    "AndroidSwiftLogcat",
                    "AndroidSwiftTrace",
                    "Backtrace",
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

import AndroidSwiftLogcat
import Foundation
import Swift_Android_Glue

class MyNativeActivity: NativeActivity {
    static let TAG = "MyNativeActivity.swift"
    
    override init(_ app: NativeApplication) {
        super.init(app)
    }
    
    deinit {}
    
    override func onKeyEvent(_ app: NativeApplication, _ event: KeyEvent) -> Int32 {
        AndroidLogcat.w(MyNativeActivity.TAG, "onKeyEvent: \(event)")
        return 0
    }
    
    override func onMotionEvent(_ app: NativeApplication, _ event: MotionEvent) -> Int32 {
        if event.action != MotionEvent.Action.MOVE {
            AndroidLogcat.w(MyNativeActivity.TAG, "onMotionEvent: \(event)")
        }
        return 0
    }
    
    override func onDrawFrame(_ app: NativeApplication) {
        // AndroidLogcat.w(MyNativeActivity.TAG, "onDrawFrame")
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
