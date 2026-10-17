package bd.pao.pao_partner

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, PresenceService.METHOD_CHANNEL)
            .setMethodCallHandler(::onPresenceCall)
        // Document photo previews ask for FLAG_SECURE so NID and selfie images
        // cannot be captured in screenshots or the recent-apps preview.
        MethodChannel(messenger, "pao/secure_screen").setMethodCallHandler(::onSecureCall)
    }

    private fun onSecureCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "setSecure") {
            result.notImplemented()
            return
        }
        if (call.arguments == true) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
        result.success(null)
    }

    private fun onPresenceCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> try {
                PresenceService.start(
                    this,
                    call.argument<String>("title").orEmpty(),
                    call.argument<String>("body").orEmpty(),
                )
                result.success(null)
            } catch (e: RuntimeException) {
                // Android 12+ refuses to start a foreground service from the background
                // (ForegroundServiceStartNotAllowedException); Dart keeps its timer.
                result.error("unavailable", e.message, null)
            }
            "stop" -> {
                PresenceService.stop(this)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
