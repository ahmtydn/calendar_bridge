import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/navigation_tab.dart';
import 'calendar_list_screen.dart';
import 'calendar_view_screen.dart';
import 'event_list_screen.dart';
import 'settings_screen.dart';

class CalendarHomeScreen extends ConsumerStatefulWidget {
  const CalendarHomeScreen({super.key});

  @override
  ConsumerState<CalendarHomeScreen> createState() => _CalendarHomeScreenState();
}

class _CalendarHomeScreenState extends ConsumerState<CalendarHomeScreen> {
  int _selectedIndex = 0;

  final List<NavigationTab> _tabs = [
    NavigationTab(
      icon: Icons.view_agenda_outlined,
      selectedIcon: Icons.view_agenda,
      label: 'Events',
    ),
    NavigationTab(
      icon: Icons.calendar_view_month_outlined,
      selectedIcon: Icons.calendar_view_month,
      label: 'Calendar',
    ),
    NavigationTab(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      label: 'Calendars',
    ),
    NavigationTab(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          EventListScreen(),
          CalendarViewScreen(),
          CalendarListScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
