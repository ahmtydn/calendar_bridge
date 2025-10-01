import 'package:meta/meta.dart';

/// Represents an attendee of a calendar event
@immutable
class Attendee {
  /// Creates a new attendee
  const Attendee({
    /// Email address of the attendee
    required this.email,

    /// Display name of the attendee
    this.name,

    /// Role of the attendee
    this.role = AttendeeRole.required,

    /// Response status of the attendee
    this.status = AttendeeStatus.unknown,

    /// Whether this attendee is the current user
    this.isCurrentUser = false,
  });

  /// Create an Attendee from JSON
  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      email: json['email'] as String,
      name: json['name'] as String?,
      role: AttendeeRole.fromString(json['role'] as String? ?? 'required'),
      status: AttendeeStatus.fromString(json['status'] as String? ?? 'unknown'),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  /// Email address of the attendee
  final String email;

  /// Display name of the attendee
  final String? name;

  /// Role of the attendee
  final AttendeeRole role;

  /// Response status of the attendee
  final AttendeeStatus status;

  /// Whether this attendee is the current user
  final bool isCurrentUser;

  /// Convert Attendee to JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'role': role.value,
      'status': status.value,
      'isCurrentUser': isCurrentUser,
    };
  }

  /// Create a copy of this Attendee with modified properties
  Attendee copyWith({
    String? email,
    String? name,
    AttendeeRole? role,
    AttendeeStatus? status,
    bool? isCurrentUser,
  }) {
    return Attendee(
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      status: status ?? this.status,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Attendee) return false;
    return email == other.email &&
        name == other.name &&
        role == other.role &&
        status == other.status &&
        isCurrentUser == other.isCurrentUser;
  }

  @override
  int get hashCode {
    return Object.hash(email, name, role, status, isCurrentUser);
  }

  @override
  String toString() {
    return 'Attendee(email: $email, name: $name, role: $role, '
        'status: $status, isCurrentUser: $isCurrentUser)';
  }
}

/// Role of an attendee in an event
enum AttendeeRole {
  /// Required attendee - their presence is mandatory
  required,

  /// Optional attendee - their presence is not mandatory
  optional,

  /// Chair/organizer of the event
  chair,

  /// Non-participant - receives information but does not participate
  nonParticipant;

  /// Get the string value for JSON serialization
  String get value {
    switch (this) {
      case AttendeeRole.required:
        return 'required';
      case AttendeeRole.optional:
        return 'optional';
      case AttendeeRole.chair:
        return 'chair';
      case AttendeeRole.nonParticipant:
        return 'non-participant';
    }
  }

  /// Create AttendeeRole from string value
  static AttendeeRole fromString(String value) {
    switch (value) {
      case 'required':
        return AttendeeRole.required;
      case 'optional':
        return AttendeeRole.optional;
      case 'chair':
        return AttendeeRole.chair;
      case 'non-participant':
        return AttendeeRole.nonParticipant;
      default:
        return AttendeeRole.required;
    }
  }
}

/// Response status of an attendee
enum AttendeeStatus {
  /// Status is unknown or not set
  unknown,

  /// Invitation is pending response
  pending,

  /// Attendee has accepted the invitation
  accepted,

  /// Attendee has declined the invitation
  declined,

  /// Attendee has tentatively accepted the invitation
  tentative;

  /// Get the string value for JSON serialization
  String get value {
    switch (this) {
      case AttendeeStatus.unknown:
        return 'unknown';
      case AttendeeStatus.pending:
        return 'pending';
      case AttendeeStatus.accepted:
        return 'accepted';
      case AttendeeStatus.declined:
        return 'declined';
      case AttendeeStatus.tentative:
        return 'tentative';
    }
  }

  /// Create AttendeeStatus from string value
  static AttendeeStatus fromString(String value) {
    switch (value) {
      case 'unknown':
        return AttendeeStatus.unknown;
      case 'pending':
        return AttendeeStatus.pending;
      case 'accepted':
        return AttendeeStatus.accepted;
      case 'declined':
        return AttendeeStatus.declined;
      case 'tentative':
        return AttendeeStatus.tentative;
      default:
        return AttendeeStatus.unknown;
    }
  }
}
