package app.hopin

import android.Manifest
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityTransition
import com.google.android.gms.location.ActivityTransitionRequest
import com.google.android.gms.location.ActivityTransitionResult
import com.google.android.gms.location.DetectedActivity
import com.pravera.flutter_foreground_task.service.ForegroundService
import com.pravera.flutter_foreground_task.service.ForegroundServiceManager
import org.json.JSONArray
import org.json.JSONObject

// Ride detection's native half (docs/ARCHITECTURE.md, Ride detection).
// Android's activity transitions say when the phone gets into a vehicle, even
// with Hopin closed; that starts the ride service, whose Dart task does the
// rest. A receiver that the system wakes is one of the cases where Android
// lets an app start a foreground service from the background.
object RideDetection {
    private const val TAG = "RideDetection"
    private const val PREFS = "hopin_detection"
    private const val ENABLED = "enabled"

    // The ride service's start options, as flutter_foreground_task's own
    // startService sends them; it wipes its copy whenever the service stops.
    private const val START = "start"

    // Where flutter_foreground_task's saveData keeps a value for the Dart task.
    private const val TASK_PREFS = "FlutterSharedPreferences"
    private const val TASK_KEY = "flutter.com.pravera.flutter_foreground_task.prefs."
    private const val VEHICLE_EXIT = "vehicle.exitAt"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun enable(context: Context, start: Map<*, *>): Boolean {
        prefs(context).edit()
            .putBoolean(ENABLED, true)
            .putString(START, JSONObject(start).toString())
            .apply()
        return register(context)
    }

    fun disable(context: Context) {
        prefs(context).edit().putBoolean(ENABLED, false).apply()
        try {
            ActivityRecognition.getClient(context)
                .removeActivityTransitionUpdates(pendingIntent(context))
        } catch (e: Exception) {
            Log.w(TAG, "Could not stop the transitions: ${e.message}")
        }
    }

    fun isEnabled(context: Context) = prefs(context).getBoolean(ENABLED, false)

    // Asks Android for the vehicle transitions again: after enabling, a
    // reboot or an update (registrations don't survive either).
    fun register(context: Context): Boolean {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACTIVITY_RECOGNITION)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        val transitions = listOf(
            ActivityTransition.ACTIVITY_TRANSITION_ENTER,
            ActivityTransition.ACTIVITY_TRANSITION_EXIT,
        ).map {
            ActivityTransition.Builder()
                .setActivityType(DetectedActivity.IN_VEHICLE)
                .setActivityTransition(it)
                .build()
        }
        return try {
            ActivityRecognition.getClient(context)
                .requestActivityTransitionUpdates(ActivityTransitionRequest(transitions), pendingIntent(context))
            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not ask for the transitions", e)
            false
        }
    }

    private fun pendingIntent(context: Context): PendingIntent = PendingIntent.getBroadcast(
        context,
        41,
        Intent(context, ActivityTransitionReceiver::class.java),
        // Mutable: Android fills in the transition result.
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
    )

    fun startRideService(context: Context) {
        if (ForegroundService.isRunningServiceState.value) return
        val json = prefs(context).getString(START, null) ?: return
        try {
            ForegroundServiceManager().start(context, toMap(JSONObject(json)))
        } catch (e: Exception) {
            Log.e(TAG, "Could not start the ride service", e)
        }
    }

    // The Dart task looks for this on its beat: the vehicle part is over.
    fun noteVehicleExit(context: Context) {
        context.getSharedPreferences(TASK_PREFS, Context.MODE_PRIVATE).edit()
            .putString(TASK_KEY + VEHICLE_EXIT, System.currentTimeMillis().toString())
            .apply()
    }

    private fun toMap(json: JSONObject): Map<String, Any?> =
        json.keys().asSequence().associateWith { plain(json.get(it)) }

    private fun plain(value: Any?): Any? = when (value) {
        JSONObject.NULL -> null
        is JSONObject -> toMap(value)
        is JSONArray -> (0 until value.length()).map { plain(value.get(it)) }
        else -> value
    }
}

class ActivityTransitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityTransitionResult.hasResult(intent) || !RideDetection.isEnabled(context)) return
        val result = ActivityTransitionResult.extractResult(intent) ?: return
        for (event in result.transitionEvents) {
            if (event.activityType != DetectedActivity.IN_VEHICLE) continue
            when (event.transitionType) {
                ActivityTransition.ACTIVITY_TRANSITION_ENTER -> RideDetection.startRideService(context)
                ActivityTransition.ACTIVITY_TRANSITION_EXIT -> RideDetection.noteVehicleExit(context)
            }
        }
    }
}

// Registrations don't survive a reboot or an update of the app.
class DetectionBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if ((action == Intent.ACTION_BOOT_COMPLETED || action == Intent.ACTION_MY_PACKAGE_REPLACED) &&
            RideDetection.isEnabled(context)
        ) {
            RideDetection.register(context)
        }
    }
}
