package dev.tvvnc.tv_vnc

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import dev.tvvnc.tv_vnc.bridge.TvHostApi
import dev.tvvnc.tv_vnc.bridge.TvFlutterApi
import dev.tvvnc.tv_vnc.core.Permissions
import dev.tvvnc.tv_vnc.core.TvController

class MainActivity : FlutterActivity() {
    private var controller: TvController? = null
    private var permissions: Permissions? = null
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        val access = Permissions(this); permissions = access
        controller = TvController(this, engine.renderer, access, TvFlutterApi(engine.dartExecutor.binaryMessenger))
        TvHostApi.setUp(engine.dartExecutor.binaryMessenger, controller)
    }
    override fun onRequestPermissionsResult(code: Int, names: Array<out String>, grants: IntArray) {
        super.onRequestPermissionsResult(code, names, grants)
        permissions?.result(code, grants)
    }
    override fun onStart() { super.onStart(); controller?.foreground() }
    override fun onPause() { controller?.suspendInput(); super.onPause() }
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) controller?.suspendInput()
    }
    override fun onStop() { controller?.background(); super.onStop() }
    override fun cleanUpFlutterEngine(engine: FlutterEngine) {
        TvHostApi.setUp(engine.dartExecutor.binaryMessenger, null)
        controller?.dispose(); controller = null; permissions?.close(); permissions = null
        super.cleanUpFlutterEngine(engine)
    }
}
