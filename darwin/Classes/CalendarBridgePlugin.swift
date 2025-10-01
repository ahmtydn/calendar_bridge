#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import Cocoa
import FlutterMacOS
#endif
import EventKit
import Foundation

public class CalendarBridgePlugin: NSObject, FlutterPlugin {
    private let eventStore = EKEventStore()
    private let calendarManager: CalendarManager
    private let eventManager: EventManager
    
    override init() {
        self.calendarManager = CalendarManager(eventStore: eventStore)
        self.eventManager = EventManager(eventStore: eventStore)
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let channel = FlutterMethodChannel(
            name: "com.ahmtydn/calendar_bridge",
            binaryMessenger: registrar.messenger()
        )
        #elseif os(macOS)
        let channel = FlutterMethodChannel(
            name: "com.ahmtydn/calendar_bridge",
            binaryMessenger: registrar.messenger
        )
        #endif
        let instance = CalendarBridgePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Task {
            do {
                switch call.method {
                case "requestPermissions":
                    let granted = await requestPermissions()
                    result(granted)
                    
                case "hasPermissions":
                    let permissionStatus = hasPermissions()
                    result(permissionStatus)
                    
                case "retrieveCalendars":
                    try await handleRetrieveCalendars(result: result)
                    
                case "retrieveEvents":
                    try await handleRetrieveEvents(call: call, result: result)
                    
                case "createEvent":
                    try await handleCreateEvent(call: call, result: result)
                    
                case "updateEvent":
                    try await handleUpdateEvent(call: call, result: result)
                    
                case "deleteEvent":
                    try await handleDeleteEvent(call: call, result: result)
                    
                case "createCalendar":
                    try await handleCreateCalendar(call: call, result: result)
                    
                case "deleteCalendar":
                    try await handleDeleteCalendar(call: call, result: result)
                    
                case "retrieveCalendarColors":
                    try await handleRetrieveCalendarColors(result: result)
                    
                case "retrieveEventColors":
                    try await handleRetrieveEventColors(call: call, result: result)
                    
                case "updateCalendarColor":
                    try await handleUpdateCalendarColor(call: call, result: result)
                    
                case "deleteEventInstance":
                    try await handleDeleteEventInstance(call: call, result: result)
                    
                default:
                    result(FlutterMethodNotImplemented)
                }
            } catch {
                handleError(error: error, result: result)
            }
        }
    }
    
    // MARK: - Permission Management
    
