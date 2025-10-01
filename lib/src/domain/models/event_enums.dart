/// Represents the status of an event
enum EventStatus {
  /// Event is confirmed
  confirmed('CONFIRMED'),

  /// Event is tentative
  tentative('TENTATIVE'),

  /// Event is canceled
  canceled('CANCELED'),

  /// Event status is unknown or not set
  none('NONE');

  /// Constructor
  const EventStatus(this.value);

  /// Create EventStatus from string
  factory EventStatus.fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CONFIRMED':
        return EventStatus.confirmed;
      case 'TENTATIVE':
        return EventStatus.tentative;
      case 'CANCELED':
        return EventStatus.canceled;
      case 'NONE':
      default:
        return EventStatus.none;
    }
  }

  /// String value of the status
  final String value;

  @override
  String toString() => value;
}

/// Represents the availability status of an event
enum EventAvailability {
  /// Event time is marked as busy
  busy('BUSY'),

  /// Event time is marked as free
  free('FREE'),

  /// Event time is marked as tentative
  tentative('TENTATIVE'),

  /// Event time is marked as unavailable
  unavailable('UNAVAILABLE');

  /// Constructor
  const EventAvailability(this.value);

  /// Create EventAvailability from string
  factory EventAvailability.fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BUSY':
        return EventAvailability.busy;
      case 'FREE':
        return EventAvailability.free;
      case 'TENTATIVE':
        return EventAvailability.tentative;
      case 'UNAVAILABLE':
        return EventAvailability.unavailable;
      default:
        return EventAvailability.busy;
    }
  }

  /// String value of the availability
  final String value;

  @override
  String toString() => value;
}
