import 'package:calendar_bridge/calendar_bridge.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class RecurrenceRulePicker extends StatefulWidget {
  final RecurrenceRule? initialRule;
  final Function(RecurrenceRule?) onRuleChanged;

  const RecurrenceRulePicker({
    super.key,
    this.initialRule,
    required this.onRuleChanged,
  });

  @override
  State<RecurrenceRulePicker> createState() => _RecurrenceRulePickerState();
}

class _RecurrenceRulePickerState extends State<RecurrenceRulePicker> {
  Frequency _frequency = Frequency.daily;
  int _interval = 1;
  int? _count;
  DateTime? _until;
  final Set<int> _byWeekDay = {};
  final Set<int> _byMonthDay = {};
  final Set<int> _byMonth = {};
  String _endCondition = 'never';

  @override
  void initState() {
    super.initState();
    _initializeFromRule();
  }

  void _initializeFromRule() {
    if (widget.initialRule != null) {
      final rule = widget.initialRule!;
      _frequency = rule.frequency;
      _interval = rule.interval ?? 1;
      _count = rule.count;
      _until = rule.until;

      _endCondition = _count != null
          ? 'count'
          : (_until != null ? 'until' : 'never');

      // Initialize byWeekDay, byMonthDay, byMonth from the rule
      // This is simplified - the actual rrule package might have different structure
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Repeat Event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frequency selection
            _buildFrequencySection(),
            const SizedBox(height: AppSpacing.md),

            // Interval
            _buildIntervalSection(),
            const SizedBox(height: AppSpacing.md),

            // Additional options based on frequency
            if (_frequency == Frequency.weekly) ...[
              _buildWeeklyOptions(),
              const SizedBox(height: AppSpacing.md),
            ],

            if (_frequency == Frequency.monthly) ...[
              _buildMonthlyOptions(),
              const SizedBox(height: AppSpacing.md),
            ],

            // End condition
            _buildEndConditionSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onRuleChanged(null);
            Navigator.of(context).pop();
          },
          child: const Text('Remove'),
        ),
        FilledButton(
          onPressed: () {
            final rule = _buildRecurrenceRule();
            widget.onRuleChanged(rule);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<Frequency>(
          initialValue: _frequency,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: Frequency.daily, child: Text('Daily')),
            DropdownMenuItem(value: Frequency.weekly, child: Text('Weekly')),
            DropdownMenuItem(value: Frequency.monthly, child: Text('Monthly')),
            DropdownMenuItem(value: Frequency.yearly, child: Text('Yearly')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _frequency = value;
                // Reset frequency-specific options
                _byWeekDay.clear();
                _byMonthDay.clear();
                _byMonth.clear();
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildIntervalSection() {
    String intervalLabel = _getIntervalLabel(_frequency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Every', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: _interval.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (value) {
                  final interval = int.tryParse(value);
                  if (interval != null && interval > 0) {
                    setState(() {
                      _interval = interval;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(intervalLabel),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyOptions() {
    const weekDays = [
      {'name': 'Mon', 'value': 1},
      {'name': 'Tue', 'value': 2},
      {'name': 'Wed', 'value': 3},
      {'name': 'Thu', 'value': 4},
      {'name': 'Fri', 'value': 5},
      {'name': 'Sat', 'value': 6},
      {'name': 'Sun', 'value': 0},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat on', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: weekDays.map((day) {
            final isSelected = _byWeekDay.contains(day['value']);
            return FilterChip(
              label: Text(day['name'] as String),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _byWeekDay.add(day['value'] as int);
                  } else {
                    _byWeekDay.remove(day['value']);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthlyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Repeat by', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        RadioGroup<String>(
          onChanged: (value) {
            setState(() {
              if (value == 'monthday') {
                _byMonthDay.add(DateTime.now().day);
                _byWeekDay.clear();
              } else if (value == 'weekday') {
                _byWeekDay.add(DateTime.now().weekday % 7);
                _byMonthDay.clear();
              }
            });
          },
          child: Column(
            children: [
              ListTile(
                leading: Radio<String>(value: 'monthday'),
                title: const Text('Day of month'),
                subtitle: const Text('Same date each month'),
                onTap: () {
                  setState(() {
                    _byMonthDay.add(DateTime.now().day);
                    _byWeekDay.clear();
                  });
                },
              ),
              ListTile(
                leading: Radio<String>(value: 'weekday'),
                title: const Text('Day of week'),
                subtitle: const Text('Same weekday each month'),
                onTap: () {
                  setState(() {
                    _byWeekDay.add(DateTime.now().weekday % 7);
                    _byMonthDay.clear();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEndConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('End', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        RadioGroup<String>(
          onChanged: (value) {
            setState(() {
              _endCondition = value!;
              if (value == 'never') {
                _count = null;
                _until = null;
              } else if (value == 'count') {
                _count = 10;
                _until = null;
              } else if (value == 'until') {
                _until = DateTime.now().add(const Duration(days: 30));
                _count = null;
              }
            });
          },
          child: Column(
            children: [
              ListTile(
                leading: Radio<String>(value: 'never'),
                title: const Text('Never'),
                onTap: () {
                  setState(() {
                    _endCondition = 'never';
                    _count = null;
                    _until = null;
                  });
                },
              ),
              ListTile(
                leading: Radio<String>(value: 'count'),
                title: const Text('After number of occurrences'),
                onTap: () {
                  setState(() {
                    _endCondition = 'count';
                    _count = 10;
                    _until = null;
                  });
                },
              ),
              if (_endCondition == 'count')
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: _count.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Count',
                          ),
                          onChanged: (value) {
                            final count = int.tryParse(value);
                            if (count != null && count > 0) {
                              setState(() {
                                _count = count;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text('occurrences'),
                    ],
                  ),
                ),
              ListTile(
                leading: Radio<String>(value: 'until'),
                title: const Text('On date'),
                onTap: () {
                  setState(() {
                    _endCondition = 'until';
                    _until = DateTime.now().add(const Duration(days: 30));
                    _count = null;
                  });
                },
              ),
              if (_endCondition == 'until')
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _until!,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date != null) {
                        setState(() {
                          _until = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_until!.day}/${_until!.month}/${_until!.year}',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  RecurrenceRule _buildRecurrenceRule() {
    // This is a simplified implementation
    // The actual RecurrenceRule construction might be different
    try {
      String rruleString = 'FREQ=${_getFrequencyString(_frequency)}';

      if (_interval > 1) {
        rruleString += ';INTERVAL=$_interval';
      }

      if (_byWeekDay.isNotEmpty) {
        final weekDays = _byWeekDay
            .map((day) {
              // Convert to RRULE format (MO, TU, WE, etc.)
              const dayNames = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];
              return dayNames[day];
            })
            .join(',');
        rruleString += ';BYDAY=$weekDays';
      }

      if (_byMonthDay.isNotEmpty) {
        rruleString += ';BYMONTHDAY=${_byMonthDay.join(',')}';
      }

      if (_count != null) {
        rruleString += ';COUNT=$_count';
      }

      if (_until != null) {
        final untilStr =
            '${_until!.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
        rruleString += ';UNTIL=$untilStr';
      }

      return RecurrenceRule.fromString(rruleString);
    } catch (e) {
      // Fallback to simple daily recurrence
      return RecurrenceRule.fromString('FREQ=DAILY');
    }
  }

  String _getIntervalLabel(Frequency frequency) {
    switch (frequency) {
      case Frequency.daily:
        return 'days';
      case Frequency.weekly:
        return 'weeks';
      case Frequency.monthly:
        return 'months';
      case Frequency.yearly:
        return 'years';
      default:
        return 'days';
    }
  }

  String _getFrequencyString(Frequency frequency) {
    switch (frequency) {
      case Frequency.daily:
        return 'DAILY';
      case Frequency.weekly:
        return 'WEEKLY';
      case Frequency.monthly:
        return 'MONTHLY';
      case Frequency.yearly:
        return 'YEARLY';
      default:
        return 'DAILY';
    }
  }
}
