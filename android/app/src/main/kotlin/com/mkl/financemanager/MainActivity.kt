package com.mkl.financemanager

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mkl.financemanager/launcher_icon"

    private val ALIAS_MAP = mapOf(
        "graphite_champagne" to "com.mkl.financemanager.MainActivityGraphite",
        "obsidian_jade" to "com.mkl.financemanager.MainActivityJade",
        "arctic_blue" to "com.mkl.financemanager.MainActivityArctic",
        "graphite" to "com.mkl.financemanager.MainActivityGraphite",
        "jade" to "com.mkl.financemanager.MainActivityJade",
        "arctic" to "com.mkl.financemanager.MainActivityArctic"
    )

    private val ORDERED_KEYS = listOf("graphite_champagne", "obsidian_jade", "arctic_blue")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setLauncherIcon" -> {
                    val iconKey = call.argument<String>("iconKey")
                    if (iconKey == null) {
                        result.error("INVALID_ARGUMENT", "iconKey cannot be null", null)
                        return@setMethodCallHandler
                    }
                    val targetAlias = ALIAS_MAP[iconKey]
                    if (targetAlias == null) {
                        result.error("UNKNOWN_ICON", "Unknown icon key: $iconKey", null)
                        return@setMethodCallHandler
                    }
                    val changed = updateLauncherIcon(targetAlias)
                    result.success(changed)
                }
                "getCurrentLauncherIcon" -> {
                    val currentKey = queryCurrentLauncherIcon()
                    result.success(currentKey)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun updateLauncherIcon(targetAlias: String): Boolean {
        return try {
            val pm = packageManager
            val allAliases = listOf(
                "com.mkl.financemanager.MainActivityGraphite",
                "com.mkl.financemanager.MainActivityJade",
                "com.mkl.financemanager.MainActivityArctic"
            )

            for (alias in allAliases) {
                val component = ComponentName(this, alias)
                val currentState = pm.getComponentEnabledSetting(component)
                val targetState = if (alias == targetAlias) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                }

                if (currentState != targetState) {
                    pm.setComponentEnabledSetting(
                        component,
                        targetState,
                        PackageManager.DONT_KILL_APP
                    )
                }
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun queryCurrentLauncherIcon(): String {
        return try {
            val pm = packageManager
            for (key in ORDERED_KEYS) {
                val alias = ALIAS_MAP[key] ?: continue
                val component = ComponentName(this, alias)
                val state = pm.getComponentEnabledSetting(component)
                if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                    return key
                }
            }
            "graphite_champagne"
        } catch (e: Exception) {
            "graphite_champagne"
        }
    }
}
