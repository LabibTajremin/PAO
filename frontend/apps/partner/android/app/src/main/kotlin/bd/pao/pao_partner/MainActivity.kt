package bd.pao.pao_partner

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Document photo previews ask for FLAG_SECURE so NID and selfie images
        // cannot be captured in screenshots or the recent-apps preview.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pao/secure_screen")
            .setMethodCallHandler { call, result ->
                if (call.method != "setSecure") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (call.arguments == true) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
                result.success(null)
            }
    }
}
