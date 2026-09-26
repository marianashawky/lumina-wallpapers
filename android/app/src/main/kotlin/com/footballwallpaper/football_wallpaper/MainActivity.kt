package com.footballwallpaper.football_wallpaper

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "football_wallpaper/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "setWallpaper" -> {
                        val path = call.argument<String>("path")
                        val target = call.argument<String>("target") ?: "both"
                        result.success(if (path.isNullOrEmpty()) "fail" else applyStatic(path, target))
                    }
                    "setLiveWallpaper" -> {
                        val path = call.argument<String>("path")
                        val kind = call.argument<String>("kind") ?: "motion"
                        result.success(if (path.isNullOrEmpty()) "fail" else applyLive(path, kind))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun applyStatic(path: String, target: String): String {
        return try {
            val (w, h) = WallpaperBitmaps.screenSize(this)
            val decoded = WallpaperBitmaps.decode(path, w, h) ?: return "fail"
            val fitted = WallpaperBitmaps.containOnScreen(decoded, w, h)
            if (fitted !== decoded) decoded.recycle()
            val wm = WallpaperManager.getInstance(this)
            if (Build.VERSION.SDK_INT >= 24) {
                val flags = when (target) {
                    "home" -> WallpaperManager.FLAG_SYSTEM
                    "lock" -> WallpaperManager.FLAG_LOCK
                    else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                }
                wm.setBitmap(fitted, null, true, flags)
            } else {
                @Suppress("DEPRECATION")
                wm.setBitmap(fitted)
            }
            "ok"
        } catch (_: Exception) {
            "fail"
        }
    }

    private fun applyLive(path: String, kind: String): String {
        return try {
            val video = kind == "video"
            val dest = File(filesDir, if (video) "live_current.mp4" else "live_current.jpg")
            File(path).copyTo(dest, overwrite = true)
            File(filesDir, if (video) "live_current.jpg" else "live_current.mp4").delete()
            getSharedPreferences(LuminaWallpaperService.PREFS, MODE_PRIVATE)
                .edit()
                .putString(LuminaWallpaperService.KEY_PATH, dest.absolutePath)
                .putString(LuminaWallpaperService.KEY_KIND, if (video) "video" else "motion")
                .apply()
            sendBroadcast(
                Intent(LuminaWallpaperService.ACTION_RELOAD).setPackage(packageName),
            )
            val info = WallpaperManager.getInstance(this).wallpaperInfo
            val alreadyOurs = info?.component?.className == LuminaWallpaperService::class.java.name
            if (alreadyOurs) return "ok"
            val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                putExtra(
                    WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                    ComponentName(this@MainActivity, LuminaWallpaperService::class.java),
                )
            }
            try {
                startActivity(intent)
                "picker"
            } catch (_: Exception) {
                if (video) "fail" else applyStatic(dest.absolutePath, "both")
            }
        } catch (_: Exception) {
            "fail"
        }
    }
}
