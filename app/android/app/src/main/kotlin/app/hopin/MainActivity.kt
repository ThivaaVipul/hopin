package app.hopin

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// The phone's maker and its own settings, for the battery guide
// (docs/ARCHITECTURE.md, Phones that kill background apps). Dart can't read
// either without a plugin.
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.hopin/phone")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "maker" -> result.success(Build.MANUFACTURER.lowercase())
                    "openAutostart" -> result.success(openAutostart())
                    else -> result.notImplemented()
                }
            }
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
