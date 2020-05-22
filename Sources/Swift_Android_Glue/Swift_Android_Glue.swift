import AndroidSwiftLogcat
import Swift_Android_NativeWindow
import C_Android_Glue
import Foundation

// Export ANativeActivity_onCreate()
// ----------------------------------------------
// Refer to: https://github.com/android-ndk/ndk/issues/381.
// https://github.com/android/ndk-samples/blob/99c3331e32268c51edae915268adb2092bb73ac9/native-activity/app/src/main/cpp/CMakeLists.txt#L30
let Export_ANativeActivity_onCreate: @convention(c) (UnsafeMutablePointer<ANativeActivity>?, UnsafeMutableRawPointer?, Int) -> Void = ANativeActivity_onCreate

class SavedState: CustomStringConvertible {
    var mData: CustomStringConvertible?

    var description: String {
        """

        SavedState {
            mData = \(String(describing: mData)),
        }
        """
    }

    init() {
    }

    deinit {
        AndroidLogcat.w(NativeActivity.TAG, "SavedState.deinit()")
    }
}

protocol InputEvent: CustomStringConvertible {
}

public class KeyEvent: InputEvent {
    public enum Action: Int32 {
        case DOWN = 0
        case UP = 1
        case MULTIPLE = 2
    }

    public enum Flag: Int32 {
        case WOKE_HERE = 0x1
        case SOFT_KEYBOARD = 0x2
        case KEEP_TOUCH_MODE = 0x4
        case FROM_SYSTEM = 0x8
        case EDITOR_ACTION = 0x10
        case CANCELED = 0x20
        case VIRTUAL_HARD_KEY = 0x40
        case LONG_PRESS = 0x80
        case CANCELED_LONG_PRESS = 0x100
        case TRACKING = 0x200
        case FALLBACK = 0x400
    }

    // https://developer.android.com/ndk/reference/group/input#group___input_1ga394b3903fbf00ba2b6243f60689a5a5f
    public let keycode: Int32
    public let action: Action
    public let flags: Int32

    public var description: String {
        """

        KeyEvent {
           keycode = \(keycode),
           action  = \(action),
           flags   = \(flags)
        }
        """
    }

    init(_ keycode: Int32, _ action: Action, _ flags: Int32) {
        self.keycode = keycode
        self.action = action
        self.flags = flags
    }

    deinit {
    }
}

// https://developer.android.com/training/gestures/multi
public class MotionEvent: InputEvent {
    public enum Action: Int32 {
        case MASK = 0xff
        case POINTER_INDEX_MASK = 0xff00
        case DOWN = 0
        case UP = 1
        case MOVE = 2
        case CANCEL = 3
        case OUTSIDE = 4
        case POINTER_DOWN = 5
        case POINTER_UP = 6
        case HOVER_MOVE = 7
        case SCROLL = 8
        case HOVER_ENTER = 9
        case HOVER_EXIT = 10
        case BUTTON_PRESS = 11
        case BUTTON_RELEASE = 12
    }

    public enum Flag: Int32 {
        case WINDOW_IS_OBSCURED = 0x1
    }

    public enum EdgeFlag: Int32 {
        case NONE = 0
        case TOP = 0x01
        case BOTTOM = 0x02
        case LEFT = 0x04
        case RIGHT = 0x08
    }

    public let x: Float
    public let y: Float
    public let pointerId: Int32
    public let pointerIndex: size_t
    public let action: Action
    public let flags: Int32
    public let edgeFlags: Int32

    public var description: String {
        """

        MotionEvent {
           x          = \(x),
           y          = \(y),
           pointerId  = \(pointerId)
           pointerIndex = \(pointerIndex),
           action     = \(action),
           flags      = \(flags),
           edgeFlags  = \(edgeFlags)
        }
        """
    }

    init(_ x: Float, _ y: Float, _ pointerId: Int32, _ pointerIndex: size_t, _ action: Action, _ flags: Int32, _ edgeFlags: Int32) {
        self.x = x
        self.y = y
        self.pointerId = pointerId
        self.pointerIndex = pointerIndex
        self.action = action
        self.flags = flags
        self.edgeFlags = edgeFlags
    }

    deinit {
    }
}

public class NativeApplication {
    var mApp: android_app

    public var window: AndroidNativeWindow? {
        //AndroidLogcat.i(NativeActivity.TAG, "mApp.window = \(mApp.window)")
        return AndroidNativeWindow.fromWindowPtr(mApp.window)
    }

    init(_ app: android_app) {
        mApp = app
    }
}

open class NativeActivity {
    static let TAG = "NativeActivity.swift"

    public let app: NativeApplication

    var mAnimating: Bool

    var mSavedState: SavedState

    public init(_ app: NativeApplication) {
        self.app = app
        mSavedState = SavedState()
        mAnimating = true
    }

    deinit {
    }

    open func onKeyEvent(_ app: NativeApplication, _ event: KeyEvent) -> Int32 {
        AndroidLogcat.v(NativeActivity.TAG, "onKeyEvent: \(event)")
        return 0
    }

