package com.mkl.financemanager

import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.mkl.financemanager/launcher_icon"

        private val ALIASES = linkedMapOf(
            "graphite_champagne" to "com.mkl.financemanager.MainActivityGraphite",
            "obsidian_jade" to "com.mkl.financemanager.MainActivityJade",
            "arctic_blue" to "com.mkl.financemanager.MainActivityArctic",
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCurrentLauncherIcon" -> result.success(currentLauncherIcon())
                    "setLauncherIcon" -> {
                        val iconKey = call.argument<String>("iconKey")
                        val targetAlias = ALIASES[iconKey]
                        if (iconKey == null || targetAlias == null) {
                            result.error("UNKNOWN_ICON", "Unknown launcher icon: $iconKey", null)
                            return@setMethodCallHandler
                        }

                        try {
                            switchLauncherIcon(targetAlias)
                            if (currentLauncherIcon() == iconKey) {
                                result.success(true)
                            } else {
                                result.error(
                                    "INCOMPLETE_SWITCH",
                                    "Launcher components did not reach the requested state",
                                    null,
                                )
                            }
                        } catch (error: Exception) {
                            result.error("SWITCH_FAILED", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun switchLauncherIcon(targetAlias: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val settings = ALIASES.values.map { alias ->
                PackageManager.ComponentEnabledSetting(
                    ComponentName(this, alias),
                    if (alias == targetAlias) {
                        PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                    } else {
                        PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                    },
                    PackageManager.DONT_KILL_APP,
                )
            }
            packageManager.setComponentEnabledSettings(settings)
            return
        }

        // Older Android has no atomic batch API. Enable the target first so a
        // failure never leaves the app without a launcher entry point.
        setAliasState(targetAlias, PackageManager.COMPONENT_ENABLED_STATE_ENABLED)
        var firstError: Exception? = null
        ALIASES.values
            .filterNot { it == targetAlias }
            .forEach { alias ->
                try {
                    setAliasState(alias, PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
                } catch (error: Exception) {
                    if (firstError == null) firstError = error
                }
            }
        firstError?.let { throw it }
    }

    private fun setAliasState(alias: String, state: Int) {
        val component = ComponentName(this, alias)
        if (packageManager.getComponentEnabledSetting(component) != state) {
            packageManager.setComponentEnabledSetting(
                component,
                state,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    private fun currentLauncherIcon(): String? {
        val enabledKeys = ALIASES.filter { (_, alias) -> isAliasEnabled(alias) }.keys
        return enabledKeys.singleOrNull()
    }

    private fun isAliasEnabled(alias: String): Boolean {
        val component = ComponentName(this, alias)
        return when (packageManager.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED_UNTIL_USED -> false
            else -> packageManager.getActivityInfo(
                component,
                PackageManager.MATCH_DISABLED_COMPONENTS,
            ).enabled
        }
    }
}
