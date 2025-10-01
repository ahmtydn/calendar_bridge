package com.ahmtydn.calendar_bridge

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.provider.CalendarContract
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.text.SimpleDateFormat
import java.util.*

class EventManager(private val context: Context) {

    suspend fun retrieveEvents(calendarId: String, arguments: Map<String, Any>): List<Map<String, Any>> = withContext(Dispatchers.IO) {
        val events = mutableListOf<Map<String, Any>>()
        
        val startDate = arguments["startDate"] as? Long
        val endDate = arguments["endDate"] as? Long
        val eventIds = arguments["eventIds"] as? List<String>

        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Events.CALENDAR_ID,
            CalendarContract.Events.TITLE,
            CalendarContract.Events.DESCRIPTION,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Events.ALL_DAY,
            CalendarContract.Events.EVENT_LOCATION,
            CalendarContract.Events.AVAILABILITY,
            CalendarContract.Events.STATUS,
            CalendarContract.Events.RRULE,
            CalendarContract.Events.DTSTART
        )

        var selection: String
        var selectionArgs: Array<String>

        if (eventIds != null && eventIds.isNotEmpty()) {
            // Query specific events by ID
            val placeholders = eventIds.joinToString(",") { "?" }
            selection = "${CalendarContract.Instances.EVENT_ID} IN ($placeholders)"
            selectionArgs = eventIds.toTypedArray()
        } else {
            // Query by calendar and date range using Instances
            val selectionParts = mutableListOf("${CalendarContract.Events.CALENDAR_ID} = ?")
            val argsList = mutableListOf(calendarId)

            if (startDate != null) {
                selectionParts.add("${CalendarContract.Instances.END} >= ?")
                argsList.add(startDate.toString())
            }

            if (endDate != null) {
                selectionParts.add("${CalendarContract.Instances.BEGIN} <= ?")
                argsList.add(endDate.toString())
            }

            selection = selectionParts.joinToString(" AND ")
            selectionArgs = argsList.toTypedArray()
        }


        val instancesUri = CalendarContract.Instances.CONTENT_URI.buildUpon().apply {
            ContentUris.appendId(this, startDate ?: 0L)
            ContentUris.appendId(this, endDate ?: Long.MAX_VALUE)
        }.build()

        val cursor: Cursor? = context.contentResolver.query(
            instancesUri,
            projection,
            selection,
            selectionArgs,
            "${CalendarContract.Instances.BEGIN} ASC"
        )

        cursor?.use {
            while (it.moveToNext()) {
                val eventId = it.getLong(0).toString()
                val eventCalendarId = it.getLong(1).toString()
                val title = it.getString(2) ?: ""
                val description = it.getString(3)
                val startTime = it.getLong(4)
                val endTime = it.getLong(5)
                val allDay = it.getInt(6) == 1
                val location = it.getString(7)
                val availability = it.getInt(8)
                val status = it.getInt(9)
                val rrule = it.getString(10)
                val originalStartTime = it.getLong(11)

                val eventMap = mutableMapOf<String, Any>(
                    "eventId" to eventId,
                    "calendarId" to eventCalendarId,
                    "title" to title,
                    "start" to startTime,
                    "end" to endTime,
                    "allDay" to allDay,
                    "availability" to availabilityToString(availability),
                    "status" to statusToString(status)
                )

                description?.let { eventMap["description"] = it }
                location?.let { eventMap["location"] = it }
                rrule?.let { eventMap["recurrenceRule"] = it }
  
                if (rrule != null) {
                    eventMap["originalStart"] = originalStartTime
                }

                // Get attendees
                val attendees = getEventAttendees(eventId)
                if (attendees.isNotEmpty()) {
                    eventMap["attendees"] = attendees
                }

                // Get reminders
                val reminders = getEventReminders(eventId)
                if (reminders.isNotEmpty()) {
                    eventMap["reminders"] = reminders
                }

                events.add(eventMap)
            }
        }

