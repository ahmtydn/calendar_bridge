import 'package:meta/meta.dart';

/// Represents a calendar in the device's calendar system
@immutable
class Calendar {
  /// Creates a new calendar instance
  const Calendar({
    /// Unique identifier for the calendar
    required this.id,

    /// Display name of the calendar
    required this.name,

    /// Color of the calendar (nullable for default)
    this.color,

    /// Account name associated with the calendar
    this.accountName,

    /// Account type (e.g., "Local", "Google", "iCloud")
    this.accountType,

    /// Whether the calendar is read-only
    this.isReadOnly = false,

    /// Whether the calendar is the default calendar
    this.isDefault = false,
  });

  /// Create a Calendar from JSON
  factory Calendar.fromJson(Map<String, dynamic> json) {
    return Calendar(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as int?,
      accountName: json['accountName'] as String?,
      accountType: json['accountType'] as String?,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Unique identifier for the calendar
  final String id;

  /// Display name of the calendar
  final String name;

  /// Color of the calendar (nullable for default)
  final int? color;

  /// Account name associated with the calendar
  final String? accountName;

  /// Account type (e.g., "Local", "Google", "iCloud")
  final String? accountType;

  /// Whether the calendar is read-only
  final bool isReadOnly;

  /// Whether the calendar is the default calendar
  final bool isDefault;

  /// Convert Calendar to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'accountName': accountName,
      'accountType': accountType,
      'isReadOnly': isReadOnly,
      'isDefault': isDefault,
    };
  }

  /// Create a copy of this Calendar with modified properties
  Calendar copyWith({
    String? id,
    String? name,
    int? color,
    String? accountName,
    String? accountType,
    bool? isReadOnly,
    bool? isDefault,
  }) {
    return Calendar(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Calendar) return false;
    return id == other.id &&
        name == other.name &&
        color == other.color &&
        accountName == other.accountName &&
        accountType == other.accountType &&
        isReadOnly == other.isReadOnly &&
        isDefault == other.isDefault;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      color,
      accountName,
      accountType,
      isReadOnly,
      isDefault,
    );
  }

  @override
  String toString() {
    return 'Calendar(id: $id, name: $name, color: $color, '
        'accountName: $accountName, accountType: $accountType, '
        'isReadOnly: $isReadOnly, isDefault: $isDefault)';
  }
}

/// Parameters for creating a new calendar
@immutable
class CreateCalendarParams {
  /// Creates new calendar creation parameters
  const CreateCalendarParams({
    /// Name of the new calendar
    required this.name,

    /// Optional color for the calendar
    this.color,

    /// Optional local account name
    this.localAccountName,
  });

  /// Create CreateCalendarParams from JSON
  factory CreateCalendarParams.fromJson(Map<String, dynamic> json) {
    return CreateCalendarParams(
      name: json['name'] as String,
      color: json['color'] as int?,
      localAccountName: json['localAccountName'] as String?,
    );
  }

  /// Name of the new calendar
  final String name;

  /// Optional color for the calendar
  final int? color;

  /// Optional local account name
  final String? localAccountName;

  /// Convert CreateCalendarParams to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'localAccountName': localAccountName,
    };
  }

  /// Create a copy of this CreateCalendarParams with modified properties
  CreateCalendarParams copyWith({
    String? name,
    int? color,
    String? localAccountName,
  }) {
    return CreateCalendarParams(
      name: name ?? this.name,
      color: color ?? this.color,
      localAccountName: localAccountName ?? this.localAccountName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CreateCalendarParams) return false;
    return name == other.name &&
        color == other.color &&
        localAccountName == other.localAccountName;
  }

  @override
  int get hashCode {
    return Object.hash(name, color, localAccountName);
  }

  @override
  String toString() {
    return 'CreateCalendarParams(name: $name, color: $color, '
        'localAccountName: $localAccountName)';
  }
}
