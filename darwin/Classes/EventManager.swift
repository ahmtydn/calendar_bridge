import EventKit
import Foundation

class EventManager {
    private let eventStore: EKEventStore
    
    init(eventStore: EKEventStore) {
        self.eventStore = eventStore
    }
    
    private func eventIdString(_ event: EKEvent) -> String {
        #if os(iOS)
        return event.eventIdentifier
        #elseif os(macOS)
        return event.eventIdentifier ?? ""
        #endif
    }
    
    func retrieveEvents(calendarId: String, arguments: [String: Any]) throws -> [[String: Any]] {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw CalendarError.calendarNotFound(calendarId)
        }
        
        let startDate = extractDate(from: arguments["startDate"])
        let endDate = extractDate(from: arguments["endDate"])
        let eventIds = arguments["eventIds"] as? [String]
        
        var events: [EKEvent] = []
        
        if let eventIds = eventIds {
            // Retrieve specific events by ID
            for eventId in eventIds {
                if let event = eventStore.event(withIdentifier: eventId) {
                    events.append(event)
                }
            }
        } else {
            // Retrieve events by date range
            let predicate = eventStore.predicateForEvents(
                withStart: startDate ?? Date.distantPast,
                end: endDate ?? Date.distantFuture,
                calendars: [calendar]
            )
            events = eventStore.events(matching: predicate)
        }
        
