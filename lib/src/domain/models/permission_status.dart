/// Represents the status of calendar permissions
enum PermissionStatus {
  /// Permission has been granted by the user
  granted('granted'),

  /// Permission has been denied by the user
  denied('denied'),

  /// Permission is restricted (e.g., parental controls)
  restricted('restricted'),

  /// Permission has not been requested yet
  notDetermined('notDetermined');

  const PermissionStatus(this.platformValue);

  /// String representation for native platforms
  final String platformValue;

  /// Returns true if permission is granted
  bool get isGranted => this == PermissionStatus.granted;

  /// Returns true if permission is denied
  bool get isDenied => this == PermissionStatus.denied;

  /// Returns true if permission is restricted
  bool get isRestricted => this == PermissionStatus.restricted;

  /// Returns true if permission is not determined
  bool get isNotDetermined => this == PermissionStatus.notDetermined;

  /// Creates PermissionStatus from platform string
  static PermissionStatus fromPlatformValue(String value) {
    for (final status in PermissionStatus.values) {
      if (status.platformValue == value) {
        return status;
      }
    }
    throw ArgumentError('Invalid permission status: $value');
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() => {'status': platformValue};

  /// Creates from JSON
  static PermissionStatus fromJson(Map<String, dynamic> json) {
    return fromPlatformValue(json['status'] as String);
  }
}
