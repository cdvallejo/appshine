package com.carlosvallejo.appshine

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.provider.MediaStore

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.carlosvallejo.appshine/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanFile" -> {
                        val path = call.argument<String>("path")
                        if (path != null) {
                            val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                            intent.data = android.net.Uri.parse("file://$path")
                            sendBroadcast(intent)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGUMENT", "Path cannot be null", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
