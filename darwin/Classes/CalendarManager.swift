import EventKit
import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class CalendarManager {
    private let eventStore: EKEventStore
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }
    
    private func calendarColorToInt(_ calendar: EKCalendar) -> Int {
        #if os(iOS)
        return UIColor(cgColor: calendar.cgColor).toColorInt()
        #elseif os(macOS)
        return calendar.color.toColorInt()
        #endif
    }
    
    func retrieveCalendars() throws -> [[String: Any]] {
        let ekCalendars = eventStore.calendars(for: .event)
        return ekCalendars.map { calendar in
            return [
                "id": calendar.calendarIdentifier,
                "name": calendar.title,
                "color": calendarColorToInt(calendar),
                "accountName": calendar.source?.title ?? "",
                "accountType": calendar.source?.sourceType.description ?? "",
                "isReadOnly": !calendar.allowsContentModifications,
                "isDefault": calendar == eventStore.defaultCalendarForNewEvents
            ]
        }
    }
    
    func createCalendar(arguments: [String: Any]) throws -> [String: Any] {
        guard let name = arguments["name"] as? String, !name.isEmpty else {
            throw CalendarError.invalidArgument("Calendar name is required")
        }
        
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = name
        
        // Set color if provided
        if let colorValue = arguments["color"] as? Int {
            #if os(iOS)
            calendar.cgColor = UIColor.fromColorInt(colorValue).cgColor
            #elseif os(macOS)
            calendar.color = NSColor.fromColorInt(colorValue)
            #endif
        }
        
        // Find appropriate source
        let source = findBestSource(localAccountName: arguments["localAccountName"] as? String)
        calendar.source = source
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return [
                "id": calendar.calendarIdentifier,
                "name": calendar.title,
                "color": calendarColorToInt(calendar),
                "accountName": calendar.source?.title ?? "",
                "accountType": calendar.source?.sourceType.description ?? "",
                "isReadOnly": !calendar.allowsContentModifications,
                "isDefault": false
            ]
        } catch {
            throw CalendarError.platformError("Failed to create calendar: \(error.localizedDescription)")
        }
    }
    
    func deleteCalendar(calendarId: String) throws -> Bool {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw CalendarError.calendarNotFound(calendarId)
        }
        
        guard calendar.allowsContentModifications else {
            throw CalendarError.invalidArgument("Cannot delete read-only calendar")
        }
        
        do {
            try eventStore.removeCalendar(calendar, commit: true)
            return true
        } catch {
            throw CalendarError.platformError("Failed to delete calendar: \(error.localizedDescription)")
        }
    }
    
    func updateCalendarColor(calendarId: String, colorKey: String) throws -> Bool {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw CalendarError.calendarNotFound(calendarId)
        }
        
        guard calendar.allowsContentModifications else {
            throw CalendarError.invalidArgument("Cannot modify read-only calendar")
        }
        
        // Map color key to actual color
        let colorValue = colorKeyToInt(colorKey)
        
        #if os(iOS)
        calendar.cgColor = UIColor.fromColorInt(colorValue).cgColor
        #elseif os(macOS)
        calendar.color = NSColor.fromColorInt(colorValue)
        #endif
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return true
        } catch {
            throw CalendarError.platformError("Failed to update calendar color: \(error.localizedDescription)")
        }
    }
    
    private func colorKeyToInt(_ colorKey: String) -> Int {
        switch colorKey.lowercased() {
        case "red": return 0xFFFF0000
        case "green": return 0xFF00FF00
        case "blue": return 0xFF0000FF
        case "yellow": return 0xFFFFFF00
        case "orange": return 0xFFFFA500
        case "purple": return 0xFF800080
        case "pink": return 0xFFFFC0CB
        case "brown": return 0xFFA52A2A
        case "gray": return 0xFF808080
        case "black": return 0xFF000000
        default: return 0xFF0000FF // Default to blue
        }
    }
    
    private func findBestSource(localAccountName: String?) -> EKSource {
        let sources = eventStore.sources
        
        // Try to find local source first
        if let localSource = sources.first(where: { $0.sourceType == .local }) {
            return localSource
        }
        
        // Try to find by account name if provided
        if let accountName = localAccountName {
            if let namedSource = sources.first(where: { 
                $0.title.lowercased().contains(accountName.lowercased()) 
            }) {
                return namedSource
            }
        }
        
        // Fall back to default source that supports event creation
        #if os(iOS)
        return sources.first { $0.sourceType != .subscribed && 
                             $0.sourceType != .birthdays } ?? sources.first!
        #elseif os(macOS)
        return sources.first(where: { $0.sourceType != .subscribed }) ?? sources.first!
        #endif
    }
}

// MARK: - Extensions

#if os(iOS)
extension UIColor {
    func toColorInt() -> Int {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        let a = Int(alpha * 255)
        
        return (a << 24) | (r << 16) | (g << 8) | b
    }
    
    static func fromColorInt(_ value: Int) -> UIColor {
        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        let alpha = CGFloat((value >> 24) & 0xFF) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#elseif os(macOS)
extension NSColor {
    func toColorInt() -> Int {
        let red = Int(self.redComponent * 255)
        let green = Int(self.greenComponent * 255)
        let blue = Int(self.blueComponent * 255)
        let alpha = Int(self.alphaComponent * 255)
        return (alpha << 24) | (red << 16) | (green << 8) | blue
    }
    
    static func fromColorInt(_ value: Int) -> NSColor {
        let red = CGFloat((value >> 16) & 0xFF) / 255.0
        let green = CGFloat((value >> 8) & 0xFF) / 255.0
        let blue = CGFloat(value & 0xFF) / 255.0
        let alpha = CGFloat((value >> 24) & 0xFF) / 255.0
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif

extension EKSourceType {
    var description: String {
        switch self {
        case .local:
            return "Local"
        case .exchange:
            return "Exchange"
        case .calDAV:
            return "CalDAV"
        case .mobileMe:
            return "MobileMe"
        case .subscribed:
            return "Subscribed"
        case .birthdays:
            return "Birthdays"
        @unknown default:
            return "Unknown"
        }
    }
}