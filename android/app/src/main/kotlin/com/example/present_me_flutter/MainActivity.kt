package com.example.present_me_flutter

import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.location.LocationManager

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.present_me/wifi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSSID" -> {
                    val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                    var ssid = wifiManager.connectionInfo.ssid

                    if (ssid.startsWith("\"") && ssid.endsWith("\"")) {
                        ssid = ssid.substring(1, ssid.length - 1)
                    }

                    result.success(ssid)
                }
                "openHotspotSettings" -> {
                    openHotspotSettings()
                    result.success(null)
                }
                "isHotspotEnabled" -> {
                    val isEnabled = isWifiApEnabled()
                    result.success(isEnabled)
                }
                "isLocationEnabled" -> {
                    val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
                    val isLocationEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                            locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
                    result.success(isLocationEnabled)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openHotspotSettings() {
        val intent = Intent(Settings.ACTION_WIRELESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun isWifiApEnabled(): Boolean {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        return try {
            val method = wifiManager.javaClass.getDeclaredMethod("isWifiApEnabled")
            method.isAccessible = true
            method.invoke(wifiManager) as Boolean
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
