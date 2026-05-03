package com.belluga_now

import android.content.Intent
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.belluga_now/deferred_link"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getInstallReferrer") {
                    fetchInstallReferrer(result)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun fetchInstallReferrer(result: MethodChannel.Result) {
        val client = InstallReferrerClient.newBuilder(applicationContext).build()

        client.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                when (responseCode) {
                    InstallReferrerClient.InstallReferrerResponse.OK -> {
                        try {
                            val details = client.installReferrer
                            val payload = hashMapOf<String, Any?>(
                                "install_referrer" to details.installReferrer,
                                "referrer_click_timestamp_seconds" to details.referrerClickTimestampSeconds,
                                "install_begin_timestamp_seconds" to details.installBeginTimestampSeconds,
                            )
                            result.success(payload)
                        } catch (error: Throwable) {
                            result.error(
                                "install_referrer_error",
                                error.message ?: "install_referrer_error",
                                null,
                            )
                        } finally {
                            client.endConnection()
                        }
                    }

                    InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED,
                    InstallReferrerClient.InstallReferrerResponse.SERVICE_UNAVAILABLE,
                    InstallReferrerClient.InstallReferrerResponse.DEVELOPER_ERROR -> {
                        result.success(null)
                        client.endConnection()
                    }

                    else -> {
                        result.success(null)
                        client.endConnection()
                    }
                }
            }

            override fun onInstallReferrerServiceDisconnected() {
                // No-op. First-open capture runs once and does not need retry loops.
            }
        })
    }
}