    open func onMotionEvent(_ app: NativeApplication, _ event: MotionEvent) -> Int32 {
        if event.action != MotionEvent.Action.MOVE {
            AndroidLogcat.v(NativeActivity.TAG, "onMotionEvent: \(event)")
        }
        return 0
    }

    open func onDrawFrame(_ app: NativeApplication) {
        // AndroidLogcat.v(NativeActivity.TAG, "onDrawFrame")
    }

    open func onAppCmdStart(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdStart")
    }

    open func onAppCmdResume(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdResume")
    }

    open func onAppCmdInitWindow(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdInitWindow")
    }

    open func onAppCmdGainedFocus(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdGainedFocus")
    }

    open func onAppCmdWindowResized(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdWindowResized")
    }

    open func onAppCmdConfigChanged(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdConfigChanged")
    }

    open func onAppCmdPause(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdPause")
    }

    open func onAppCmdLostFocus(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdLostFocus")
    }

    open func onAppCmdTermWindow(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdTermWindow")
    }

    open func onAppCmdStop(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdStop")
    }

    open func onAppCmdSaveState(_ app: NativeApplication) -> CustomStringConvertible? {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdSaveState")
        return nil
    }

    open func onAppCmdRestoreState(_ app: NativeApplication, _ savedata: CustomStringConvertible) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdRestoreState: savedata = \(savedata)")
    }

    open func onAppCmdDestroy(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdDestroy")
    }

    open func onAppCmdLowMemory(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdLowMemory")
    }

    open func onAppCmdWindowRedrawNeeded(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdWindowRedrawNeeded")
    }

    open func onAppCmdContentRectChanged(_ app: NativeApplication) {
        AndroidLogcat.v(NativeActivity.TAG, "onAppCmdContentRectChanged")
    }
}

/// Process the next main command.
@_cdecl("c_engine_handle_cmd")
// @_silgen_name("c_engine_handle_cmd")
func c_engine_handle_cmd(_ pApp: UnsafeMutablePointer<android_app>?, _ cmd: Int32) {
    // AndroidLogcat.v(NativeActivity.TAG, "c_engine_handle_cmd")
    if let pApp = pApp {
        var app: android_app = pApp.pointee
        let pUserData: UnsafeMutableRawPointer = app.userData
        let engine: NativeActivity = pUserData.load(as: NativeActivity.self)
        let nativeApp: NativeApplication = engine.app
        nativeApp.mApp = app

        switch Int(cmd) {
            case APP_CMD_START:
                engine.onAppCmdStart(nativeApp)

            case APP_CMD_RESUME:
                engine.onAppCmdResume(nativeApp)

            case APP_CMD_INIT_WINDOW:
                if app.window != nil {
                    engine.onAppCmdInitWindow(nativeApp)
                }

            case APP_CMD_GAINED_FOCUS:
                engine.onAppCmdGainedFocus(nativeApp)

            case APP_CMD_WINDOW_RESIZED:
                engine.onAppCmdWindowResized(nativeApp)

            case APP_CMD_CONFIG_CHANGED:
                engine.onAppCmdConfigChanged(nativeApp)

            case APP_CMD_PAUSE:
                engine.onAppCmdPause(nativeApp)

                // activated state
                // -------------------------------------

            case APP_CMD_LOST_FOCUS:
                engine.onAppCmdLostFocus(nativeApp)

            case APP_CMD_TERM_WINDOW:
                engine.onAppCmdTermWindow(nativeApp)

            case APP_CMD_STOP:
                engine.onAppCmdStop(nativeApp)

            case APP_CMD_SAVE_STATE:
                engine.mSavedState.mData = engine.onAppCmdSaveState(nativeApp)

                // The system has asked us to save our current state.  Do so.
                let pSavedState: UnsafeMutablePointer<SavedState> = UnsafeMutablePointer<SavedState>.allocate(capacity: 1)
                pSavedState.initialize(to: engine.mSavedState)

                app.savedState = UnsafeMutableRawPointer(pSavedState)
                app.savedStateSize = MemoryLayout.size(ofValue: engine.mSavedState)
            case APP_CMD_DESTROY:
                engine.onAppCmdDestroy(nativeApp)

                //
                // --------------------------------------

            case APP_CMD_LOW_MEMORY:
                engine.onAppCmdLowMemory(nativeApp)

            case APP_CMD_WINDOW_REDRAW_NEEDED:
                engine.onAppCmdWindowRedrawNeeded(nativeApp)

            case APP_CMD_CONTENT_RECT_CHANGED:
                engine.onAppCmdContentRectChanged(nativeApp)

            default:
                break
        }
    }
}

