package com.example.screen_time

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.app.usage.UsageStats
import android.content.Context
import android.os.Bundle
import android.provider.Settings
import android.content.Intent
import android.app.AppOpsManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*
import okhttp3.*
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.screen_time/usage"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getHourlyUsage") {
                val date = call.argument<String>("date") ?: ""
                val usageData = getHourlyUsage(date)
                result.success(usageData)
            } else if (call.method == "hasUsageStatsPermission") {
                result.success(hasUsageStatsPermission())
            } else if (call.method == "requestUsageStatsPermission") {
                requestUsageStatsPermission()
                result.success(null)
            } else if (call.method == "postScreenTime") {
                val date = call.argument<String>("date") ?: ""
                val usageData = getHourlyUsage(date)
                postScreenTime(date, usageData) { response ->
                    result.success(response)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOpsManager.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            appOpsManager.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun getHourlyUsage(date: String): Map<String, Long> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    
        val dateFormat = java.text.SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        val targetDate = dateFormat.parse(date)

        // Get start and end times for yesterday
        val calendar = Calendar.getInstance()
        calendar.time = targetDate
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = startTime + 24 * 60 * 60 * 1000 - 1
    
        // Query events
        val events = usageStatsManager.queryEvents(startTime, endTime)
        val hourlyUsage = mutableMapOf<Int, Long>()

        for (hour in 0 until 24) {
            hourlyUsage[hour] = 0L
        }

        var lastEventTimestamp: Long? = null
        var lastEventType: Int? = null

        while (events.hasNextEvent()) {
            val event = UsageEvents.Event()
            events.getNextEvent(event)

            // Only process foreground events
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED || event.eventType == UsageEvents.Event.ACTIVITY_PAUSED) {
                if (lastEventTimestamp == null && event.eventType == UsageEvents.Event.ACTIVITY_PAUSED && event.timeStamp < startTime + 3600000) {
                    // Assume the activity started at the beginning of the time range
                    // This assumption is made to handle cases where the first event is a pause event
                    lastEventTimestamp = startTime
                    lastEventType = UsageEvents.Event.ACTIVITY_RESUMED
                }

                if (lastEventTimestamp != null && lastEventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                    val duration = event.timeStamp - lastEventTimestamp
                    var hour = Calendar.getInstance().apply {
                        timeInMillis = lastEventTimestamp ?: 0
                    }.get(Calendar.HOUR_OF_DAY)

                    // start from last event time and accumulate time for the respective hour
                    // each hour starts at milliseconds that are multiples of 3600000
                    // next whole hour is calculated by adding 3600000 to the current hour
                    // and removing modulo of 3600000
                    // start of hour
                    val startOfHour = lastEventTimestamp!! - (lastEventTimestamp!! % 3600000)
                    var nextHour = startOfHour + 3600000
                    while (nextHour <= event.timeStamp) {
                        val existing = hourlyUsage[hour] ?: 0
                        hourlyUsage[hour] = existing + (nextHour - lastEventTimestamp!!)
                        lastEventTimestamp = nextHour
                        hour = (hour + 1) % 24
                        nextHour += 3600000
                    }

                    hourlyUsage[hour] = hourlyUsage[hour]?.plus(event.timeStamp - lastEventTimestamp!!) ?: event.timeStamp - lastEventTimestamp!!
                }

                // Update the last event details
                lastEventTimestamp = event.timeStamp
                lastEventType = event.eventType
            }
        }

        // Convert hour keys to string ranges and milliseconds to seconds
        return hourlyUsage.mapKeys { entry ->
            val hour = entry.key
            // "${hour}:00 - ${hour + 1}:00"
            "${hour}"
        }.mapValues { entry ->
            entry.value / 1000 // Convert milliseconds to seconds
        }
    }

    private fun postScreenTime(date: String, usageData: Map<String, Long>, callback: (String) -> Unit) {
        val deviceId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)

        val client = OkHttpClient()
        val url = "https://rrostt-simplescreentimeapi.web.val.run"
        val json = JSONObject().apply {
            put("deviceId", deviceId)
            put("screenTimeEntries", JSONArray().apply {
                usageData.forEach { (hour, seconds) ->
                    put(JSONObject().apply {
                        val formattedHour = "$date $hour"
                        put("hour", formattedHour)
                        put("seconds", seconds)
                    })
                }
            })
        }

        val body = json.toString().toRequestBody("application/json; charset=utf-8".toMediaType())
        val request = Request.Builder()
            .url(url)
            .post(body)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                callback("{\"error\": \"${e.message}\"}")
            }

            override fun onResponse(call: Call, response: Response) {
                val responseBody = response.body?.string()
                if (response.isSuccessful) {
                    callback(responseBody ?: "{\"message\": \"Unknown response\"}")
                } else {
                    callback("{\"error\": \"${response.message}\"}")
                }
            }
        })
    }
}