    private func requestPermissions() async -> Bool {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
        #elseif os(macOS)
        return await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, error in              
                continuation.resume(returning: granted)
            }
        }
        #endif
    }
    
    private func hasPermissions() -> String {
        let status: EKAuthorizationStatus
        #if os(iOS)
        if #available(iOS 17.0, *) {
            status = EKEventStore.authorizationStatus(for: .event)
            switch status {
            case .fullAccess:
                return "granted"
            case .writeOnly:
                return "restricted"
            case .denied:
                return "denied"
            case .notDetermined:
                return "notDetermined"
            @unknown default:
                return "notDetermined"
            }
        } else {
            status = EKEventStore.authorizationStatus(for: .event)
            switch status {
            case .authorized:
                return "granted"
            case .denied:
                return "denied"
            case .restricted:
                return "restricted"
            case .notDetermined:
                return "notDetermined"
            @unknown default:
                return "notDetermined"
            }
        }
        #elseif os(macOS)
        status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized:
            return "granted"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "notDetermined"
        case .writeOnly:
            return "restricted" 
        case .fullAccess:
            return "granted"
        @unknown default:
            return "notDetermined"
        }
        #endif
    }
    
    private func checkPermissions() throws {
        guard hasPermissions() == "granted" else {
            throw CalendarError.permissionDenied
        }
    }
    
    // MARK: - Calendar Operations
    
    private func handleRetrieveCalendars(result: @escaping FlutterResult) async throws {
        try checkPermissions()
        let calendars = try calendarManager.retrieveCalendars()
        result(calendars)
    }
    
    private func handleCreateCalendar(call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        try checkPermissions()
        guard let arguments = call.arguments as? [String: Any] else {
            throw CalendarError.invalidArgument("Missing arguments")
        }
        let calendar = try calendarManager.createCalendar(arguments: arguments)
        result(calendar)
    }
    
    private func handleDeleteCalendar(call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        try checkPermissions()
        guard let arguments = call.arguments as? [String: Any],
              let calendarId = arguments["calendarId"] as? String else {
            throw CalendarError.invalidArgument("Calendar ID is required")
        }
        let success = try calendarManager.deleteCalendar(calendarId: calendarId)
        result(success)
    }
    
    // MARK: - Event Operations
    
    private func handleRetrieveEvents(call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        try checkPermissions()
        guard let arguments = call.arguments as? [String: Any],
              let calendarId = arguments["calendarId"] as? String else {
            throw CalendarError.invalidArgument("Calendar ID is required")
        }
        let events = try eventManager.retrieveEvents(calendarId: calendarId, arguments: arguments)
        result(events)
    }
    
    private func handleCreateEvent(call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        try checkPermissions()
        guard let arguments = call.arguments as? [String: Any] else {
            throw CalendarError.invalidArgument("Missing arguments")
        }
        let eventId = try eventManager.createEvent(arguments: arguments)
        result(eventId)
    }
    
    private func handleUpdateEvent(call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        try checkPermissions()
        guard let arguments = call.arguments as? [String: Any] else {
            throw CalendarError.invalidArgument("Missing arguments")
        }
        let eventId = try eventManager.updateEvent(arguments: arguments)
        result(eventId)
    }
    
    private func handleDeleteEvent(call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        try checkPermissions()
        guard let arguments = call.arguments as? [String: Any],
              let calendarId = arguments["calendarId"] as? String,
              let eventId = arguments["eventId"] as? String else {
            throw CalendarError.invalidArgument("Calendar ID and Event ID are required")
        }
        let success = try eventManager.deleteEvent(calendarId: calendarId, eventId: eventId)
        result(success)
    }
    
    // MARK: - Color Management
    
    private func handleRetrieveCalendarColors(result: @escaping FlutterResult) async throws {
        // iOS/macOS doesn't have predefined calendar colors like Android
        // We return some common colors that work well
        let colors: [String: Int] = [
            "red": 0xFFFF0000,
            "green": 0xFF00FF00,
            "blue": 0xFF0000FF,
            "yellow": 0xFFFFFF00,
            "orange": 0xFFFFA500,
            "purple": 0xFF800080,
            "pink": 0xFFFFC0CB,
            "brown": 0xFFA52A2A,
            "gray": 0xFF808080,
            "black": 0xFF000000
        ]
        result(colors)
    }
    
    private func handleRetrieveEventColors(call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        // iOS/macOS doesn't have calendar-specific event colors
        // Return the same common colors
        let colors: [String: Int] = [
            "red": 0xFFFF0000,
            "green": 0xFF00FF00,
            "blue": 0xFF0000FF,
            "yellow": 0xFFFFFF00,
            "orange": 0xFFFFA500,
            "purple": 0xFF800080,
            "pink": 0xFFFFC0CB,
            "brown": 0xFFA52A2A,
            "gray": 0xFF808080,
            "black": 0xFF000000
        ]
        result(colors)
    }
    
    private func handleUpdateCalendarColor(call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        try checkPermissions()
        
        guard let arguments = call.arguments as? [String: Any],
              let calendarId = arguments["calendarId"] as? String,
              let colorKey = arguments["colorKey"] as? String else {
            throw CalendarError.invalidArgument("Missing required arguments")
        }
        
        let success = try calendarManager.updateCalendarColor(calendarId: calendarId, colorKey: colorKey)
        result(success)
    }
    
    private func handleDeleteEventInstance(call: FlutterMethodCall, result: @escaping FlutterResult) async throws {
        try checkPermissions()
        
        guard let arguments = call.arguments as? [String: Any],
              let calendarId = arguments["calendarId"] as? String,
              let eventId = arguments["eventId"] as? String,
              let startDateMs = arguments["startDate"] as? Int64 else {
            throw CalendarError.invalidArgument("Missing required arguments")
        }
        
        let startDate = Date(timeIntervalSince1970: Double(startDateMs) / 1000.0)
        let followingInstances = arguments["followingInstances"] as? Bool ?? false
        
        let success = try await eventManager.deleteEventInstance(
            calendarId: calendarId,
            eventId: eventId,
            startDate: startDate,
            followingInstances: followingInstances
        )
        result(success)
    }
    
    // MARK: - Error Handling
    
    private func handleError(error: Error, result: @escaping FlutterResult) {
        let flutterError: FlutterError
        
        if let calendarError = error as? CalendarError {
            flutterError = calendarError.toFlutterError()
        } else {
            flutterError = FlutterError(
                code: "UNKNOWN_ERROR",
                message: "An unexpected error occurred",
                details: error.localizedDescription
            )
        }
        
        result(flutterError)
    }
}

// MARK: - Error Types

enum CalendarError: Error {
    case permissionDenied
    case calendarNotFound(String)
    case eventNotFound(String)  
    case invalidArgument(String)
    case unsupportedOperation(String)
    case platformError(String)
    
    func toFlutterError() -> FlutterError {
        switch self {
        case .permissionDenied:
            return FlutterError(
                code: "PERMISSION_DENIED",
                message: "Calendar permissions not granted",
                details: nil
            )
        case .calendarNotFound(let id):
            return FlutterError(
                code: "CALENDAR_NOT_FOUND",
                message: "Calendar not found",
                details: id
            )
        case .eventNotFound(let id):
            return FlutterError(
                code: "EVENT_NOT_FOUND", 
                message: "Event not found",
                details: id
            )
        case .invalidArgument(let message):
            return FlutterError(
                code: "INVALID_ARGUMENT",
                message: message,
                details: nil
            )
        case .unsupportedOperation(let operation):
            return FlutterError(
                code: "UNSUPPORTED_OPERATION",
                message: operation,
                details: nil
            )
        case .platformError(let message):
            return FlutterError(
                code: "PLATFORM_ERROR",
                message: message,
                details: nil
            )
        }
    }
}