package com.ahmtydn.calendar_bridge

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Color
import android.net.Uri
import android.provider.CalendarContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class CalendarManager(private val context: Context) {
    
    companion object {
        const val PERMISSION_REQUEST_CODE = 1000
    }
    
    private var activity: Activity? = null

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    fun hasPermissions(): String {
        val readGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
        
        val writeGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.WRITE_CALENDAR
        ) == PackageManager.PERMISSION_GRANTED
        
        return when {
            readGranted && writeGranted -> "granted"
            else -> "denied"
        }
    }
    
    fun hasPermissionsBoolean(): Boolean {
        return hasPermissions() == "granted"
    }

    fun requestPermissions(activity: Activity) {
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(
                Manifest.permission.READ_CALENDAR,
                Manifest.permission.WRITE_CALENDAR
            ),
            PERMISSION_REQUEST_CODE
        )
    }

    suspend fun retrieveCalendars(): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        if (!hasPermissionsBoolean()) {
            throw CalendarException.PermissionDenied()
        }

        val calendars = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.CALENDAR_COLOR,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.ACCOUNT_TYPE,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
            CalendarContract.Calendars.IS_PRIMARY
        )

        val cursor: Cursor? = context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                val id = it.getLong(0).toString()
                val name = it.getString(1) ?: ""
                val color = it.getInt(2)
                val accountName = it.getString(3) ?: ""
                val accountType = it.getString(4) ?: ""
                val accessLevel = it.getInt(5)
                val isPrimary = it.getInt(6) == 1

                val isReadOnly = accessLevel < CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR

                calendars.add(mapOf(
                    "id" to id,
                    "name" to name,
                    "color" to color,
                    "accountName" to accountName,
                    "accountType" to accountType,
                    "isReadOnly" to isReadOnly,
                    "isDefault" to isPrimary
                ))
            }
        }

        return@withContext calendars
    }

    suspend fun createCalendar(arguments: Map<String, Any>): Map<String, Any> = withContext(Dispatchers.IO) {
        if (!hasPermissionsBoolean()) {
            throw CalendarException.PermissionDenied()
        }

        val name = arguments["name"] as? String
            ?: throw CalendarException.InvalidArgument("Calendar name is required")

        if (name.trim().isEmpty()) {
            throw CalendarException.InvalidArgument("Calendar name cannot be empty")
        }

        val color = arguments["color"] as? Int ?: Color.BLUE
        val localAccountName = arguments["localAccountName"] as? String ?: "Local"

        val values = ContentValues().apply {
            put(CalendarContract.Calendars.ACCOUNT_NAME, localAccountName)
            put(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            put(CalendarContract.Calendars.NAME, name)
            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, name)
            put(CalendarContract.Calendars.CALENDAR_COLOR, color)
            put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
            put(CalendarContract.Calendars.OWNER_ACCOUNT, localAccountName)
            put(CalendarContract.Calendars.CALENDAR_TIME_ZONE, java.util.TimeZone.getDefault().id)
            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
            put(CalendarContract.Calendars.VISIBLE, 1)
        }

        // Use sync adapter query params to allow writing ACCOUNT_NAME/ACCOUNT_TYPE
        // See: https://developer.android.com/reference/android/provider/CalendarContract.Calendars
        val insertUri = CalendarContract.Calendars.CONTENT_URI.buildUpon()
            .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, localAccountName)
            .appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, CalendarContract.ACCOUNT_TYPE_LOCAL)
            .build()

        val uri = try {
            context.contentResolver.insert(insertUri, values)
        } catch (e: IllegalArgumentException) {
            throw CalendarException.PlatformError("Failed to create calendar: ${e.message}")
        } ?: throw CalendarException.PlatformError("Failed to create calendar")

        val calendarId = uri.lastPathSegment
            ?: throw CalendarException.PlatformError("Failed to get calendar ID")

        return@withContext mapOf(
            "id" to calendarId,
            "name" to name,
            "color" to color,
            "accountName" to localAccountName,
            "accountType" to CalendarContract.ACCOUNT_TYPE_LOCAL,
            "isReadOnly" to false,
            "isDefault" to false
        )
    }

    suspend fun deleteCalendar(calendarId: String): Boolean = withContext(Dispatchers.IO) {
        if (!hasPermissionsBoolean()) {
            throw CalendarException.PermissionDenied()
        }

        if (calendarId.trim().isEmpty()) {
            throw CalendarException.InvalidArgument("Calendar ID cannot be empty")
        }

        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL
        )

        val cursor = context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            "${CalendarContract.Calendars._ID} = ?",
            arrayOf(calendarId),
            null
        )

        cursor?.use {
            if (!it.moveToFirst()) {
                throw CalendarException.CalendarNotFound(calendarId)
            }

            val accessLevel = it.getInt(1)
            if (accessLevel < CalendarContract.Calendars.CAL_ACCESS_OWNER) {
                throw CalendarException.InvalidArgument("Cannot delete read-only calendar")
            }
        } ?: throw CalendarException.CalendarNotFound(calendarId)

        val deletedRows = context.contentResolver.delete(
            CalendarContract.Calendars.CONTENT_URI,
            "${CalendarContract.Calendars._ID} = ?",
            arrayOf(calendarId)
        )

        return@withContext deletedRows > 0
    }

    suspend fun getCalendarColors(): Map<String, Int> = withContext(Dispatchers.IO) {
        if (!hasPermissionsBoolean()) {
            throw CalendarException.PermissionDenied()
        }

        val colors = mutableMapOf<String, Int>()
        val projection = arrayOf(
            CalendarContract.Colors.COLOR_KEY,
            CalendarContract.Colors.COLOR
        )

        val cursor: Cursor? = context.contentResolver.query(
            CalendarContract.Colors.CONTENT_URI,
            projection,
            "${CalendarContract.Colors.COLOR_TYPE} = ?",
            arrayOf(CalendarContract.Colors.TYPE_CALENDAR.toString()),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                val colorKey = it.getString(0) ?: continue
                val color = it.getInt(1)
                colors[colorKey] = color
            }
        }

        if (colors.isEmpty()) {
            colors["1"] = Color.parseColor("#FF0000")
            colors["2"] = Color.parseColor("#00FF00")
            colors["3"] = Color.parseColor("#0000FF")
            colors["4"] = Color.parseColor("#FFFF00")
            colors["5"] = Color.parseColor("#FFA500")
            colors["6"] = Color.parseColor("#800080")
            colors["7"] = Color.parseColor("#FFC0CB")
            colors["8"] = Color.parseColor("#A52A2A")
            colors["9"] = Color.parseColor("#808080")
            colors["10"] = Color.parseColor("#000000")
        }

        return@withContext colors
    }

    suspend fun getEventColors(calendarId: String): Map<String, Int> = withContext(Dispatchers.IO) {
        if (!hasPermissionsBoolean()) {
            throw CalendarException.PermissionDenied()
        }

        val colors = mutableMapOf<String, Int>()
        val projection = arrayOf(
            CalendarContract.Colors.COLOR_KEY,
            CalendarContract.Colors.COLOR
        )

        val cursor: Cursor? = context.contentResolver.query(
            CalendarContract.Colors.CONTENT_URI,
            projection,
            "${CalendarContract.Colors.COLOR_TYPE} = ?",
            arrayOf(CalendarContract.Colors.TYPE_EVENT.toString()),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                val colorKey = it.getString(0) ?: continue
                val color = it.getInt(1)
                colors[colorKey] = color
            }
        }

        if (colors.isEmpty()) {
            colors["1"] = Color.parseColor("#FF0000")
            colors["2"] = Color.parseColor("#00FF00")
            colors["3"] = Color.parseColor("#0000FF")
            colors["4"] = Color.parseColor("#FFFF00")
            colors["5"] = Color.parseColor("#FFA500")
            colors["6"] = Color.parseColor("#800080")
            colors["7"] = Color.parseColor("#FFC0CB")
            colors["8"] = Color.parseColor("#A52A2A")
            colors["9"] = Color.parseColor("#808080")
            colors["10"] = Color.parseColor("#000000")
        }

        return@withContext colors
    }

    suspend fun updateCalendarColor(calendarId: String, colorKey: String): Boolean = withContext(Dispatchers.IO) {
        if (!hasPermissionsBoolean()) {
            throw CalendarException.PermissionDenied()
        }

        val projection = arrayOf(
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL
        )

        val cursor = context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            "${CalendarContract.Calendars._ID} = ?",
            arrayOf(calendarId),
            null
        )

        cursor?.use {
            if (!it.moveToFirst()) {
                throw CalendarException.CalendarNotFound(calendarId)
            }

            val accessLevel = it.getInt(0)
            if (accessLevel < CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR) {
                throw CalendarException.InvalidArgument("Cannot modify read-only calendar")
            }
        } ?: throw CalendarException.CalendarNotFound(calendarId)

        val colors = getCalendarColors()
        val colorValue = colors[colorKey] ?: colors.values.firstOrNull() ?: Color.BLUE

        val values = ContentValues().apply {
            put(CalendarContract.Calendars.CALENDAR_COLOR, colorValue)
        }

        val updatedRows = context.contentResolver.update(
            CalendarContract.Calendars.CONTENT_URI,
            values,
            "${CalendarContract.Calendars._ID} = ?",
            arrayOf(calendarId)
        )

        return@withContext updatedRows > 0
    }
}