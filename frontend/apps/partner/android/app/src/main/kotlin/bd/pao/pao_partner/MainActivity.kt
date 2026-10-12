package bd.pao.pao_partner

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PresenceService.METHOD_CHANNEL)
            .setMethodCallHandler(::onPresenceCall)
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
