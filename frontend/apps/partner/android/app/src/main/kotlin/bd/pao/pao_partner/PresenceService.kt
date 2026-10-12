package bd.pao.pao_partner

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/**
 * Holds the app in the foreground while the provider is online (ADR-0028).
 *
 * It sends nothing itself: the heartbeat stays in Dart. Without it Android freezes a
 * backgrounded app, its timers stop, and location is withheld, so the provider would
 * drop offline 90 s after leaving the app.
 */
class PresenceService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE).orEmpty()
        val body = intent?.getStringExtra(EXTRA_BODY).orEmpty()
        try {
            promote(notification(title, body))
        } catch (e: RuntimeException) {
            // Android 14 refuses a location service once the permission is revoked; the
            // app must not crash for it, and the in-app timer still beats while open.
            stopSelf()
        }
        // Not sticky: a service restarted after the process died would show the
        // provider as online while no Dart code is left to send beats.
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Swiping the app away ends the Flutter engine and with it the heartbeat.
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    private fun promote(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun notification(title: String, body: String): Notification {
        val open = packageManager.getLaunchIntentForPackage(packageName)
        val tap = PendingIntent.getActivity(
            this, 0, open, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return builder(title)
            .setSmallIcon(R.drawable.ic_presence)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(tap)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .build()
    }

    private fun builder(channelName: String): Notification.Builder {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            return Notification.Builder(this)
        }
        // Low importance: an ongoing status, not an alert, so no sound or pop-up.
        val channel = NotificationChannel(CHANNEL_ID, channelName, NotificationManager.IMPORTANCE_LOW)
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        return Notification.Builder(this, CHANNEL_ID)
    }

    companion object {
        /** Method channel name shared with `service_heartbeat.dart`. */
        const val METHOD_CHANNEL = "pao/presence_service"
        private const val CHANNEL_ID = "presence"
        private const val NOTIFICATION_ID = 7301
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"

        fun start(context: Context, title: String, body: String) {
            val intent = Intent(context, PresenceService::class.java)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_BODY, body)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, PresenceService::class.java))
        }
    }
}
