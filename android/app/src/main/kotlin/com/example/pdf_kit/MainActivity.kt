package cloud.nexiotech.pdfseva

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "all_files_access"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"openAllFiles" -> {
						try {
							openAllFilesAccessSettings()
							result.success(true)
						} catch (e: Exception) {
							result.error("OPEN_ALL_FILES_FAILED", e.message, null)
						}
					}
					"openAppPermissions" -> {
						try {
							openAppPermissionsSettings()
							result.success(true)
						} catch (e: Exception) {
							result.error("OPEN_APP_PERMS_FAILED", e.message, null)
						}
					}
					else -> result.notImplemented()
				}
			}
	}

	private fun openAllFilesAccessSettings() {
		val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
			Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
				data = Uri.parse("package:$packageName")
			}
		} else {
			// Fallback for older devices (should generally not be needed for MANAGE_EXTERNAL_STORAGE).
			Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
				data = Uri.parse("package:$packageName")
			}
		}

		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

		try {
			startActivity(intent)
		} catch (_: Exception) {
			// Some OEMs may not support the app-specific screen; fallback to the generic one.
			val fallback = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
			fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			startActivity(fallback)
		}
	}

	private fun openAppPermissionsSettings() {
		val pkgUri = Uri.parse("package:$packageName")

		val candidates = listOf(
			Intent("android.settings.APP_PERMISSION_SETTINGS").apply {
				data = pkgUri
				putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
				putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
			},
			Intent("android.settings.MANAGE_APP_PERMISSIONS").apply {
				data = pkgUri
				putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
			},
			Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
				data = pkgUri
			}
		)

		for (intent in candidates) {
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			val resolved = intent.resolveActivity(packageManager)
			if (resolved != null) {
				startActivity(intent)
				return
			}
		}

		// As a final fallback try app details without checking resolver.
		val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
			data = pkgUri
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}
		startActivity(fallback)
	}
}