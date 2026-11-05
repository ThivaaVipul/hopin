package app.hopin

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import android.util.Log
import com.pravera.flutter_foreground_task.service.ForegroundService
import com.pravera.flutter_foreground_task.service.ForegroundServiceManager

// "On a bus" in quick settings (docs/PLAN.md, Ride detection): one tap starts
// watching the ride, for the rides Play services doesn't notice, and a tap
// while it's on ends the ride, as End does. With ride detection off, or when
// Android won't let the service start from here, it opens Hopin, which starts
// watching from the screen.
class RideTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        show()
    }

    override fun onClick() {
        super.onClick()
        if (ForegroundService.isRunningServiceState.value) {
            end()
            return
        }
        if (!RideDetection.isEnabled(this)) {
            open(watch = false)
            return
        }
        try {
            RideDetection.watchNow(this)
            show(watching = true)
        } catch (e: Exception) {
            Log.w(TAG, "Could not start watching from the tile: ${e.message}")
            open(watch = true)
        }
    }

    // Stops the ride service the way the Dart task's own End does; the task
    // keeps the ride and leaves its quiet mark.
    private fun end() {
        try {
            ForegroundServiceManager().stop(this)
        } catch (e: Exception) {
            Log.w(TAG, "Could not end the ride from the tile: ${e.message}")
        }
        show(watching = false)
    }

    private fun show(watching: Boolean = ForegroundService.isRunningServiceState.value) {
        val tile = qsTile ?: return
        tile.state = if (watching) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = getString(R.string.tile_on_a_bus)
        tile.updateTile()
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun open(watch: Boolean) {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            .putExtra(MainActivity.WATCH, watch)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this,
                    0,
                    intent,
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private companion object {
        const val TAG = "RideTileService"
    }
}
