package com.ahmtydn.calendar_bridge

sealed class CalendarException(
    val code: String,
    override val message: String,
    val details: String? = null
) : Exception(message) {

    class PermissionDenied(details: String? = null) : CalendarException(
        code = "PERMISSION_DENIED",
        message = "Calendar permissions not granted",
        details = details
    )

    class CalendarNotFound(calendarId: String) : CalendarException(
        code = "CALENDAR_NOT_FOUND",
        message = "Calendar not found",
        details = calendarId
    )

    class EventNotFound(eventId: String) : CalendarException(
        code = "EVENT_NOT_FOUND",
        message = "Event not found",
        details = eventId
    )

    class InvalidArgument(message: String, details: String? = null) : CalendarException(
        code = "INVALID_ARGUMENT",
        message = message,
        details = details
    )

    class UnsupportedOperation(operation: String) : CalendarException(
        code = "UNSUPPORTED_OPERATION",
        message = "Operation not supported on this platform",
        details = operation
    )

    class PlatformError(message: String, details: String? = null) : CalendarException(
        code = "PLATFORM_ERROR",
        message = message,
        details = details
    )
}