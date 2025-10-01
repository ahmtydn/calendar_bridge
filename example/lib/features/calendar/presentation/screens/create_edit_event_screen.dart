import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

import '../../../../core/providers/calendar_providers.dart';
import '../../../../core/theme/theme.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/recurrence_rule_picker.dart';

class CreateEditEventScreen extends ConsumerStatefulWidget {
  final CalendarEvent? event;
  final String? initialCalendarId;

  const CreateEditEventScreen({super.key, this.event, this.initialCalendarId});

  @override
  ConsumerState<CreateEditEventScreen> createState() =>
      _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends ConsumerState<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _urlController;

  // Form state
  String? _selectedCalendarId;
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay.now();
  bool _allDay = false;

  // Advanced features
  List<Attendee> _attendees = [];
  List<Reminder> _reminders = [];
  RecurrenceRule? _recurrenceRule;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _urlController = TextEditingController();

    // Initialize form with existing event data or defaults
    if (widget.event != null) {
      _initializeWithEvent(widget.event!);
    } else {
      _initializeDefaults();
    }
  }

  void _initializeWithEvent(CalendarEvent event) {
    _titleController.text = event.title ?? '';
    _descriptionController.text = event.description ?? '';
    _locationController.text = event.location ?? '';
    _urlController.text = event.url ?? '';

    _selectedCalendarId = event.calendarId;
    _allDay = event.allDay;
    if (event.start != null) {
      _startDate = event.start!.toLocal();
      _startTime = TimeOfDay.fromDateTime(_startDate);
    }

    if (event.end != null) {
      _endDate = event.end!.toLocal();
      _endTime = TimeOfDay.fromDateTime(_endDate);
    }

    _attendees = List.from(event.attendees);
    _reminders = List.from(event.reminders);
    _recurrenceRule = event.recurrenceRule;
  }

  void _initializeDefaults() {
    _selectedCalendarId = widget.initialCalendarId;

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
    _startTime = TimeOfDay.fromDateTime(_startDate);

    _endDate = _startDate.add(const Duration(hours: 1));
    _endTime = TimeOfDay.fromDateTime(_endDate);

    // Add default reminder
    _reminders = [Reminder.fifteenMinutesBefore()];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calendarsAsync = ref.watch(writableCalendarsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(onPressed: _saveEvent, child: const Text('Save')),
        ],
      ),
      body: calendarsAsync.when(
        data: (calendars) => _buildForm(calendars),
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget(
          error: error,
          onRetry: () => ref.invalidate(writableCalendarsProvider),
        ),
      ),
    );
  }

  Widget _buildForm(List<Calendar> calendars) {
    if (calendars.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: AppSpacing.md),
            Text('No writable calendars available'),
            Text('Create a calendar first to add events'),
          ],
        ),
      );
    }

    // Set default calendar if none selected
    if (_selectedCalendarId == null && calendars.isNotEmpty) {
      _selectedCalendarId = calendars.first.id;
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Calendar Selection
          _buildCalendarSelector(calendars),
          const SizedBox(height: AppSpacing.lg),

          // Basic Information
          _buildBasicInfoSection(),
          const SizedBox(height: AppSpacing.lg),

          // Date and Time
          _buildDateTimeSection(),
          const SizedBox(height: AppSpacing.lg),

          // Additional Options
          _buildAdditionalOptionsSection(),
          const SizedBox(height: AppSpacing.lg),

          // Advanced Features
          _buildAdvancedFeaturesSection(),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildCalendarSelector(List<Calendar> calendars) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calendar',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _selectedCalendarId,
              decoration: const InputDecoration(
                labelText: 'Select Calendar',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: calendars
                  .map(
                    (calendar) => DropdownMenuItem(
                      value: calendar.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            backgroundColor: Color(
                              calendar.color ?? 0xFF2196F3,
                            ),
                            radius: 12,
                            child: Text(
                              calendar.name.isNotEmpty
                                  ? calendar.name[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              calendar.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCalendarId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a calendar';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Event Title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an event title';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // URL
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL (optional)',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),

            // All Day Toggle
            SwitchListTile(
              title: const Text('All Day'),
              subtitle: const Text('Event lasts the entire day'),
              value: _allDay,
              onChanged: (value) {
                setState(() {
                  _allDay = value;
                  if (value) {
                    // Set to beginning and end of day
                    _startTime = const TimeOfDay(hour: 0, minute: 0);
                    _endTime = const TimeOfDay(hour: 23, minute: 59);
                  }
                });
              },
            ),
            const Divider(),

            // Start Date/Time
            _buildDateTimePicker(
              label: 'Start',
              date: _startDate,
              time: _startTime,
              onDateChanged: (date) {
                setState(() {
                  _startDate = date;
                  // Ensure end is after start
                  if (_endDate.isBefore(_startDate)) {
                    _endDate = _startDate.add(const Duration(hours: 1));
                  }
                });
              },
              onTimeChanged: (time) {
                setState(() {
                  _startTime = time;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // End Date/Time
            _buildDateTimePicker(
              label: 'End',
              date: _endDate,
              time: _endTime,
              onDateChanged: (date) {
                setState(() {
                  _endDate = date;
                });
              },
              onTimeChanged: (time) {
                setState(() {
                  _endTime = time;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required Function(DateTime) onDateChanged,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () async {
              final newDate = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (newDate != null) {
                onDateChanged(newDate);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(DateFormat('MMM d, y').format(date)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (!_allDay)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final newTime = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (newTime != null) {
                  onTimeChanged(newTime);
                }
              },
              icon: const Icon(Icons.access_time),
              label: Text(time.format(context)),
            ),
          ),
      ],
    );
  }

  Widget _buildAdditionalOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Options',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Features',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),

            // Reminders
            _buildRemindersSection(),
            const SizedBox(height: AppSpacing.md),

            // Attendees
            _buildAttendeesSection(),
            const SizedBox(height: AppSpacing.md),

            // Recurrence
            _buildRecurrenceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reminders', style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              onPressed: _addReminder,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_reminders.isEmpty)
          const Text('No reminders set')
        else
          ...(_reminders.asMap().entries.map((entry) {
            final index = entry.key;
            final reminder = entry.value;
            return ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(reminder.description),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _reminders.removeAt(index);
                  });
                },
              ),
              contentPadding: EdgeInsets.zero,
            );
          })),
      ],
    );
  }

  Widget _buildAttendeesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Attendees', style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              onPressed: _addAttendee,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        if (_attendees.isEmpty)
          const Text('No attendees added')
        else
          ...(_attendees.asMap().entries.map((entry) {
            final index = entry.key;
            final attendee = entry.value;
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  (attendee.name?.isNotEmpty == true
                          ? attendee.name![0]
                          : attendee.email[0])
                      .toUpperCase(),
                ),
              ),
              title: Text(attendee.name ?? attendee.email),
              subtitle: Text(attendee.email),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _attendees.removeAt(index);
                  });
                },
              ),
              contentPadding: EdgeInsets.zero,
            );
          })),
      ],
    );
  }

  Widget _buildRecurrenceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Repeat', style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              onPressed: _setRecurrence,
              icon: Icon(_recurrenceRule == null ? Icons.add : Icons.edit),
              label: Text(_recurrenceRule == null ? 'Add' : 'Edit'),
            ),
          ],
        ),
        Text(_recurrenceRule?.toString() ?? 'Does not repeat'),
        if (_recurrenceRule != null)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _recurrenceRule = null;
              });
            },
            icon: const Icon(Icons.delete),
            label: const Text('Remove'),
          ),
      ],
    );
  }

  void _addReminder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('At event time'),
              onTap: () {
                setState(() {
                  _reminders.add(Reminder.atEventTime());
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('5 minutes before'),
              onTap: () {
                setState(() {
                  _reminders.add(Reminder.fiveMinutesBefore());
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('15 minutes before'),
              onTap: () {
                setState(() {
                  _reminders.add(Reminder.fifteenMinutesBefore());
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('30 minutes before'),
              onTap: () {
                setState(() {
                  _reminders.add(Reminder.thirtyMinutesBefore());
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('1 hour before'),
              onTap: () {
                setState(() {
                  _reminders.add(Reminder.oneHourBefore());
                });
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('1 day before'),
              onTap: () {
                setState(() {
                  _reminders.add(Reminder.oneDayBefore());
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addAttendee() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Attendee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'attendee@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
                hintText: 'John Doe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                setState(() {
                  _attendees.add(
                    Attendee(
                      email: emailController.text,
                      name: nameController.text.isNotEmpty
                          ? nameController.text
                          : null,
                    ),
                  );
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _setRecurrence() {
    showDialog(
      context: context,
      builder: (context) => RecurrenceRulePicker(
        initialRule: _recurrenceRule,
        onRuleChanged: (rule) {
          setState(() {
            _recurrenceRule = rule;
          });
        },
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCalendarId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a calendar')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final api = ref.read(calendarBridgeProvider);

      // Combine date and time
      final startDateTime = _allDay
          ? DateTime(_startDate.year, _startDate.month, _startDate.day)
          : DateTime(
              _startDate.year,
              _startDate.month,
              _startDate.day,
              _startTime.hour,
              _startTime.minute,
            );

      final endDateTime = _allDay
          ? DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59)
          : DateTime(
              _endDate.year,
              _endDate.month,
              _endDate.day,
              _endTime.hour,
              _endTime.minute,
            );

      final event = CalendarEvent(
        eventId: widget.event?.eventId,
        calendarId: _selectedCalendarId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        url: _urlController.text.trim().isNotEmpty
            ? _urlController.text.trim()
            : null,
        start: TZDateTime.from(startDateTime, UTC),
        end: TZDateTime.from(endDateTime, UTC),
        allDay: _allDay,
        attendees: _attendees,
        reminders: _reminders,
        recurrenceRule: _recurrenceRule,
      );

      if (widget.event == null) {
        // Create new event
        await api.createEvent(event);
      } else {
        // Update existing event
        await api.updateEvent(event);
      }

      // Invalidate providers to refresh data
      ref.invalidate(eventsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event == null
                  ? 'Event created successfully!'
                  : 'Event updated successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save event: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
