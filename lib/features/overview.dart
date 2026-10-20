import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/workspace_ui.dart';
import '../widgets/room_art.dart';
import '../widgets/record_form.dart';
import 'bookings/booking_detail.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onBookings});
  final VoidCallback onBookings;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Json data = {};
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await AppScope.of(context).api.get('dashboard');
      if (mounted) setState(() => data = object(result['data']));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final colors = Theme.of(context).colorScheme;
    return LoadView(
      loading: loading,
      error: error,
      retry: load,
      child: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            WorkspaceHeading(
              s.label(
                'A clear view of every stay',
                'প্রতিটি থাকার তথ্য এক নজরে',
              ),
              'Welcome, ${text(s.user?['name'])}. Your rest-house workspace for today.',
              icon: Icons.space_dashboard_outlined,
              action: FilledButton.icon(
                onPressed: widget.onBookings,
                icon: const Icon(Icons.add),
                label: const Text('Manage bookings'),
              ),
            ),
            LayoutBuilder(
              builder: (context, c) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                final columns = c.maxWidth > 1000
                    ? 4
                    : c.maxWidth >= 280 && !largeText
                    ? 2
                    : 1;
                final metrics = [
                  (
                    'Total rooms',
                    '${number(data['rooms'])}',
                    Icons.meeting_room_outlined,
                    colors.primary,
                  ),
                  (
                    'Awaiting approval',
                    '${number(data['pending'])}',
                    Icons.pending_actions,
                    const Color(0xffa87824),
                  ),
                  (
                    'Occupied stays',
                    '${number(data['occupied'])}',
                    Icons.hotel_outlined,
                    colors.tertiary,
                  ),
                  (
                    'Today’s collections',
                    money(data['collections_minor']),
                    Icons.account_balance_wallet_outlined,
                    colors.primary,
                  ),
                ];
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics
                      .map(
                        (item) => SizedBox(
                          width: (c.maxWidth - (columns - 1) * 12) / columns,
                          child: MetricTile(
                            label: item.$1,
                            value: item.$2,
                            icon: item.$3,
                            accent: item.$4,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 22),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Today at the bungalow',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  RecordMeta(
                    Icons.login_rounded,
                    '${number(data['arrivals'])} arrivals expected',
                  ),
                  RecordMeta(
                    Icons.logout_rounded,
                    '${number(data['departures'])} departures expected',
                  ),
                  RecordMeta(
                    Icons.check_circle_outline,
                    '${number(data['bookable_rooms'])} rooms enabled for booking',
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Outstanding balance',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    money(data['receivables_minor']),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                  if (data['tariff_ready'] != true) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Tariff policy needs admin approval before bookings can be confirmed.',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule, size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Booking times use Asia/Dhaka. Payment balances and room readiness are updated by the server.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  DateTime start = DateTime(
    dhakaNow().year,
    dhakaNow().month,
    dhakaNow().day,
    14,
  );
  late DateTime end = start.add(const Duration(days: 1)).copyWith(hour: 12);
  List<Json> rooms = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await AppScope.of(context).api.get(
        'availability',
        query: {
          'check_in_at': dhakaInput(start),
          'check_out_at': dhakaInput(end),
        },
      );
      if (mounted) setState(() => rooms = rows(r['data']));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> range() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: start, end: end),
    );
    if (r != null) {
      start = r.start.copyWith(hour: 14);
      end = r.end.copyWith(hour: 12);
      await load();
    }
  }

  Future<void> edit(Json room) async {
    final s = AppScope.of(context);
    final saved = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: 'Room ${room['code']}',
        initial: {
          ...room,
          'bookable': '${room['bookable'] == true || room['bookable'] == 1}',
        },
        fields: const [
          FormFieldSpec('name', 'Room name', required: true),
          FormFieldSpec(
            'capacity',
            'Verified capacity',
            numeric: true,
            required: true,
          ),
          FormFieldSpec(
            'bookable',
            'Allow bookings',
            required: true,
            options: {'true': 'Yes', 'false': 'No'},
          ),
          FormFieldSpec(
            'housekeeping',
            'Housekeeping',
            required: true,
            options: {
              'ready': 'Ready',
              'needs_cleaning': 'Needs cleaning',
              'cleaning': 'Cleaning',
              'unverified': 'Unverified',
            },
          ),
        ],
        save: (v) async {
          v['bookable'] = v['bookable'] == 'true';
          await s.api.send('PATCH', 'rooms/${room['id']}', v);
        },
      ),
    );
    if (saved == true) await load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        WorkspaceHeading(
          s.label('Rooms', 'কক্ষসমূহ'),
          'Date-specific availability. A confirmed allocation cannot be selected.',
          icon: Icons.meeting_room_outlined,
          action: OutlinedButton.icon(
            onPressed: range,
            icon: const Icon(Icons.date_range),
            label: Text('${dateOnly(start)} to ${dateOnly(end)}'),
          ),
        ),
        LoadView(
          loading: loading,
          error: error,
          retry: load,
          child: LayoutBuilder(
            builder: (context, c) {
              final columns = c.maxWidth > 1000
                  ? 3
                  : c.maxWidth > 580
                  ? 2
                  : 1;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: rooms.map((entry) {
                  final r = object(entry['room']).isNotEmpty
                      ? object(entry['room'])
                      : entry;
                  final available = entry['available'] == true;
                  return SizedBox(
                    width: (c.maxWidth - (columns - 1) * 16) / columns,
                    child: RoomRecordView(
                      room: r,
                      available: available,
                      onEdit: s.admin ? () => edit(r) : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime start = DateTime(dhakaNow().year, dhakaNow().month, dhakaNow().day);
  Json data = {};
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final s = AppScope.of(context);
      await s.loadCatalog();
      final r = await s.api.get(
        'calendar',
        query: {
          'start': dateOnly(start),
          'end': dateOnly(start.add(const Duration(days: 7))),
        },
      );
      if (mounted) setState(() => data = object(r['data']));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  ({Json entry, Json booking}) calendarCell(
    Json room,
    DateTime day,
    List<Json> entries,
    List<Json> bookings,
  ) {
    final date = dateOnly(day);
    bool covers(Json record, String from, String to) {
      final first = text(record[from]);
      final last = text(record[to]);
      return first.length >= 10 &&
          last.length >= 10 &&
          first.substring(0, 10).compareTo(date) <= 0 &&
          last.substring(0, 10).compareTo(date) > 0;
    }

    final entry = entries.firstWhere(
      (entry) =>
          entry['room_id'] == room['id'] &&
          covers(entry, 'starts_at', 'ends_at'),
      orElse: () => <String, dynamic>{},
    );
    final booking = entry.isNotEmpty
        ? bookings.firstWhere(
            (booking) => booking['id'] == entry['booking_id'],
            orElse: () => <String, dynamic>{},
          )
        : bookings.firstWhere(
            (booking) =>
                booking['status'] == 'pending_approval' &&
                rows(booking['rooms'])
                    .any((item) => item['id'] == room['id']) &&
                covers(booking, 'check_in_at', 'check_out_at'),
            orElse: () => <String, dynamic>{},
          );
    return (entry: entry, booking: booking);
  }

  void openBooking(Json booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(id: number(booking['id'])),
      ),
    );
  }

  ({Color color, IconData icon, String label}) cellStyle(
    Json entry,
    Json booking,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (booking.isNotEmpty) {
      if (booking['status'] == 'pending_approval') {
        return (
          color: dark ? const Color(0xffffd27b) : const Color(0xff936000),
          icon: Icons.schedule_rounded,
          label: 'Pending',
        );
      }
      return (
        color: dark ? const Color(0xff86daca) : const Color(0xff126b61),
        icon: Icons.bed_outlined,
        label: 'Booked',
      );
    }
    if (entry.isNotEmpty) {
      return (
        color: dark ? const Color(0xffffb5aa) : const Color(0xffb44d40),
        icon: Icons.block_rounded,
        label: 'Blocked',
      );
    }
    return (
      color: dark ? const Color(0xffa5c5b5) : const Color(0xff617d70),
      icon: Icons.check_rounded,
      label: 'Available',
    );
  }

  Future<void> showCalendarDay(
    Json room,
    DateTime day,
    Json entry,
    Json booking,
  ) async {
    final style = cellStyle(entry, booking);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Room ${room['code']} · ${room['name']}',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(DateFormat('EEEE, d MMMM yyyy').format(day)),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(style.icon, color: style.color),
                const SizedBox(width: 8),
                Text(
                  style.label,
                  style: TextStyle(
                    color: style.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (booking.isNotEmpty) ...[
              Text(
                text(object(booking['guest_snapshot'])['name']),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              Text(text(booking['number'])),
              const SizedBox(height: 8),
              Text('Status: ${human(booking['status'])}'),
              Text('Check-in: ${timestamp(booking['check_in_at'])}'),
              Text('Check-out: ${timestamp(booking['check_out_at'])}'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  openBooking(booking);
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('View booking'),
              ),
            ] else if (entry.isNotEmpty) ...[
              Text('Room block: ${human(entry['kind'])}'),
              if (text(entry['reason']).isNotEmpty) Text(text(entry['reason'])),
            ] else
              const Text(
                'No booking or block on this day. Check availability for the full stay before allocating a room.',
              ),
          ],
        ),
      ),
    );
  }

  Widget mobileWeekCalendar(
    List<Json> rooms,
    List<Json> entries,
    List<Json> bookings,
  ) {
    final colors = Theme.of(context).colorScheme;
    final today = dateOnly(dhakaNow());
    final scaler = MediaQuery.textScalerOf(context);
    final rowHeight = 20 + scaler.scale(13) * 1.5 + scaler.scale(10) * 3;
    final roomWidth = MediaQuery.sizeOf(context).width < 360 ? 72.0 : 84.0;
    return Column(
      key: const ValueKey('mobile-week-calendar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            for (final item in [
              cellStyle({}, {}),
              cellStyle({}, {'status': 'confirmed'}),
              cellStyle({}, {'status': 'pending_approval'}),
              cellStyle({'kind': 'maintenance'}, {}),
            ])
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 14, color: item.color),
                  const SizedBox(width: 4),
                  Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: roomWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          'ROOM',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    ...List.generate(7, (index) {
                      final day = start.add(Duration(days: index));
                      final isToday = dateOnly(day) == today;
                      return Expanded(
                        child: Tooltip(
                          message: DateFormat('EEEE, d MMMM').format(day),
                          child: Container(
                            key: ValueKey('week-date-$index'),
                            height: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isToday ? colors.primaryContainer : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('EEE').format(day),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isToday
                                          ? colors.onPrimaryContainer
                                          : colors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 6),
                if (rooms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No rooms are configured.'),
                  ),
                ...rooms.map(
                  (room) => Row(
                    children: [
                      SizedBox(
                        width: roomWidth,
                        height: rowHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: Tooltip(
                            message: '${room['code']} · ${room['name']}',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  text(room['code']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  text(room['name']),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ...List.generate(7, (index) {
                        final day = start.add(Duration(days: index));
                        final cell = calendarCell(room, day, entries, bookings);
                        final style = cellStyle(cell.entry, cell.booking);
                        final occupied =
                            cell.entry.isNotEmpty || cell.booking.isNotEmpty;
                        return Expanded(
                          child: SizedBox(
                            height: rowHeight,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                                vertical: 4,
                              ),
                              child: Semantics(
                                label:
                                    'Room ${room['code']}, ${DateFormat('EEEE d MMMM').format(day)}, ${style.label}',
                                button: true,
                                child: Tooltip(
                                  message: '${style.label} · tap for details',
                                  child: Material(
                                    color: style.color.withValues(
                                      alpha: occupied ? .2 : .045,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(7),
                                      side: BorderSide(
                                        color: style.color.withValues(
                                          alpha: occupied ? .38 : .15,
                                        ),
                                      ),
                                    ),
                                    child: InkWell(
                                      key: ValueKey(
                                        'week-cell-${room['id']}-$index',
                                      ),
                                      borderRadius: BorderRadius.circular(7),
                                      onTap: () => showCalendarDay(
                                        room,
                                        day,
                                        cell.entry,
                                        cell.booking,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          style.icon,
                                          size: occupied ? 17 : 13,
                                          color: style.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tap any day cell for guest and booking details.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget weekControls() => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      IconButton(
        tooltip: 'Previous week',
        onPressed: () {
          start = start.subtract(const Duration(days: 7));
          load();
        },
        icon: const Icon(Icons.chevron_left),
      ),
      TextButton(
        onPressed: () async {
          final day = await showDatePicker(
            context: context,
            initialDate: start,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (day != null) {
            start = day;
            load();
          }
        },
        child: Text(
          '${DateFormat('d MMM').format(start)} – ${DateFormat('d MMM yyyy').format(start.add(const Duration(days: 6)))}',
        ),
      ),
      IconButton(
        tooltip: 'Next week',
        onPressed: () {
          start = start.add(const Duration(days: 7));
          load();
        },
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );

  Widget weeklyTable(
    List<Json> rooms,
    List<Json> entries,
    List<Json> bookings,
  ) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Table(
      defaultColumnWidth: const FixedColumnWidth(142),
      border: TableBorder.all(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      children: [
        TableRow(
          children: [
            const Padding(padding: EdgeInsets.all(12), child: Text('Room')),
            ...List.generate(
              7,
              (i) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  dateOnly(start.add(Duration(days: i))),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        ...rooms.map(
          (room) => TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text('${room['code']}\n${room['name']}'),
              ),
              ...List.generate(7, (i) {
                final cell = calendarCell(
                  room,
                  start.add(Duration(days: i)),
                  entries,
                  bookings,
                );
                final match = cell.entry;
                final b = cell.booking;
                final blocked = match.isNotEmpty || b.isNotEmpty;
                return SizedBox(
                  height: 94,
                  child: Material(
                    color: blocked
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                    child: InkWell(
                      onTap: b.isEmpty
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingDetailScreen(id: number(b['id'])),
                              ),
                            ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          b.isNotEmpty
                              ? '${text(object(b['guest_snapshot'])['name'])}\n${human(b['status'])}'
                              : blocked
                              ? human(match['kind'])
                              : 'Available',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final rooms = rows(session.catalog['rooms']);
    final entries = rows(data['entries']), bookings = rows(data['bookings']);
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        return ListView(
          padding: EdgeInsets.all(mobile ? 12 : 24),
          children: [
            if (mobile) ...[
              Text(
                session.label('Booking calendar', 'বুকিং ক্যালেন্ডার'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text('Your rooms. The whole week. At a glance.'),
              const SizedBox(height: 8),
              weekControls(),
              const SizedBox(height: 12),
            ] else
              PageHeading(
                session.label('Booking calendar', 'বুকিং ক্যালেন্ডার'),
                'A seven-day room view. Scroll across to see more dates.',
                action: weekControls(),
              ),
            LoadView(
              loading: loading,
              error: error,
              retry: load,
              child: mobile
                  ? mobileWeekCalendar(rooms, entries, bookings)
                  : weeklyTable(rooms, entries, bookings),
            ),
          ],
        );
      },
    );
  }
}
