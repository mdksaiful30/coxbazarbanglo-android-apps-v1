import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../widgets/common.dart';
import '../../widgets/record_form.dart';
import 'booking_editor.dart';
import 'booking_document.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.id});
  final int id;
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Json booking = {}, finance = {}, shareOptions = {};
  List<Json> history = [];
  bool loading = true, busy = false;
  String? error;
  Uint8List? prepared;
  String preparedFormat = 'pdf';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await AppScope.of(context).api.get('bookings/${widget.id}');
      if (mounted) {
        setState(() {
          booking = object(r['data']);
          finance = object(r['finance']);
          prepared = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> action(Future<void> Function() fn) async {
    setState(() => busy = true);
    try {
      await fn();
    } catch (e) {
      if (mounted) notice(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> transition(String actionName) async {
    final s = AppScope.of(context);
    final needs = [
      'reject',
      'return-for-correction',
      'cancel',
      'mark-no-show',
      'check-out',
    ].contains(actionName);
    final fields = <FormFieldSpec>[
      if (needs) reasonField,
      if (actionName == 'approve')
        const FormFieldSpec(
          'reservation_id',
          'Matching reservation ID (optional)',
          numeric: true,
        ),
    ];
    final result = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: human(actionName),
        fields: fields,
        message:
            'Booking ${booking['number']}. Revision ${booking['version']}. This action is validated by the server.',
        saveLabel: human(actionName),
        save: (v) async {
          await s.api.send('POST', 'bookings/${widget.id}/$actionName', {
            'version': booking['version'],
            ...v,
          });
        },
      ),
    );
    if (result == true) await load();
  }

  Future<void> edit(String mode) async {
    final r = await adaptiveDialog<int>(
      context,
      BookingEditor(booking: booking, mode: mode),
    );
    if (r != null) await load();
  }

  Future<void> financeForm(String kind, {Json? payment}) async {
    final s = AppScope.of(context);
    final paymentId = payment?['id'];
    final path = kind == 'payment'
        ? 'bookings/${widget.id}/payments'
        : kind == 'credit'
        ? 'bookings/${widget.id}/credit-notes'
        : kind == 'refund'
        ? 'payments/$paymentId/refunds'
        : 'payments/$paymentId/reverse';
    final fields = <FormFieldSpec>[
      if (kind != 'reverse')
        const FormFieldSpec(
          'amount',
          'Amount (BDT)',
          required: true,
          hint: 'For example, 1250.00',
        ),
      if (kind == 'payment') ...const [
        FormFieldSpec(
          'method',
          'Payment method',
          required: true,
          options: {
            'cash': 'Cash',
            'bank_transfer': 'Bank transfer',
            'other': 'Other',
          },
        ),
        FormFieldSpec('reference', 'Receipt/bank reference'),
      ],
      if (kind != 'payment') reasonField,
    ];
    final r = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: human(kind),
        fields: fields,
        message: 'Record verified payments only. A payment does not release the room.',
        save: (v) async {
          if (kind != 'reverse') {
            v['amount_minor'] = moneyInput(v.remove('amount'));
          }
          await s.api.send('POST', path, v);
        },
      ),
    );
    if (r == true) await load();
  }

  Future<void> document(String format) async {
    final s = AppScope.of(context);
    await action(() async {
      final response = await s.api.get(
        'bookings/${widget.id}/guest-confirmation',
      );
      final bytes = await BookingDocument.render(
        object(response['data']),
        format,
      );
      if (mounted) {
        setState(() {
          prepared = bytes;
          preparedFormat = format;
        });
        notice(
          context,
          '${format.toUpperCase()} generated. Save it or share the file below.',
        );
      }
    });
  }

  Future<void> saveDocument() async {
    if (prepared == null) return;
    await action(() async {
      final saved = await FilePicker.saveFile(
        fileName: 'Booking-${booking['number']}.$preparedFormat',
        bytes: prepared!,
        type: FileType.custom,
        allowedExtensions: [preparedFormat],
      );
      if (mounted && saved != null) {
        notice(context, '${preparedFormat.toUpperCase()} saved.');
      }
    });
  }

  Future<void> shareDocument() async {
    if (prepared == null) return;
    final box = context.findRenderObject() as RenderBox?;
    await action(() async {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              prepared!,
              mimeType: preparedFormat == 'pdf'
                  ? 'application/pdf'
                  : 'image/jpeg',
              name: 'Booking-${booking['number']}.$preparedFormat',
            ),
          ],
          fileNameOverrides: ['Booking-${booking['number']}.$preparedFormat'],
          title: 'Booking details',
          sharePositionOrigin: box == null
              ? const Rect.fromLTWH(0, 0, 1, 1)
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    });
  }

  Future<void> sharing() async {
    final api = AppScope.of(context).api;
    await action(() async {
      final options = await api.get('bookings/${widget.id}/share-options');
      final deliveries = await api.get('bookings/${widget.id}/shares');
      if (mounted) {
        setState(() {
          shareOptions = object(options['data']);
          history = rows(deliveries['data']);
        });
      }
    });
  }

  Future<void> composer(String channel) async {
    final value =
        shareOptions[channel == 'whatsapp' ? 'whatsapp_url' : 'email_url'];
    if (value == null) {
      notice(context, 'No guest contact is saved for this channel.');
      return;
    }
    final uri = Uri.parse('$value');
    if ((uri.scheme == 'https' && uri.host == 'wa.me') ||
        uri.scheme == 'mailto') {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        notice(context, 'No compatible sharing app is available.');
      }
    }
  }

  Future<void> serverShare() async {
    final api = AppScope.of(context).api;
    final ok = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: 'Send through the office server',
        initial: const {'channel': 'email', 'format': 'pdf'},
        fields: const [
          FormFieldSpec(
            'channel',
            'Channel',
            required: true,
            options: {
              'email': 'Email',
              'whatsapp': 'WhatsApp template',
              'sms': 'SMS',
            },
          ),
          FormFieldSpec(
            'format',
            'Format',
            required: true,
            options: {
              'pdf': 'PDF (email only)',
              'jpg': 'JPG (email only)',
              'text': 'Text',
            },
          ),
        ],
        message: 'Send to the guest contact saved in this booking. Requires configured providers and background workers. A queued status is not delivery confirmation.',
        saveLabel: 'Queue message',
        save: (v) async {
          await api.send('POST', 'bookings/${widget.id}/share', {
            'version': booking['version'],
            ...v,
          });
        },
      ),
    );
    if (ok == true && mounted) {
      notice(context, 'Message queued. Check delivery status below.');
      await sharing();
    }
  }

  Future<void> upload() async {
    final api = AppScope.of(context).api;
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    if ((await file.length() ?? 0) > 5 * 1024 * 1024) {
      if (mounted) notice(context, 'Maximum reference file size is 5 MB.');
      return;
    }
    await action(() async {
      await api.upload(
        'bookings/${widget.id}/attachments',
        file.name,
        await file.readAsBytes(),
      );
      await load();
    });
  }

  Future<void> downloadAttachment(Json a) async {
    final api = AppScope.of(context).api;
    await action(() async {
      final bytes = await api.download('attachments/${a['id']}/download');
      await FilePicker.saveFile(
        fileName: text(a['name'], 'reference.pdf'),
        bytes: bytes,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final status = text(booking['status']);
    final owner = s.admin || booking['created_by'] == s.user?['id'];
    final g = object(booking['guest_snapshot']);
    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(text(booking['number'], 'Booking details')),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: LoadView(
          loading: loading,
          error: error,
          retry: load,
          child: RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                PageHeading(
                  text(g['name'], 'Booking details'),
                  '${text(booking['number'])} · Revision ${text(booking['version'])}',
                  action: StatusPill(status),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (owner && ['draft', 'rejected'].contains(status))
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => edit('draft'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit draft'),
                      ),
                    if (owner && status == 'draft')
                      FilledButton(
                        onPressed: busy ? null : () => transition('submit'),
                        child: const Text('Submit for approval'),
                      ),
                    if (s.admin &&
                        (status == 'pending_approval' ||
                            (status == 'draft' &&
                                booking['created_by'] == s.user?['id'])))
                      FilledButton(
                        onPressed: busy ? null : () => transition('approve'),
                        child: const Text('Approve booking'),
                      ),
                    if (s.admin && status == 'pending_approval')
                      ...['reject', 'return-for-correction'].map(
                        (a) => OutlinedButton(
                          onPressed: busy ? null : () => transition(a),
                          child: Text(human(a)),
                        ),
                      ),
                    if (s.admin &&
                        [
                          'confirmed',
                          'checked_in',
                          'checked_out',
                        ].contains(status))
                      FilledButton.icon(
                        onPressed: busy ? null : () => edit('approved'),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Edit booking → Save changes'),
                      ),
                    if (!s.admin && owner && status == 'confirmed')
                      OutlinedButton(
                        onPressed: busy ? null : () => edit('amendment'),
                        child: const Text('Propose amendment'),
                      ),
                    if (s.admin && status == 'confirmed')
                      ...['check-in', 'mark-no-show', 'cancel'].map(
                        (a) => OutlinedButton(
                          onPressed: busy ? null : () => transition(a),
                          child: Text(human(a)),
                        ),
                      ),
                    if (s.admin && status == 'checked_in')
                      FilledButton(
                        onPressed: busy ? null : () => transition('check-out'),
                        child: const Text('Check out'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                section(
                  'Guest details',
                  DataFields({
                    'Name': g['name'],
                    'Designation': g['designation'],
                    'Organization': g['organization'],
                    'Mobile': g['mobile'],
                    'Email': g['email'],
                    'Guest count': booking['guest_count'],
                  }),
                ),
                section(
                  'Stay & room allocation',
                  DataFields({
                    'Arrival (Dhaka)': timestamp(booking['check_in_at']),
                    'Departure (Dhaka)': timestamp(booking['check_out_at']),
                    'Rooms': rows(booking['rooms'])
                        .map((r) => '${r['code']} — ${r['name']}')
                        .join('\n'),
                    'Reference letter': booking['reference_letter'],
                    'Reference date': booking['reference_date'],
                    'Purpose': booking['purpose'],
                    'Internal notes': booking['notes'],
                  }),
                ),
                section(
                  'Payment summary',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DataFields({
                        'Charges': money(finance['charges_minor']),
                        'Net paid': money(
                          number(finance['paid_minor']) -
                              number(finance['refunded_minor']),
                        ),
                        'Balance': money(finance['balance_minor']),
                        'Payment status': human(finance['payment_status']),
                      }),
                      if (s.admin) ...[
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            if ([
                              'confirmed',
                              'checked_in',
                              'checked_out',
                            ].contains(status))
                              FilledButton.icon(
                                onPressed: busy
                                    ? null
                                    : () => financeForm('payment'),
                                icon: const Icon(Icons.payments_outlined),
                                label: const Text('Record payment'),
                              ),
                            OutlinedButton(
                              onPressed: busy
                                  ? null
                                  : () => financeForm('credit'),
                              child: const Text('Issue credit note'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                section(
                  'Guest documents & sharing',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: busy ? null : () => document('pdf'),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Generate PDF'),
                          ),
                          OutlinedButton.icon(
                            onPressed: busy ? null : () => document('jpg'),
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Generate JPG'),
                          ),
                          OutlinedButton.icon(
                            onPressed: busy ? null : sharing,
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Share options'),
                          ),
                        ],
                      ),
                      if (prepared != null) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: busy ? null : saveDocument,
                              icon: const Icon(Icons.download),
                              label: Text(
                                'Save ${preparedFormat.toUpperCase()}',
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: busy ? null : shareDocument,
                              icon: const Icon(Icons.ios_share),
                              label: const Text('Share prepared file'),
                            ),
                          ],
                        ),
                      ],
                      if (shareOptions.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton(
                              onPressed: () => composer('whatsapp'),
                              child: const Text('WhatsApp text'),
                            ),
                            OutlinedButton(
                              onPressed: () => composer('email'),
                              child: const Text('Email composer'),
                            ),
                            FilledButton(
                              onPressed: busy ? null : serverShare,
                              child: const Text('Send via server'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Native file sharing opens your device’s available apps. You confirm sending in WhatsApp or email.',
                        ),
                        ...history.map(
                          (h) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${human(h['channel'])} · ${human(h['status'])}',
                            ),
                            subtitle: Text(
                              text(h['last_error'], timestamp(h['created_at'])),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                section(
                  'Reference attachments',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (owner && ['draft', 'rejected'].contains(status))
                        OutlinedButton.icon(
                          onPressed: busy ? null : upload,
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Upload reference letter'),
                        ),
                      ...rows(booking['attachments']).map(
                        (a) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(text(a['name'])),
                          trailing: IconButton(
                            tooltip: 'Download reference',
                            onPressed: busy
                                ? null
                                : () => downloadAttachment(a),
                            icon: const Icon(Icons.download),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (rows(booking['payments']).isNotEmpty)
                  section(
                    'Payments & receipts',
                    Column(
                      children: rows(booking['payments'])
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${text(p['receipt_number'])} · ${money(p['amount_minor'])} · ${human(p['status'])}',
                                  ),
                                  Text(
                                    '${human(p['method'])} · ${timestamp(p['created_at'])}',
                                  ),
                                  if (s.admin && p['status'] == 'posted')
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        TextButton(
                                          onPressed: busy
                                              ? null
                                              : () => financeForm(
                                                  'refund',
                                                  payment: p,
                                                ),
                                          child: const Text('Refund'),
                                        ),
                                        TextButton(
                                          onPressed: busy
                                              ? null
                                              : () => financeForm(
                                                  'reverse',
                                                  payment: p,
                                                ),
                                          child: const Text('Reverse'),
                                        ),
                                      ],
                                    ),
                                  ...rows(p['refunds']).map(
                                    (r) => Text(
                                      'Refund ${money(r['amount_minor'])} · ${text(r['reason'])}',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (rows(booking['amendments']).isNotEmpty)
                  section(
                    'Amendments',
                    Column(
                      children: rows(booking['amendments'])
                          .map(
                            (a) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Amendment ${a['id']} · ${human(a['status'])}',
                              ),
                              subtitle: Text(text(a['reason'])),
                              onTap: () => adaptiveDialog(
                                context,
                                DialogFrame(
                                  title: 'Proposed changes',
                                  child: SelectableText(
                                    const JsonEncoder.withIndent('  ').convert(
                                      a['proposal'] ?? a['proposed_data'] ?? a,
                                    ),
                                  ),
                                ),
                              ),
                              trailing: s.admin && a['status'] == 'pending'
                                  ? PopupMenuButton<String>(
                                      onSelected: (v) => action(() async {
                                        await s.api.send(
                                          'POST',
                                          'booking-amendments/${a['id']}/$v',
                                        );
                                        await load();
                                      }),
                                      itemBuilder: (_) => ['approve', 'reject']
                                          .map(
                                            (v) => PopupMenuItem(
                                              value: v,
                                              child: Text(human(v)),
                                            ),
                                          )
                                          .toList(),
                                    )
                                  : null,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                section(
                  'Booking history',
                  Column(
                    children: rows(booking['events'])
                        .map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.history),
                            title: Text(human(e['action'] ?? e['event'])),
                            subtitle: Text(timestamp(e['created_at'])),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
