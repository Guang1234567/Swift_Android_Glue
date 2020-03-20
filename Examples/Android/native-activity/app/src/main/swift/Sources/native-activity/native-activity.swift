
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
