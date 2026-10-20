import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';
import '../widgets/workspace_ui.dart';
import '../widgets/record_form.dart';
import 'bookings/booking_detail.dart';
import 'reservation_editor.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key, required this.kind});
  final String kind;
  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  List<Json> records = [];
  Json report = {};
  bool loading = true, busy = false, next = false;
  String? error;
  int page = 1;
  final search = TextEditingController();
  DateTime start = DateTime(dhakaNow().year, dhakaNow().month, 1);
  late DateTime end = start.add(const Duration(days: 30));
  String get path => switch (widget.kind) {
    'Guests' => 'guests',
    'Tariffs' => 'tariffs',
    'Reservations' => 'room-blocks',
    'Reports' => 'reports',
    'Staff' => 'users',
    'Notifications' => 'notifications',
    _ => 'audit-logs',
  };
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load({bool more = false}) async {
    setState(() {
      if (!more) {
        loading = true;
        page = 1;
      } else {
        busy = true;
      }
      error = null;
    });
    try {
      final r = await AppScope.of(context).api.get(
        path,
        query: {
          'page': more ? page + 1 : 1,
          if (widget.kind == 'Guests') 'search': search.text,
          if (widget.kind == 'Reports') ...{
            'start': dateOnly(start),
            'end': dateOnly(end),
          },
        },
      );
      final result = widget.kind == 'Reports'
          ? rows(object(r['data'])['bookings'])
          : rows(r['data']);
      if (mounted) {
        setState(() {
          records = more ? [...records, ...result] : result;
          report = widget.kind == 'Reports' ? object(r['data']) : {};
          next = r['next_page_url'] != null;
          if (more) page++;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          busy = false;
        });
      }
    }
  }

  Future<void> editor({Json? initial}) async {
    final s = AppScope.of(context);
    if (widget.kind == 'Reservations') {
      final saved = await adaptiveDialog<bool>(
        context,
        const ReservationEditor(),
      );
      if (saved == true) {
        await load();
      }
      return;
    }
    List<FormFieldSpec> fields = [];
    Json values = initial ?? {};
    String route = path;
    String method = initial == null ? 'POST' : 'PUT';
    String? message;
    switch (widget.kind) {
      case 'Guests':
        fields = guestFields;
        if (initial != null) route = '$path/${initial['id']}';
      case 'Staff':
        fields = [
          const FormFieldSpec('name', 'Name', required: true),
          const FormFieldSpec('email', 'Email', required: true),
          const FormFieldSpec(
            'role',
            'Role',
            required: true,
            options: {'admin': 'Administrator', 'staff_admin': 'Staff admin'},
          ),
          const FormFieldSpec(
            'active',
            'Account enabled',
            required: true,
            options: {'true': 'Enabled', 'false': 'Disabled'},
          ),
          FormFieldSpec(
            'password',
            initial == null
                ? 'Password (minimum 12 characters)'
                : 'New password (leave blank to keep)',
            required: initial == null,
            secret: true,
          ),
        ];
        values = {...values, 'active': '${values['active'] ?? true}'};
        if (initial != null) route = '$path/${initial['id']}';
      default:
        return;
    }
    if (!mounted) return;
    final ok = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: initial == null
            ? 'New ${widget.kind.toLowerCase()}'
            : 'Edit ${widget.kind.toLowerCase()}',
        fields: fields,
        initial: values,
        message: message,
        save: (v) async {
          if (widget.kind == 'Staff') v['active'] = v['active'] == 'true';
          if (widget.kind == 'Reservations') {
            final ids = text(
              v['room_ids'],
              '',
            ).split(',').map((x) => int.tryParse(x.trim())).toList();
            if (ids.isEmpty || ids.contains(null)) {
              throw const ApiFailure(
                'Enter valid room IDs separated by commas.',
              );
            }
            v['room_ids'] = ids;
          }
          await s.api.send(method, route, v);
        },
      ),
    );
    if (ok == true) await load();
  }

  Future<void> release(Json record) async {
    final api = AppScope.of(context).api;
    final ok = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: 'Release reservation',
        fields: const [reasonField],
        save: (v) async {
          await api.send('POST', 'room-blocks/${record['id']}/release', v);
        },
      ),
    );
    if (ok == true) await load();
  }

  Future<void> tariff(Json t) async {
    await adaptiveDialog(context, _TariffPanel(tariff: t));
    await load();
  }

  Future<void> export() async {
    setState(() => busy = true);
    try {
      final api = AppScope.of(context).api;
      final path = Uri(
        path: 'reports/export',
        queryParameters: {'start': dateOnly(start), 'end': dateOnly(end)},
      ).toString();
      final bytes = await api.download(path);
      await FilePicker.saveFile(
        fileName: 'rest-house-${dateOnly(start)}.csv',
        bytes: bytes,
      );
    } catch (e) {
      if (mounted) notice(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> dates() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: start, end: end),
    );
    if (r != null) {
      start = r.start;
      end = r.end;
      load();
    }
  }

  String roomName(dynamic id) {
    final r = rows(AppScope.of(context).catalog['rooms'])
        .firstWhere((r) => r['id'] == id, orElse: () => {});
    return r.isEmpty ? 'Room' : '${r['code']} — ${r['name']}';
  }

  String title(Json r) => switch (widget.kind) {
    'Guests' => text(r['name']),
    'Tariffs' => text(r['name']),
    'Reservations' => '${human(r['kind'])} #${r['id']}',
    'Staff' => text(r['name']),
    'Notifications' => '${human(r['channel'])} · Booking ${r['booking_id']}',
    'Reports' => text(r['number']),
    _ => human(r['action']),
  };
  String subtitle(Json r) => switch (widget.kind) {
    'Guests' => '${text(r['mobile'])} · ${text(r['designation'])}',
    'Tariffs' => '${text(r['reference'])} · ${human(r['calculation_mode'])}',
    'Reservations' => text(r['reason']),
    'Staff' => '${text(r['email'])} · ${human(r['role'])}',
    'Notifications' => text(r['last_error'], timestamp(r['created_at'])),
    'Reports' =>
      '${text(r['guest'])} · ${money(object(r['finance'])['balance_minor'])} due',
    _ =>
      '${text(r['entity_type'])} ${text(r['entity_id'])} · ${timestamp(r['created_at'])}',
  };
  Widget recordActions(Json r) {
    final s = AppScope.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (['Guests', 'Staff'].contains(widget.kind))
          OutlinedButton(
            onPressed: () => editor(initial: r),
            child: const Text('Edit'),
          ),
        if (widget.kind == 'Tariffs')
          OutlinedButton(
            onPressed: () => tariff(r),
            child: const Text('Rates & policy'),
          ),
        if (widget.kind == 'Reservations')
          ...rows(r['entries']).map(
            (e) => Text(
              '${roomName(e['room_id'])} · ${timestamp(e['starts_at'])} → ${timestamp(e['ends_at'])}',
            ),
          ),
        if (widget.kind == 'Reservations' && r['status'] == 'active')
          OutlinedButton(
            onPressed: () => release(r),
            child: const Text('Release block'),
          ),
        if (widget.kind == 'Reports')
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingDetailScreen(id: number(r['id'])),
              ),
            ),
            child: const Text('Open booking'),
          ),
        if (widget.kind == 'Notifications' &&
            r['status'] == 'failed' &&
            r['provider_id'] == null)
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    final api = s.api;
                    final ok = await adaptiveDialog<bool>(
                      context,
                      RecordForm(
                        title: 'Retry failed message',
                        fields: const [],
                        message: 'Confirm the provider has not already accepted this message.',
                        saveLabel: 'Retry',
                        save: (_) async {
                          await api.send(
                            'POST',
                            'notifications/${r['id']}/retry',
                          );
                        },
                      ),
                    );
                    if (ok == true) await load();
                  },
            child: const Text('Retry delivery'),
          ),
        if (['Audit trail', 'Notifications'].contains(widget.kind))
          TextButton(
            onPressed: () => adaptiveDialog(
              context,
              DialogFrame(
                title: 'Record details',
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(r),
                ),
              ),
            ),
            child: const Text('View details'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        WorkspaceHeading(
          s.label(
            widget.kind,
            {
                  'Guests': 'অতিথি',
                  'Tariffs': 'ভাড়ার তালিকা',
                  'Reservations': 'সংরক্ষণ',
                  'Reports': 'প্রতিবেদন',
                  'Staff': 'কর্মী',
                  'Notifications': 'বার্তা',
                  'Audit trail': 'কার্যক্রমের ইতিহাস',
                }[widget.kind] ??
                widget.kind,
          ),
          switch (widget.kind) {
            'Guests' => 'Guest contacts and stay information, in one place.',
            'Staff' => 'Your team, account access and assigned roles.',
            'Notifications' => 'Message delivery status and follow-up actions.',
            'Audit trail' => 'A clear history of changes and staff activity.',
            _ => 'Office records and operational history.',
          },
          icon: switch (widget.kind) {
            'Guests' => Icons.people_outline,
            'Staff' => Icons.badge_outlined,
            'Notifications' => Icons.notifications_outlined,
            'Audit trail' => Icons.history_rounded,
            _ => Icons.folder_outlined,
          },
          action: ['Guests', 'Staff', 'Reservations'].contains(widget.kind)
              ? FilledButton.icon(
                  onPressed: () => editor(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add new'),
                )
              : widget.kind == 'Reports'
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: dates,
                      child: Text('${dateOnly(start)} → ${dateOnly(end)}'),
                    ),
                    FilledButton.icon(
                      onPressed: busy ? null : export,
                      icon: const Icon(Icons.download),
                      label: const Text('Export CSV'),
                    ),
                  ],
                )
              : IconButton(
                  tooltip: 'Refresh',
                  onPressed: load,
                  icon: const Icon(Icons.refresh),
                ),
        ),
        if (!loading &&
            error == null &&
            const [
              'Guests',
              'Staff',
              'Notifications',
              'Audit trail',
            ].contains(widget.kind)) ...[
          WorkspaceCounts([
            ('Loaded records', '${records.length}'),
            if (widget.kind == 'Staff')
              (
                'Active on this page',
                '${records.where((r) => r['active'] == true || r['active'] == 1).length}',
              ),
            if (widget.kind == 'Notifications')
              (
                'Failed on this page',
                '${records.where((r) => r['status'] == 'failed').length}',
              ),
          ]),
          const SizedBox(height: 16),
        ],
        if (widget.kind == 'Guests') ...[
          TextField(
            controller: search,
            decoration: InputDecoration(
              labelText: 'Search guests',
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: load,
                icon: const Icon(Icons.search),
              ),
            ),
            onSubmitted: (_) => load(),
          ),
          const SizedBox(height: 20),
        ],
        if (report.isNotEmpty) ...[
          Panel(
            child: DataFields({
              'Collections': money(report['collections_minor']),
              'Refunds': money(report['refunds_minor']),
              'Net collections': money(report['net_collections_minor']),
              'Receivables': money(report['receivables_minor']),
            }),
          ),
          const SizedBox(height: 20),
        ],
        LoadView(
          loading: loading,
          error: error,
          retry: load,
          child: Column(
            children: [
              if (records.isEmpty)
                const WorkspaceEmpty(
                  message: 'No records found. New records will appear here.',
                  icon: Icons.inbox_outlined,
                ),
              ...records.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      const [
                        'Guests',
                        'Staff',
                        'Notifications',
                        'Audit trail',
                      ].contains(widget.kind)
                      ? DirectoryRecordView(
                          kind: widget.kind,
                          record: r,
                          actions: recordActions(r),
                        )
                      : Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    title(r),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                  if (r['status'] != null)
                                    StatusPill(text(r['status'])),
                                  if (widget.kind == 'Staff')
                                    StatusPill(
                                      r['active'] == true
                                          ? 'active'
                                          : 'disabled',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(subtitle(r)),
                              const SizedBox(height: 12),
                              recordActions(r),
                            ],
                          ),
                        ),
                ),
              ),
              if (next)
                OutlinedButton(
                  onPressed: busy ? null : () => load(more: true),
                  child: const Text('Load more'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TariffPanel extends StatefulWidget {
  const _TariffPanel({required this.tariff});
  final Json tariff;
  @override
  State<_TariffPanel> createState() => _TariffPanelState();
}

class _TariffPanelState extends State<_TariffPanel> {
  late Json tariff = widget.tariff;
  bool busy = false;
  String? error;
  Future<void> reload() async {
    final r = await AppScope.of(context).api.get('tariffs/${tariff['id']}');
    if (mounted) setState(() => tariff = object(r['data']));
  }

  Future<void> clone() async {
    final api = AppScope.of(context).api;
    final ok = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: 'Clone tariff for changes',
        fields: const [
          FormFieldSpec('name', 'New version name', required: true),
          FormFieldSpec(
            'reference',
            'Office authorization reference',
            required: true,
          ),
        ],
        save: (v) async {
          await api.send('POST', 'tariffs/${tariff['id']}/clone', v);
        },
      ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  Future<void> activateTariff() async {
    final api = AppScope.of(context).api;
    final ok = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: 'Approve tariff policy',
        initial: {
          'effective_from': dateOnly(dhakaNow()),
          'check_in_time': '14:00',
          'check_out_time': '12:00',
          'turnaround_minutes': 60,
          'notification_channel': 'email',
        },
        message: 'Activating makes this version immutable. Only acknowledge after the office approves the calculation policy, dates and communication channel.',
        fields: const [
          FormFieldSpec(
            'calculation_mode',
            'Pricing policy',
            required: true,
            options: {
              'progressive': 'Progressive bands',
              'whole_stay': 'Whole stay band',
            },
          ),
          FormFieldSpec(
            'effective_from',
            'Effective date YYYY-MM-DD',
            required: true,
          ),
          FormFieldSpec(
            'check_in_time',
            'Standard arrival HH:MM',
            required: true,
          ),
          FormFieldSpec(
            'check_out_time',
            'Standard departure HH:MM',
            required: true,
          ),
          FormFieldSpec(
            'turnaround_minutes',
            'Turnaround minutes',
            required: true,
            numeric: true,
          ),
          FormFieldSpec(
            'notification_channel',
            'Confirmation channel',
            required: true,
            options: {'email': 'Email', 'sms': 'SMS', 'whatsapp': 'WhatsApp'},
          ),
          FormFieldSpec(
            'policy_acknowledged',
            'Office policy authorization',
            required: true,
            options: {'true': 'I confirm this policy is authorized'},
          ),
          reasonField,
        ],
        save: (v) async {
          v['policy_acknowledged'] = v['policy_acknowledged'] == 'true';
          await api.send('POST', 'tariffs/${tariff['id']}/activate', v);
        },
      ),
    );
    if (ok == true) await reload();
  }

  Future<void> rate(Json r) async {
    final api = AppScope.of(context).api;
    final ok = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: 'Edit rate',
        initial: {
          'amount': (number(r['amount_minor']) / 100).toStringAsFixed(2),
        },
        fields: const [
          FormFieldSpec('amount', 'VAT-inclusive amount (BDT)', required: true),
        ],
        save: (v) async {
          v['amount_minor'] = moneyInput(v.remove('amount'));
          await api.send(
            'PATCH',
            'tariffs/${tariff['id']}/rates/${r['id']}',
            v,
          );
        },
      ),
    );
    if (ok == true) await reload();
  }

  @override
  Widget build(BuildContext context) => DialogFrame(
    title: text(tariff['name']),
    actions: [
      OutlinedButton(onPressed: clone, child: const Text('Clone version')),
      if (tariff['approved_at'] == null)
        FilledButton(
          onPressed: activateTariff,
          child: const Text('Approve & activate'),
        ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataFields({
          'Reference': tariff['reference'],
          'Policy': tariff['calculation_mode'],
          'Effective from': tariff['effective_from'],
          'Approved at': tariff['approved_at'],
        }),
        const SizedBox(height: 20),
        ...rows(tariff['rates']).map(
          (r) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${human(r['ac_type'])} · Category ${r['guest_category_id']} · Nights ${text(r['min_nights'])}–${text(r['max_nights'], '∞')}',
            ),
            subtitle: Text(money(r['amount_minor'])),
            trailing: tariff['approved_at'] == null
                ? IconButton(
                    tooltip: 'Edit rate',
                    onPressed: () => rate(r),
                    icon: const Icon(Icons.edit_outlined),
                  )
                : null,
          ),
        ),
      ],
    ),
  );
}
