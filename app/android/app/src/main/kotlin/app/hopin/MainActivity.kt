package app.hopin

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import java.io.File
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// The phone's maker and its own settings, for the battery guide
// (docs/ARCHITECTURE.md, Phones that kill background apps), and handing a
// downloaded update to Android's installer. Dart can't do these without a
// plugin.
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A fresh request for the vehicle readings each time Hopin opens.
        if (RideDetection.isEnabled(this)) RideDetection.register(this)
        watchIfAsked(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        watchIfAsked(intent)
    }

    // The quick settings tile couldn't start watching from the panel; from
    // the screen, Android allows it.
    private fun watchIfAsked(intent: Intent?) {
        if (intent?.getBooleanExtra(WATCH, false) != true) return
        intent.removeExtra(WATCH)
        try {
            RideDetection.watchNow(this)
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "Could not start watching: ${e.message}")
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.hopin/phone")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "maker" -> result.success(Build.MANUFACTURER.lowercase())
                    "openAutostart" -> result.success(openAutostart())
                    "installApk" -> result.success(installApk(call.argument<String>("path")))
                    "enableDetection" -> result.success(
                        RideDetection.enable(this, call.arguments as? Map<*, *> ?: emptyMap<String, Any>()),
                    )
                    "disableDetection" -> {
                        RideDetection.disable(this)
                        result.success(null)
                    }
                    "detectionEnabled" -> result.success(RideDetection.isEnabled(this))
                    "detectNow" -> {
                        RideDetection.startRideService(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Android's installer for a downloaded update. The first time, Android's
    // page to let Hopin install apps opens instead, and this answers false.
    private fun installApk(path: String?): Boolean {
        if (path == null) return false
        if (!packageManager.canRequestPackageInstalls()) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.fromParts("package", packageName, null),
                ),
            )
            return false
        }
        val apk = FileProvider.getUriForFile(this, "$packageName.updates", File(path))
        startActivity(
            Intent(Intent.ACTION_VIEW)
                .setDataAndType(apk, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        return true
    }

    companion object {
        // From the quick settings tile: start watching the ride.
        const val WATCH = "app.hopin.WATCH"
    }

    // Xiaomi's Autostart list, or the app's own settings where it's missing.
    private fun openAutostart(): Boolean {
        val autostart = Intent().setComponent(
            ComponentName(
                "com.miui.securitycenter",
                "com.miui.permcenter.autostart.AutoStartManagementActivity",
            ),
        )
        return try {
            startActivity(autostart)
            true
        } catch (e: Exception) {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", packageName, null),
                ),
            )
            false
        }
    }
}
