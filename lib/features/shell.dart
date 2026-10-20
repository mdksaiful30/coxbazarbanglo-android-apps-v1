import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/api.dart';
import '../widgets/brand_logo.dart';
import 'overview.dart';
import 'bookings/booking_list.dart';
import 'directory.dart';
import 'account.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String page = 'Dashboard';
  static const destinations = <String, IconData>{
    'Dashboard': Icons.space_dashboard_outlined,
    'Calendar': Icons.calendar_month_outlined,
    'Bookings': Icons.hotel_outlined,
    'Rooms': Icons.meeting_room_outlined,
    'Guests': Icons.people_outline,
    'Tariffs': Icons.price_change_outlined,
    'Reservations': Icons.event_available_outlined,
    'Reports': Icons.assessment_outlined,
    'Staff': Icons.badge_outlined,
    'Notifications': Icons.notifications_outlined,
    'Audit trail': Icons.history,
    'Account': Icons.manage_accounts_outlined,
  };
  static const bangla = {
    'Dashboard': 'ড্যাশবোর্ড',
    'Calendar': 'ক্যালেন্ডার',
    'Bookings': 'বুকিং',
    'Rooms': 'কক্ষসমূহ',
    'Guests': 'অতিথি',
    'Tariffs': 'ভাড়ার তালিকা',
    'Reservations': 'সংরক্ষণ',
    'Reports': 'প্রতিবেদন',
    'Staff': 'কর্মী',
    'Notifications': 'বার্তা',
    'Audit trail': 'কার্যক্রমের ইতিহাস',
    'Account': 'অ্যাকাউন্ট',
  };
  void select(String value) => setState(() => page = value);
  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final names = destinations.keys
        .where(
          (n) =>
              session.admin ||
              [
                'Dashboard',
                'Calendar',
                'Bookings',
                'Rooms',
                'Guests',
                'Account',
              ].contains(n),
        )
        .toList();
    if (!names.contains(page)) page = 'Dashboard';
    String name(String n) => session.language == 'bn' ? bangla[n]! : n;
    Widget navigation(bool expanded, {bool drawer = false}) => SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(expanded ? 24 : 12),
            child: BrandLogo(compact: !expanded),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: names
                  .map(
                    (n) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      child: expanded
                          ? ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              selected: page == n,
                              selectedTileColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              leading: Icon(destinations[n]),
                              title: Text(name(n)),
                              onTap: () {
                                select(n);
                                if (drawer) Navigator.pop(context);
                              },
                            )
                          : IconButton.filledTonal(
                              isSelected: page == n,
                              tooltip: name(n),
                              onPressed: () => select(n),
                              icon: Icon(destinations[n]),
                            ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                text(session.user?['name']),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
    final body = switch (page) {
      'Dashboard' => DashboardScreen(onBookings: () => select('Bookings')),
      'Calendar' => const CalendarScreen(),
      'Bookings' => const BookingListScreen(),
      'Rooms' => const RoomsScreen(),
      'Guests' => const DirectoryScreen(kind: 'Guests'),
      'Account' => const AccountScreen(),
      _ => DirectoryScreen(kind: page),
    };
    return LayoutBuilder(
      builder: (context, c) {
        final mobile = c.maxWidth < 700, expanded = c.maxWidth >= 1200;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (mobile) ...[
                  const BrandLogo(compact: true, width: 28),
                  const SizedBox(width: 10),
                ],
                Flexible(child: Text(name(page))),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Account',
                onPressed: () => select('Account'),
                icon: const Icon(Icons.account_circle_outlined),
              ),
              const SizedBox(width: 12),
            ],
          ),
          drawer: mobile ? Drawer(child: navigation(true, drawer: true)) : null,
          bottomNavigationBar: mobile
              ? NavigationBar(
                  selectedIndex:
                      [
                        'Dashboard',
                        'Calendar',
                        'Bookings',
                        'Rooms',
                      ].contains(page)
                      ? [
                          'Dashboard',
                          'Calendar',
                          'Bookings',
                          'Rooms',
                        ].indexOf(page)
                      : 0,
                  onDestinationSelected: (i) =>
                      select(['Dashboard', 'Calendar', 'Bookings', 'Rooms'][i]),
                  destinations: ['Dashboard', 'Calendar', 'Bookings', 'Rooms']
                      .map(
                        (n) => NavigationDestination(
                          icon: Icon(destinations[n]),
                          label: name(n),
                        ),
                      )
                      .toList(),
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!mobile)
                  SizedBox(
                    width: expanded ? 240 : 80,
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: navigation(expanded),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: KeyedSubtree(key: ValueKey(page), child: body),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Text(
                          "Developed by Zaman's Dev",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