        return@withContext events
    }

    suspend fun createEvent(arguments: Map<String, Any>): String = withContext(Dispatchers.IO) {
        val calendarId = arguments["calendarId"] as? String
            ?: throw CalendarException.InvalidArgument("Calendar ID is required")

        val title = arguments["title"] as? String
            ?: throw CalendarException.InvalidArgument("Event title is required")

        val startTime = arguments["start"] as? Long
            ?: throw CalendarException.InvalidArgument("Event start time is required")

        val endTime = arguments["end"] as? Long
            ?: throw CalendarException.InvalidArgument("Event end time is required")

        if (startTime >= endTime) {
            throw CalendarException.InvalidArgument("Event start time must be before end time")
        }

        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId.toLong())
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DTSTART, startTime)
            put(CalendarContract.Events.DTEND, endTime)
            put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
            put(CalendarContract.Events.ALL_DAY, if (arguments["allDay"] as? Boolean == true) 1 else 0)
            
            arguments["description"]?.let { 
                put(CalendarContract.Events.DESCRIPTION, it as String)
            }
            
            arguments["location"]?.let { 
                put(CalendarContract.Events.EVENT_LOCATION, it as String)
            }
            
            arguments["availability"]?.let { 
                put(CalendarContract.Events.AVAILABILITY, availabilityFromString(it as String))
            }
            
            arguments["status"]?.let { 
                put(CalendarContract.Events.STATUS, statusFromString(it as String))
            }
            
            arguments["recurrenceRule"]?.let { 
                put(CalendarContract.Events.RRULE, it as String)
            }
        }

        val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)
            ?: throw CalendarException.PlatformError("Failed to create event")

        val eventId = uri.lastPathSegment
            ?: throw CalendarException.PlatformError("Failed to get event ID")

        // Add attendees if provided
        arguments["attendees"]?.let { attendees ->
            addEventAttendees(eventId, attendees as List<Map<String, Any>>)
        }

        // Add reminders if provided
        arguments["reminders"]?.let { reminders ->
            addEventReminders(eventId, reminders as List<Map<String, Any>>)
        }

        return@withContext eventId
    }

    suspend fun updateEvent(arguments: Map<String, Any>): String = withContext(Dispatchers.IO) {
        val eventId = arguments["eventId"] as? String
            ?: throw CalendarException.InvalidArgument("Event ID is required")

        // Check if event exists
        val cursor = context.contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            arrayOf(CalendarContract.Events._ID),
            "${CalendarContract.Events._ID} = ?",
            arrayOf(eventId),
            null
        )

        cursor?.use {
            if (!it.moveToFirst()) {
                throw CalendarException.EventNotFound(eventId)
            }
        } ?: throw CalendarException.EventNotFound(eventId)

        val values = ContentValues()
        
        arguments["title"]?.let { 
            values.put(CalendarContract.Events.TITLE, it as String)
        }
        
        arguments["description"]?.let { 
            values.put(CalendarContract.Events.DESCRIPTION, it as String)
        }
        
        arguments["location"]?.let { 
            values.put(CalendarContract.Events.EVENT_LOCATION, it as String)
        }
        
        arguments["start"]?.let { 
            values.put(CalendarContract.Events.DTSTART, it as Long)
        }
        
        arguments["end"]?.let { 
            values.put(CalendarContract.Events.DTEND, it as Long)
        }
        
        arguments["allDay"]?.let { 
            values.put(CalendarContract.Events.ALL_DAY, if (it as Boolean) 1 else 0)
        }
        
        arguments["availability"]?.let { 
            values.put(CalendarContract.Events.AVAILABILITY, availabilityFromString(it as String))
        }
        
        arguments["status"]?.let { 
            values.put(CalendarContract.Events.STATUS, statusFromString(it as String))
        }
        
        arguments["recurrenceRule"]?.let { 
            values.put(CalendarContract.Events.RRULE, it as String)
        }

        val updatedRows = context.contentResolver.update(
            CalendarContract.Events.CONTENT_URI,
            values,
            "${CalendarContract.Events._ID} = ?",
            arrayOf(eventId)
        )

        if (updatedRows == 0) {
            throw CalendarException.PlatformError("Failed to update event")
        }

        // Update attendees if provided
        arguments["attendees"]?.let { attendees ->
            // Delete existing attendees
            context.contentResolver.delete(
                CalendarContract.Attendees.CONTENT_URI,
                "${CalendarContract.Attendees.EVENT_ID} = ?",
                arrayOf(eventId)
            )
            // Add new attendees
            addEventAttendees(eventId, attendees as List<Map<String, Any>>)
        }

        // Update reminders if provided
        arguments["reminders"]?.let { reminders ->
            // Delete existing reminders
            context.contentResolver.delete(
                CalendarContract.Reminders.CONTENT_URI,
                "${CalendarContract.Reminders.EVENT_ID} = ?",
                arrayOf(eventId)
            )
            // Add new reminders
            addEventReminders(eventId, reminders as List<Map<String, Any>>)
        }

        return@withContext eventId
    }

    suspend fun deleteEvent(calendarId: String, eventId: String): Boolean = withContext(Dispatchers.IO) {
        // Verify event exists in the specified calendar
        val cursor = context.contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            arrayOf(CalendarContract.Events._ID, CalendarContract.Events.CALENDAR_ID),
            "${CalendarContract.Events._ID} = ? AND ${CalendarContract.Events.CALENDAR_ID} = ?",
            arrayOf(eventId, calendarId),
            null
        )

        cursor?.use {
            if (!it.moveToFirst()) {
                throw CalendarException.EventNotFound(eventId)
            }
        } ?: throw CalendarException.EventNotFound(eventId)

        val deletedRows = context.contentResolver.delete(
            CalendarContract.Events.CONTENT_URI,
            "${CalendarContract.Events._ID} = ?",
            arrayOf(eventId)
        )

        return@withContext deletedRows > 0
    }

    suspend fun deleteEventInstance(calendarId: String, eventId: String, startDate: Long, followingInstances: Boolean): Boolean = withContext(Dispatchers.IO) {
        // Verify event exists in the specified calendar
        val cursor = context.contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            arrayOf(CalendarContract.Events._ID, CalendarContract.Events.CALENDAR_ID, CalendarContract.Events.RRULE),
            "${CalendarContract.Events._ID} = ? AND ${CalendarContract.Events.CALENDAR_ID} = ?",
            arrayOf(eventId, calendarId),
            null
        )

        var isRecurring = false
        cursor?.use {
            if (!it.moveToFirst()) {
                throw CalendarException.EventNotFound(eventId)
            }
            val rrule = it.getString(2)
            isRecurring = !rrule.isNullOrEmpty()
        } ?: throw CalendarException.EventNotFound(eventId)

        // For recurring events, create an exception instead of deleting
        if (isRecurring) {
            val exceptionValues = ContentValues().apply {
                put(CalendarContract.Events.ORIGINAL_ID, eventId)
                put(CalendarContract.Events.ORIGINAL_INSTANCE_TIME, startDate)
                put(CalendarContract.Events.CALENDAR_ID, calendarId)
                put(CalendarContract.Events.STATUS, CalendarContract.Events.STATUS_CANCELED)
                
                if (followingInstances) {
                    // For future events, we need to modify the original event's RRULE
                    // This is a simplified implementation - in practice, you'd need to update the RRULE
                    put(CalendarContract.Events.DTSTART, startDate)
                }
            }

            val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, exceptionValues)
            return@withContext uri != null
        } else {
            // For non-recurring events, just delete normally
            return@withContext deleteEvent(calendarId, eventId)
        }
    }

    private fun getEventAttendees(eventId: String): List<Map<String, Any>> {
        val attendees = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(
            CalendarContract.Attendees.ATTENDEE_EMAIL,
            CalendarContract.Attendees.ATTENDEE_NAME,
            CalendarContract.Attendees.ATTENDEE_RELATIONSHIP,
            CalendarContract.Attendees.ATTENDEE_STATUS
        )

        val cursor = context.contentResolver.query(
            CalendarContract.Attendees.CONTENT_URI,
            projection,
            "${CalendarContract.Attendees.EVENT_ID} = ?",
            arrayOf(eventId),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                val email = it.getString(0) ?: ""
                val name = it.getString(1)
                val relationship = it.getInt(2)
                val status = it.getInt(3)

                attendees.add(mapOf(
                    "email" to email,
                    "name" to (name ?: email),
                    "role" to attendeeRoleToString(relationship),
                    "status" to attendeeStatusToString(status)
                ))
            }
        }

        return attendees
    }

    private fun getEventReminders(eventId: String): List<Map<String, Any>> {
        val reminders = mutableListOf<Map<String, Any>>()
        val projection = arrayOf(CalendarContract.Reminders.MINUTES)

        val cursor = context.contentResolver.query(
            CalendarContract.Reminders.CONTENT_URI,
            projection,
            "${CalendarContract.Reminders.EVENT_ID} = ?",
            arrayOf(eventId),
            null
        )

        cursor?.use {
            while (it.moveToNext()) {
                val minutes = it.getInt(0)
                reminders.add(mapOf("minutes" to minutes))
            }
        }

        return reminders
    }

    private fun addEventAttendees(eventId: String, attendees: List<Map<String, Any>>) {
        attendees.forEach { attendee ->
            val email = attendee["email"] as? String ?: return@forEach
            val name = attendee["name"] as? String ?: email
            val role = attendee["role"] as? String ?: "required"
            val status = attendee["status"] as? String ?: "pending"
            
            val values = ContentValues().apply {
                put(CalendarContract.Attendees.EVENT_ID, eventId.toLong())
                put(CalendarContract.Attendees.ATTENDEE_EMAIL, email)
                put(CalendarContract.Attendees.ATTENDEE_NAME, name)
                put(CalendarContract.Attendees.ATTENDEE_RELATIONSHIP, attendeeRoleFromString(role))
                put(CalendarContract.Attendees.ATTENDEE_STATUS, attendeeStatusFromString(status))
                put(CalendarContract.Attendees.ATTENDEE_TYPE, CalendarContract.Attendees.TYPE_REQUIRED)
            }

            context.contentResolver.insert(CalendarContract.Attendees.CONTENT_URI, values)
        }
    }

    private fun addEventReminders(eventId: String, reminders: List<Map<String, Any>>) {
        reminders.forEach { reminder ->
            val minutes = reminder["minutes"] as? Int ?: return@forEach
            
            val values = ContentValues().apply {
                put(CalendarContract.Reminders.EVENT_ID, eventId.toLong())
                put(CalendarContract.Reminders.MINUTES, minutes)
                put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
            }

            context.contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, values)
        }
    }

    private fun availabilityToString(availability: Int): String {
        return when (availability) {
            CalendarContract.Events.AVAILABILITY_BUSY -> "busy"
            CalendarContract.Events.AVAILABILITY_FREE -> "free"
            CalendarContract.Events.AVAILABILITY_TENTATIVE -> "tentative"
            else -> "busy"
        }
    }

    private fun availabilityFromString(availability: String): Int {
        return when (availability.lowercase()) {
            "free" -> CalendarContract.Events.AVAILABILITY_FREE
            "tentative" -> CalendarContract.Events.AVAILABILITY_TENTATIVE
            else -> CalendarContract.Events.AVAILABILITY_BUSY
        }
    }

    private fun statusToString(status: Int): String {
        return when (status) {
            CalendarContract.Events.STATUS_CONFIRMED -> "confirmed"
            CalendarContract.Events.STATUS_TENTATIVE -> "tentative"
            CalendarContract.Events.STATUS_CANCELED -> "cancelled"
            else -> "confirmed"
        }
    }

    private fun statusFromString(status: String): Int {
        return when (status.lowercase()) {
            "tentative" -> CalendarContract.Events.STATUS_TENTATIVE
            "cancelled" -> CalendarContract.Events.STATUS_CANCELED
            else -> CalendarContract.Events.STATUS_CONFIRMED
        }
    }

    private fun attendeeRoleToString(relationship: Int): String {
        return when (relationship) {
            CalendarContract.Attendees.RELATIONSHIP_ATTENDEE -> "required"
            CalendarContract.Attendees.RELATIONSHIP_ORGANIZER -> "chair"
            CalendarContract.Attendees.RELATIONSHIP_PERFORMER -> "required"
            CalendarContract.Attendees.RELATIONSHIP_SPEAKER -> "required"
            else -> "required"
        }
    }

    private fun attendeeStatusToString(status: Int): String {
        return when (status) {
            CalendarContract.Attendees.ATTENDEE_STATUS_ACCEPTED -> "accepted"
            CalendarContract.Attendees.ATTENDEE_STATUS_DECLINED -> "declined"
            CalendarContract.Attendees.ATTENDEE_STATUS_INVITED -> "pending"
            CalendarContract.Attendees.ATTENDEE_STATUS_TENTATIVE -> "tentative"
            else -> "unknown"
        }
    }

    private fun attendeeRoleFromString(role: String): Int {
        return when (role.lowercase()) {
            "chair" -> CalendarContract.Attendees.RELATIONSHIP_ORGANIZER
            "required" -> CalendarContract.Attendees.RELATIONSHIP_ATTENDEE
            "optional" -> CalendarContract.Attendees.RELATIONSHIP_ATTENDEE
            else -> CalendarContract.Attendees.RELATIONSHIP_ATTENDEE
        }
    }

    private fun attendeeStatusFromString(status: String): Int {
        return when (status.lowercase()) {
            "accepted" -> CalendarContract.Attendees.ATTENDEE_STATUS_ACCEPTED
            "declined" -> CalendarContract.Attendees.ATTENDEE_STATUS_DECLINED
            "tentative" -> CalendarContract.Attendees.ATTENDEE_STATUS_TENTATIVE
            "pending" -> CalendarContract.Attendees.ATTENDEE_STATUS_INVITED
            else -> CalendarContract.Attendees.ATTENDEE_STATUS_INVITED
        }
    }
}