// swift compiler cant recognize `AInputEvent` in `#include<android/input.h>`
@_cdecl("c_engine_handle_input")
// @_silgen_name("c_engine_handle_input")
func c_engine_handle_input(_ pApp: UnsafeMutablePointer<android_app>?, _ pEvent: OpaquePointer? /* UnsafeMutablePointer<AInputEvent>? */) -> Int32 {
    // AndroidLogcat.v(NativeActivity.TAG, "c_engine_handle_input")
    if let pApp = pApp {
        let app: android_app = pApp.pointee
        let pUserData: UnsafeMutableRawPointer = app.userData
        let engine: NativeActivity = pUserData.load(as: NativeActivity.self)
        let nativeApp: NativeApplication = engine.app
        nativeApp.mApp = app

        if AInputEvent_getType(pEvent) == AINPUT_EVENT_TYPE_MOTION {
            let action: Int32 = AMotionEvent_getAction(pEvent)
            let pointerIdx: Int32 = (action & MotionEvent.Action.POINTER_INDEX_MASK.rawValue) >> 8
            let actionIdx: Int32 = action & MotionEvent.Action.MASK.rawValue
            let flags: Int32 = AMotionEvent_getFlags(pEvent)
            let edgeFlags: Int32 = AMotionEvent_getEdgeFlags(pEvent)
            let pointerIndex: size_t = size_t(pointerIdx)
            let x: Float = AMotionEvent_getX(pEvent, pointerIndex)
            let y: Float = AMotionEvent_getY(pEvent, pointerIndex)
            let pointerId: Int32 = AMotionEvent_getPointerId(pEvent, pointerIndex)

            return engine.onMotionEvent(nativeApp, MotionEvent(x, y,
                                                               pointerId,
                                                               pointerIndex,
                                                               MotionEvent.Action(rawValue: actionIdx)!,
                                                               flags, edgeFlags))
        } else if AInputEvent_getType(pEvent) == AINPUT_EVENT_TYPE_KEY {
            let keycode: Int32 = AKeyEvent_getKeyCode(pEvent)
            let action: Int32 = AKeyEvent_getAction(pEvent)
            let flags: Int32 = AKeyEvent_getFlags(pEvent)

            return engine.onKeyEvent(nativeApp, KeyEvent(keycode, KeyEvent.Action(rawValue: action)!, flags))
        }
        return 0
    }
    return 0
}

@_silgen_name("android_main")
func android_main(_ pApp: UnsafeMutablePointer<android_app>) {
    AndroidLogcat.i(NativeActivity.TAG, "android_main")

    //
    // -------------
    var app: android_app = pApp.pointee
    let nativeApp: NativeApplication = NativeApplication(app)

    //
    // -------------
    // let engine: NativeActivity = NativeActivity(app)
    let pNativeApp: UnsafeMutablePointer<NativeApplication> = UnsafeMutablePointer.allocate(capacity: 1)
    defer {
        pNativeApp.deinitialize(count: 1)
        pNativeApp.deallocate()
    }
    pNativeApp.initialize(to: nativeApp)

    let pNativeActivity: UnsafeMutableRawPointer = create_custom_native_activity(UnsafeMutableRawPointer(pNativeApp))
    defer {
        pNativeActivity.deallocate()
    }
    let engine: NativeActivity = pNativeActivity.bindMemory(to: NativeActivity.self, capacity: 1).pointee

    //
    // -------------
    let pUserData: UnsafeMutablePointer<NativeActivity> = UnsafeMutablePointer.allocate(capacity: 1)
    defer {
        pUserData.deinitialize(count: 1)
        pUserData.deallocate()
    }
    pUserData.initialize(to: engine)

    // init appState
    // -------------
    app.userData = UnsafeMutableRawPointer(pUserData)
    app.onAppCmd = c_engine_handle_cmd
    app.onInputEvent = c_engine_handle_input

    // must be set back to C-Pointer, because Swift-Struct-Type is a Value-Type
    pApp.pointee = app

    if let pSavedState: UnsafeMutableRawPointer = app.savedState {
        // We are starting with a previous saved state; restore from it.
        engine.mSavedState = pSavedState.load(as: SavedState.self)

        if let savedata = engine.mSavedState.mData {
            engine.onAppCmdRestoreState(nativeApp, savedata)
        }
    }

    // loop waiting for stuff to do.

    while true {
        // Read all pending events.
        var events: Int32 = 0
        var ppSource: UnsafeMutablePointer<UnsafeMutableRawPointer?> = UnsafeMutablePointer.allocate(capacity: 1)
        defer {
            ppSource.deinitialize(count: 1)
            ppSource.deallocate()
        }

        // If not animating, we will block forever waiting for events.
        // If animating, we loop until all events are read, then continue
        // to draw the next frame of animation.
        while case let ident: Int32 = ALooper_pollAll(engine.mAnimating ? 0 : -1, nil, &events, ppSource), ident >= 0 {
            // AndroidLogcat.v(NativeActivity.TAG, "ALooper_pollAll")

            // Process this event.
            if let pSrc: UnsafeMutableRawPointer = ppSource.pointee {
                let pSource: UnsafeMutablePointer<android_poll_source> = pSrc.bindMemory(to: android_poll_source.self, capacity: 1)
                let source: android_poll_source = pSource.pointee
                source.process(pApp, pSource)
            }

            // TODO:
            // --------------

            // Check if we are exiting.
            if app.destroyRequested != 0 {
                engine.onAppCmdTermWindow(nativeApp)
                return
            }
        } // while case let ident

        if engine.mAnimating {
            engine.onDrawFrame(nativeApp)
        }
    } // while true
}
