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
import com.google.android.gms.location.ActivityRecognitionResult
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
//
// The transitions sometimes never come although Play services saw the
// vehicle, so a backstop asks for its readings every few minutes as well,
// and starts watching on a confident "in a vehicle". After a ride stops it
// keeps quiet until the rider is on foot again (or the vehicle is left), so
// Not a bus and End aren't undone in the same vehicle.
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

    // Written by the Dart task when the ride service stops (ride_task.dart).
    private const val QUIET = "ride.quiet"

    private const val TRANSITIONS = 41
    private const val BACKSTOP = 42

    // A reading every 3 minutes: a brief wake, no GPS until a vehicle shows.
    private const val BACKSTOP_EVERY_MS = 3 * 60 * 1000L

    // How sure Play services must be: in a vehicle, or on foot.
    private const val SURE = 75

    // Quiet at most this long, if the rider is never seen on foot.
    private const val QUIET_FOR_MS = 2 * 60 * 60 * 1000L

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun taskPrefs(context: Context) =
        context.getSharedPreferences(TASK_PREFS, Context.MODE_PRIVATE)

    fun enable(context: Context, start: Map<*, *>): Boolean {
        prefs(context).edit()
            .putBoolean(ENABLED, true)
            .putString(START, JSONObject(start).toString())
            .apply()
        return register(context)
    }

    fun disable(context: Context) {
        prefs(context).edit().putBoolean(ENABLED, false).apply()
        val client = ActivityRecognition.getClient(context)
        try {
            client.removeActivityTransitionUpdates(pendingIntent(context, TRANSITIONS))
            client.removeActivityUpdates(pendingIntent(context, BACKSTOP))
        } catch (e: Exception) {
            Log.w(TAG, "Could not stop the readings: ${e.message}")
        }
    }

    fun isEnabled(context: Context) = prefs(context).getBoolean(ENABLED, false)

    // Asks Play services for the vehicle transitions and the backstop's
    // readings again: after enabling, a reboot, an update, and each time
    // Hopin opens (a fresh request replaces the old one).
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
            val client = ActivityRecognition.getClient(context)
            client.requestActivityTransitionUpdates(
                ActivityTransitionRequest(transitions),
                pendingIntent(context, TRANSITIONS),
            )
            client.requestActivityUpdates(BACKSTOP_EVERY_MS, pendingIntent(context, BACKSTOP))
            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not ask for the readings", e)
            false
        }
    }

    private fun pendingIntent(context: Context, code: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            code,
            Intent(context, ActivityTransitionReceiver::class.java),
            // Mutable: Play services fills in its result.
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

    // The rider asked (the quick settings tile): watch now, quiet or not.
    // Throws when Android refuses the start from where it was asked.
    fun watchNow(context: Context) {
        clearQuiet(context)
        if (ForegroundService.isRunningServiceState.value) return
        val json = prefs(context).getString(START, null) ?: return
        ForegroundServiceManager().start(context, toMap(JSONObject(json)))
    }

    // The backstop: a confident "in a vehicle" starts watching; a confident
    // "on foot" ends the quiet after a ride.
    fun onReading(context: Context, result: ActivityRecognitionResult) {
        if (result.getActivityConfidence(DetectedActivity.IN_VEHICLE) >= SURE) {
            if (!isQuiet(context)) startRideService(context)
            return
        }
        val onFoot = maxOf(
            result.getActivityConfidence(DetectedActivity.ON_FOOT),
            result.getActivityConfidence(DetectedActivity.WALKING),
            result.getActivityConfidence(DetectedActivity.RUNNING),
        )
        if (onFoot >= SURE) clearQuiet(context)
    }

    private fun isQuiet(context: Context): Boolean {
        val since = taskPrefs(context).getString(TASK_KEY + QUIET, null)?.toLongOrNull()
            ?: return false
        return System.currentTimeMillis() - since < QUIET_FOR_MS
    }

    fun clearQuiet(context: Context) {
        taskPrefs(context).edit().remove(TASK_KEY + QUIET).apply()
    }

    // The Dart task looks for this on its beat: the vehicle part is over.
    fun noteVehicleExit(context: Context) {
        taskPrefs(context).edit()
            .putString(TASK_KEY + VEHICLE_EXIT, System.currentTimeMillis().toString())
            .remove(TASK_KEY + QUIET)
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

// Both kinds of Play services news: the transitions, and the backstop's
// readings.
class ActivityTransitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!RideDetection.isEnabled(context)) return
        if (ActivityTransitionResult.hasResult(intent)) {
            val result = ActivityTransitionResult.extractResult(intent) ?: return
            for (event in result.transitionEvents) {
                if (event.activityType != DetectedActivity.IN_VEHICLE) continue
                when (event.transitionType) {
                    ActivityTransition.ACTIVITY_TRANSITION_ENTER -> RideDetection.startRideService(context)
                    ActivityTransition.ACTIVITY_TRANSITION_EXIT -> RideDetection.noteVehicleExit(context)
                }
            }
        } else if (ActivityRecognitionResult.hasResult(intent)) {
            val result = ActivityRecognitionResult.extractResult(intent) ?: return
            RideDetection.onReading(context, result)
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