        return events.map { event in
            return eventToDict(event: event)
        }
    }
    
    func createEvent(arguments: [String: Any]) throws -> String {
        guard let calendarId = arguments["calendarId"] as? String else {
            throw CalendarError.invalidArgument("Calendar ID is required")
        }
        
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw CalendarError.calendarNotFound(calendarId)
        }
        
        guard calendar.allowsContentModifications else {
            throw CalendarError.invalidArgument("Cannot create event in read-only calendar")
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        
        try populateEventFromDict(event: event, dict: arguments)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarError.platformError("Failed to create event: \(error.localizedDescription)")
        }
    }
    
    func updateEvent(arguments: [String: Any]) throws -> String {
        guard let eventId = arguments["eventId"] as? String else {
            throw CalendarError.invalidArgument("Event ID is required")
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound(eventId)
        }
        
        guard event.calendar.allowsContentModifications else {
            throw CalendarError.invalidArgument("Cannot update event in read-only calendar")
        }
        
        try populateEventFromDict(event: event, dict: arguments)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarError.platformError("Failed to update event: \(error.localizedDescription)")
        }
    }
    
    func deleteEvent(calendarId: String, eventId: String) throws -> Bool {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw CalendarError.calendarNotFound(calendarId)
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound(eventId)
        }
        
        guard calendar.allowsContentModifications else {
            throw CalendarError.invalidArgument("Cannot delete event from read-only calendar")
        }
        
        do {
            try eventStore.remove(event, span: .thisEvent)
            return true
        } catch {
            throw CalendarError.platformError("Failed to delete event: \(error.localizedDescription)")
        }
    }
    
    func deleteEventInstance(calendarId: String, eventId: String, startDate: Date, followingInstances: Bool) async throws -> Bool {
        guard let calendar = eventStore.calendar(withIdentifier: calendarId) else {
            throw CalendarError.calendarNotFound(calendarId)
        }
        
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound(eventId)
        }
        
        guard calendar.allowsContentModifications else {
            throw CalendarError.invalidArgument("Cannot delete event from read-only calendar")
        }
        
        do {
            let span: EKSpan = followingInstances ? .futureEvents : .thisEvent
            try eventStore.remove(event, span: span)
            return true
        } catch {
            throw CalendarError.platformError("Failed to delete event instance: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func populateEventFromDict(event: EKEvent, dict: [String: Any]) throws {
        if let title = dict["title"] as? String {
            event.title = title
        }
        
        if let description = dict["description"] as? String {
            event.notes = description
        }
        
        if let location = dict["location"] as? String {
            event.location = location
        }
        
        if let url = dict["url"] as? String {
            event.url = URL(string: url)
        }
        
        if let isAllDay = dict["allDay"] as? Bool {
            event.isAllDay = isAllDay
        }
        
        if let startDate = extractDate(from: dict["start"]) {
            event.startDate = startDate
        }
        
        if let endDate = extractDate(from: dict["end"]) {
            event.endDate = endDate
        }
        
        // Handle attendees
        if let attendeesData = dict["attendees"] as? [[String: Any]] {
            setAttendees(attendeesData, event)
        }
        
        // Handle reminders
        if let remindersData = dict["reminders"] as? [[String: Any]] {
            let alarms = remindersData.compactMap { reminderDict -> EKAlarm? in
                guard let minutes = reminderDict["minutes"] as? Int else { return nil }
                return EKAlarm(relativeOffset: TimeInterval(-minutes * 60))
            }
            event.alarms = alarms
        }
        
        // Handle availability
        if let availabilityString = dict["availability"] as? String {
            switch availabilityString {
            case "busy":
                event.availability = .busy
            case "free":
                event.availability = .free
            case "tentative":
                event.availability = .tentative
            case "out-of-office":
                if #available(iOS 9.0, *) {
                    event.availability = .unavailable
                } else {
                    event.availability = .busy
                }
            default:
                event.availability = .busy
            }
        }
        
        // Handle recurrence rule
        if let recurrenceDict = dict["recurrenceRule"] as? [String: Any] {
            event.recurrenceRules = createEKRecurrenceRules(recurrenceDict)
        }
    }
    
    private func eventToDict(event: EKEvent) -> [String: Any] {
        var dict: [String: Any] = [
            "eventId": eventIdString(event),
            "calendarId": event.calendar.calendarIdentifier,
            "title": event.title ?? "",
            "allDay": event.isAllDay
        ]
        
        if let description = event.notes {
            dict["description"] = description
        }
        
        if let location = event.location {
            dict["location"] = location
        }
        
        if let url = event.url {
            dict["url"] = url.absoluteString
        }
        
        dict["start"] = Int(event.startDate.timeIntervalSince1970 * 1000)
        dict["end"] = Int(event.endDate.timeIntervalSince1970 * 1000)
        
        // Handle attendees
        if let attendees = event.attendees {
            let attendeesData = attendees.map { attendee in
                #if os(iOS)
                var email = ""
                let url = attendee.url
                if url.scheme == "mailto" {
                    email = String(url.absoluteString.dropFirst(7)) 
                } else {
                    email = url.absoluteString
                }
                #elseif os(macOS)
                let email = attendee.url.absoluteString
                #endif
                return [
                    "email": email,
                    "name": attendee.name ?? "",
                    "role": attendeeRoleToString(attendee.participantRole),
                    "status": attendeeStatusToString(attendee.participantStatus)
                ]
            }
            dict["attendees"] = attendeesData
        }
        
        // Handle reminders
        if let alarms = event.alarms {
            let remindersData = alarms.compactMap { alarm -> [String: Any]? in
                #if os(iOS)
                guard let relativeOffset = alarm.relativeOffset as? TimeInterval else { return nil }
                #elseif os(macOS)
                let relativeOffset = alarm.relativeOffset
                #endif
                return ["minutes": Int(-relativeOffset / 60)]
            }
            dict["reminders"] = remindersData
        }
        
        // Handle availability
        dict["availability"] = availabilityToString(event.availability)
        
        // Handle status
        dict["status"] = statusToString(event.status)
        
        var originalStartDate: Int64? = nil
        
        if let masterItem = eventStore.calendarItem(withIdentifier: event.calendarItemIdentifier) as? EKEvent {
            originalStartDate = Int64(masterItem.startDate.millisecondsSinceEpoch)
        } else {
            if event.hasRecurrenceRules {
                originalStartDate = Int64(event.startDate.millisecondsSinceEpoch)
            } else {
                originalStartDate = Int64(event.startDate.millisecondsSinceEpoch)
            }
        }
        
        if let originalStart = originalStartDate {
            dict["originalStart"] = originalStart
        }
        
        return dict
    }
    
    private func extractDate(from value: Any?) -> Date? {
        guard let timestamp = value as? NSNumber else { return nil }
        return Date(timeIntervalSince1970: timestamp.doubleValue / 1000.0)
    }
    
    private func attendeeRoleToString(_ role: EKParticipantRole) -> String {
        switch role {
        case .required:
            return "required"
        case .optional:
            return "optional"
        case .chair:
            return "chair"
        case .nonParticipant:
            return "non-participant"
        case .unknown:
            return "unknown"
        @unknown default:
            return "required"
        }
    }
    
    private func attendeeStatusToString(_ status: EKParticipantStatus) -> String {
        switch status {
        case .unknown:
            return "unknown"
        case .pending:
            return "pending"
        case .accepted:
            return "accepted"
        case .declined:
            return "declined"
        case .tentative:
            return "tentative"
        case .delegated:
            return "tentative"
        case .completed:
            return "accepted"
        case .inProcess:
            return "pending"
        @unknown default:
            return "unknown"
        }
    }
    
    private func availabilityToString(_ availability: EKEventAvailability) -> String {
        switch availability {
        case .notSupported:
            return "busy"
        case .busy:
            return "busy"
        case .free:
            return "free"
        case .tentative:
            return "tentative"
        case .unavailable:
            return "out-of-office"
        @unknown default:
            return "busy"
        }
    }
    
    private func statusToString(_ status: EKEventStatus) -> String {
        #if os(iOS)
        switch status {
        case .none:
            return "confirmed"
        case .confirmed:
            return "confirmed"
        case .tentative:
            return "tentative"
        case .canceled:
            return "cancelled"
        @unknown default:
            return "confirmed"
        }
        #elseif os(macOS)
        switch status {
        case .none:
            return "confirmed"
        case .confirmed:
            return "confirmed"
        case .tentative:
            return "tentative"
        case .canceled:
            return "cancelled"
        @unknown default:
            return "confirmed"
        }
        #endif
    }
    
    // MARK: - Recurrence Rule Handling
    
    private func createEKRecurrenceRules(_ recurrenceDict: [String: Any]) -> [EKRecurrenceRule]? {
        guard let frequency = recurrenceDict["freq"] as? String else { return nil }
        
        let interval = recurrenceDict["interval"] as? Int ?? 1
        let count = recurrenceDict["count"] as? Int
        let until = recurrenceDict["until"] as? String
        
        var ekFrequency: EKRecurrenceFrequency
        switch frequency.uppercased() {
        case "DAILY":
            ekFrequency = .daily
        case "WEEKLY":
            ekFrequency = .weekly
        case "MONTHLY":
            ekFrequency = .monthly
        case "YEARLY":
            ekFrequency = .yearly
        default:
            ekFrequency = .daily
        }
        
        var recurrenceEnd: EKRecurrenceEnd?
        if let count = count, count > 0 {
            recurrenceEnd = EKRecurrenceEnd(occurrenceCount: count)
        } else if let until = until {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            if let endDate = dateFormatter.date(from: until) {
                recurrenceEnd = EKRecurrenceEnd(end: endDate)
            }
        }
        
        // Parse BYDAY values
        var daysOfWeek: [EKRecurrenceDayOfWeek]?
        if let byDayStrings = recurrenceDict["byday"] as? [String] {
            daysOfWeek = byDayStrings.compactMap { recurrenceDayOfWeekFromString($0) }
        }
        
        // Parse BYMONTHDAY values
        var daysOfMonth: [NSNumber]?
        if let byMonthDays = recurrenceDict["bymonthday"] as? [Int] {
            daysOfMonth = byMonthDays.map { NSNumber(value: $0) }
        }
        
        // Parse BYMONTH values
        var monthsOfYear: [NSNumber]?
        if let byMonths = recurrenceDict["bymonth"] as? [Int] {
            monthsOfYear = byMonths.map { NSNumber(value: $0) }
        }
        
        // Parse BYYEARDAY values
        var daysOfYear: [NSNumber]?
        if let byYearDays = recurrenceDict["byyearday"] as? [Int] {
            daysOfYear = byYearDays.map { NSNumber(value: $0) }
        }
        
        // Parse BYWEEKNO values
        var weeksOfYear: [NSNumber]?
        if let byWeeks = recurrenceDict["byweekno"] as? [Int] {
            weeksOfYear = byWeeks.map { NSNumber(value: $0) }
        }
        
        // Parse BYSETPOS values
        var setPositions: [NSNumber]?
        if let bySetPos = recurrenceDict["bysetpos"] as? [Int] {
            setPositions = bySetPos.map { NSNumber(value: $0) }
        }
        
        let rule = EKRecurrenceRule(
            recurrenceWith: ekFrequency,
            interval: interval,
            daysOfTheWeek: daysOfWeek,
            daysOfTheMonth: daysOfMonth,
            monthsOfTheYear: monthsOfYear,
            weeksOfTheYear: weeksOfYear,
            daysOfTheYear: daysOfYear,
            setPositions: setPositions,
            end: recurrenceEnd
        )
        
        return [rule]
    }
    
    private func recurrenceDayOfWeekFromString(_ dayString: String) -> EKRecurrenceDayOfWeek? {
        // Parse strings like "MO", "TU", "1MO", "-1SU" etc.
        let pattern = "^(?:(\\+|-)?([0-9]{1,2}))?([A-Z]{2})$"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: dayString, range: NSRange(dayString.startIndex..., in: dayString)) else {
            return nil
        }
        
        var weekNumber: Int = 0
        var dayOfWeek: EKWeekday
        
        // Extract week number if present
        if match.range(at: 2).location != NSNotFound {
            let weekNumberString = String(dayString[Range(match.range(at: 2), in: dayString)!])
            weekNumber = Int(weekNumberString) ?? 0
            
            // Check for minus sign
            if match.range(at: 1).location != NSNotFound {
                let signString = String(dayString[Range(match.range(at: 1), in: dayString)!])
                if signString == "-" {
                    weekNumber = -weekNumber
                }
            }
        }
        
        // Extract day of week
        let dayString = String(dayString[Range(match.range(at: 3), in: dayString)!])
        switch dayString {
        case "SU": dayOfWeek = .sunday
        case "MO": dayOfWeek = .monday
        case "TU": dayOfWeek = .tuesday
        case "WE": dayOfWeek = .wednesday
        case "TH": dayOfWeek = .thursday
        case "FR": dayOfWeek = .friday
        case "SA": dayOfWeek = .saturday
        default: return nil
        }
        
        if weekNumber != 0 {
            return EKRecurrenceDayOfWeek(dayOfTheWeek: dayOfWeek, weekNumber: weekNumber)
        } else {
            return EKRecurrenceDayOfWeek(dayOfWeek)
        }
    }
    
    // MARK: - Attendee Handling
    
    private func setAttendees(_ attendeesData: [[String: Any]], _ event: EKEvent) {
        var attendees = [EKParticipant]()
        
        for attendeeDict in attendeesData {
            guard let email = attendeeDict["email"] as? String else { continue }
            let name = attendeeDict["name"] as? String ?? ""
            let role = attendeeDict["role"] as? Int ?? EKParticipantRole.required.rawValue
            
            // Check if attendee already exists
            if let existingAttendees = event.attendees {
                if let existingAttendee = existingAttendees.first(where: { participant in
                    return extractEmailFromParticipant(participant) == email
                }) {
                    attendees.append(existingAttendee)
                    continue
                }
            }
            
            // Create new participant
            if let participant = createParticipant(name: name, emailAddress: email, role: role) {
                attendees.append(participant)
            }
        }
        
        // Use KVC to set attendees (this is a workaround since attendees is normally read-only)
        event.setValue(attendees, forKey: "attendees")
    }
    
    private func createParticipant(name: String, emailAddress: String, role: Int) -> EKParticipant? {
        // This uses a private API approach similar to the reference implementation
        guard let ekAttendeeClass = NSClassFromString("EKAttendee") as? NSObject.Type else {
            return nil
        }
        
        let participant = ekAttendeeClass.init()
        participant.setValue(UUID().uuidString, forKey: "UUID")
        participant.setValue(name, forKey: "displayName")
        participant.setValue(emailAddress, forKey: "emailAddress")
        participant.setValue(role, forKey: "participantRole")
        
        return participant as? EKParticipant
    }
    
    private func extractEmailFromParticipant(_ participant: EKParticipant) -> String {
        #if os(iOS)
        let url = participant.url
        if url.scheme == "mailto" {
            return String(url.absoluteString.dropFirst(7))
        } else {
            return url.absoluteString
        }
        #elseif os(macOS)
        // For macOS, try to get email from the URL or use reflection to access emailAddress
        if let emailAddress = participant.value(forKey: "emailAddress") as? String {
            return emailAddress
        }
        return participant.url.absoluteString
        #endif
    }
}

// MARK: - Extensions

extension Date {
    var millisecondsSinceEpoch: Double {
        return self.timeIntervalSince1970 * 1000.0
    }
}