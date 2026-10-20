import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../widgets/common.dart';
import '../../widgets/record_form.dart';

class BookingEditor extends StatefulWidget {
  const BookingEditor({super.key, this.booking, this.mode = 'draft'});
  final Json? booking;
  final String mode;
  @override
  State<BookingEditor> createState() => _BookingEditorState();
}

class _BookingEditorState extends State<BookingEditor> {
  final formKey = GlobalKey<FormState>();
  final guestSearch = TextEditingController();
  final reference = TextEditingController(),
      purpose = TextEditingController(),
      notes = TextEditingController(),
      count = TextEditingController(text: '1'),
      reason = TextEditingController(),
      refDate = TextEditingController();
  final guestName = TextEditingController(),
      guestMobile = TextEditingController(),
      guestEmail = TextEditingController(),
      designation = TextEditingController(),
      organization = TextEditingController(),
      address = TextEditingController();
  List<Json> guests = [], rooms = [];
  Set<int> roomIds = {};
  int? guestId, categoryId, tariffId;
  DateTime start = DateTime(
    dhakaNow().year,
    dhakaNow().month,
    dhakaNow().day,
    14,
  );
  late DateTime end = start.add(const Duration(days: 1)).copyWith(hour: 12);
  bool loading = true, busy = false, roomBusy = false, notify = false;
  String? error;
  Json? quote;
  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    if (b != null) {
      guestId = number(b['guest_id']);
      categoryId = number(b['guest_category_id']);
      tariffId = b['tariff_version_id'] == null
          ? null
          : number(b['tariff_version_id']);
      start = DateTime.tryParse(text(b['check_in_at'])) ?? start;
      end = DateTime.tryParse(text(b['check_out_at'])) ?? end;
      roomIds = rows(b['rooms']).map((r) => number(r['id'])).toSet();
      reference.text = text(b['reference_letter'], '');
      refDate.text = text(b['reference_date'], '');
      purpose.text = text(b['purpose'], '');
      notes.text = text(b['notes'], '');
      count.text = text(b['guest_count'], '1');
      final g = object(b['guest_snapshot']);
      guestName.text = text(g['name'], '');
      guestMobile.text = text(g['mobile'], '');
      guestEmail.text = text(g['email'], '');
      designation.text = text(g['designation'], '');
      organization.text = text(g['organization'], '');
      address.text = text(g['address'], '');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  @override
  void dispose() {
    for (final c in [
      guestSearch,
      reference,
      purpose,
      notes,
      count,
      reason,
      refDate,
      guestName,
      guestMobile,
      guestEmail,
      designation,
      organization,
      address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    try {
      final s = AppScope.of(context);
      await s.loadCatalog();
      final r = await s.api.get('guests');
      guests = rows(r['data']);
      if (widget.booking != null && !guests.any((g) => g['id'] == guestId)) {
        guests.insert(0, {
          'id': guestId,
          ...object(widget.booking!['guest_snapshot']),
        });
      }
      categoryId ??= rows(s.catalog['categories']).firstOrNull?['id'] as int?;
      await available();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> available() async {
    if (!mounted) return;
    setState(() {
      roomBusy = true;
      quote = null;
    });
    try {
      final r = await AppScope.of(context).api.get(
        'availability',
        query: {
          'check_in_at': dhakaInput(start),
          'check_out_at': dhakaInput(end),
          if (widget.booking != null && widget.mode != 'draft')
            'exclude_booking_id': widget.booking!['id'],
        },
      );
      if (mounted) {
        setState(() {
          rooms = rows(r['data']);
          roomIds.removeWhere(
            (id) => !rooms.any((r) => r['id'] == id && r['available'] == true),
          );
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => roomBusy = false);
    }
  }

  Future<void> findGuest() async {
    setState(() => busy = true);
    try {
      final r = await AppScope.of(context).api
          .get('guests', query: {'search': guestSearch.text});
      if (mounted) setState(() => guests = rows(r['data']));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addGuest() async {
    final s = AppScope.of(context);
    Json? created;
    final ok = await adaptiveDialog<bool>(
      context,
      RecordForm(
        title: 'New guest',
        fields: guestFields,
        save: (v) async {
          created = object((await s.api.send('POST', 'guests', v))['data']);
        },
      ),
    );
    if (ok == true && created != null && mounted) {
      setState(() {
        guests.insert(0, created!);
        guestId = number(created!['id']);
      });
    }
  }

  Future<void> pickDate(bool arrival) async {
    final original = arrival ? start : end;
    final now = dhakaNow();
    final today = DateTime(now.year, now.month, now.day);
    final minimum = widget.mode == 'draft' ? today : DateTime(2020);
    final first = !arrival && start.isAfter(minimum)
        ? DateUtils.dateOnly(start)
        : minimum;
    final d = await showDatePicker(
      context: context,
      initialDate: original.isBefore(first) ? first : original,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(original),
    );
    if (t == null || !mounted) return;
    setState(() {
      final value = d.copyWith(hour: t.hour, minute: t.minute);
      if (arrival) {
        start = value;
      } else {
        end = value;
      }
    });
    await available();
  }

  Json payload() => {
    'guest_id': guestId,
    'guest_category_id': categoryId,
    if (tariffId != null) 'tariff_version_id': tariffId,
    'room_ids': roomIds.toList()..sort(),
    'check_in_at': dhakaInput(start),
    'check_out_at': dhakaInput(end),
    'guest_count': int.tryParse(count.text) ?? 1,
    'reference_letter': reference.text,
    'reference_date': refDate.text.isEmpty ? null : refDate.text,
    'purpose': purpose.text,
    'notes': notes.text,
    if (widget.booking != null) 'version': widget.booking!['version'],
    if (widget.mode != 'draft') 'reason': reason.text,
    if (widget.mode == 'approved') ...{
      'notify_guest': notify,
      'guest_details': {
        'name': guestName.text,
        'mobile': guestMobile.text,
        'email': guestEmail.text.isEmpty ? null : guestEmail.text,
        'designation': designation.text,
        'organization': organization.text,
        'address': address.text,
      },
    },
  };
  bool validate() {
    if (!formKey.currentState!.validate()) return false;
    final now = dhakaNow();
    if (widget.mode == 'draft' &&
        DateUtils.dateOnly(start)
            .isBefore(DateTime(now.year, now.month, now.day))) {
      setState(() => error = 'Arrival cannot be before today (Asia/Dhaka).');
      return false;
    }
    if (guestId == null ||
        categoryId == null ||
        roomIds.isEmpty ||
        !end.isAfter(start)) {
      setState(
        () => error = 'Choose a guest, category, valid dates and at least one available room.',
      );
      return false;
    }
    return true;
  }

  Future<void> calculate() async {
    if (!validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await AppScope.of(context).api
          .send('POST', 'booking-quotes', payload());
      if (mounted) setState(() => quote = object(r['data']));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final b = widget.booking;
      final path = b == null
          ? 'bookings'
          : widget.mode == 'approved'
          ? 'bookings/${b['id']}/approved-details'
          : widget.mode == 'amendment'
          ? 'bookings/${b['id']}/amendments'
          : 'bookings/${b['id']}';
      final r = await AppScope.of(context).api.send(
        b == null || widget.mode == 'amendment' ? 'POST' : 'PATCH',
        path,
        payload(),
      );
      if (mounted) {
        Navigator.pop(
          context,
          b == null ? number(object(r['data'])['id']) : number(b['id']),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final categories = rows(s.catalog['categories']),
        tariffs = rows(s.catalog['tariffs']);
    Widget field(
      TextEditingController c,
      String label, {
      bool required = false,
      int lines = 1,
    }) => TextFormField(
      controller: c,
      enabled: !busy,
      decoration: InputDecoration(labelText: label),
      maxLines: lines,
      validator: (v) =>
          required && (v ?? '').trim().isEmpty ? 'Required' : null,
      onChanged: (_) => setState(() => quote = null),
    );
    return DialogFrame(
      title: widget.booking == null
          ? 'New booking'
          : widget.mode == 'approved'
          ? 'Edit approved booking'
          : widget.mode == 'amendment'
          ? 'Propose amendment'
          : 'Edit draft',
      busy: busy,
      actions: [
        OutlinedButton(
          onPressed: busy || roomBusy ? null : calculate,
          child: const Text('Calculate quote'),
        ),
        FilledButton(
          onPressed: busy || roomBusy || loading ? null : save,
          child: Text(busy ? 'Saving…' : 'Save changes'),
        ),
      ],
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null) ...[
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: guestSearch,
                          decoration: InputDecoration(
                            labelText: 'Find guest by name/mobile',
                            suffixIcon: IconButton(
                              onPressed: busy ? null : findGuest,
                              icon: const Icon(Icons.search),
                            ),
                          ),
                          onSubmitted: (_) => findGuest(),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Create guest',
                        onPressed: busy ? null : addGuest,
                        icon: const Icon(Icons.person_add_alt_1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FieldGrid([
                    DropdownButtonFormField<int>(
                      key: ValueKey(
                        'guest-$guestId-${guests.map((g) => g['id']).join(',')}',
                      ),
                      initialValue: guests.any((g) => g['id'] == guestId)
                          ? guestId
                          : null,
                      decoration: const InputDecoration(labelText: 'Guest'),
                      isExpanded: true,
                      items: guests
                          .map(
                            (g) => DropdownMenuItem(
                              value: number(g['id']),
                              child: Text(
                                '${g['name']} · ${g['mobile']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: busy
                          ? null
                          : (v) {
                              setState(() {
                                guestId = v;
                                quote = null;
                                if (widget.mode == 'approved') {
                                  final g = guests.firstWhere(
                                    (g) => g['id'] == v,
                                  );
                                  guestName.text = text(g['name'], '');
                                  guestMobile.text = text(g['mobile'], '');
                                  guestEmail.text = text(g['email'], '');
                                  designation.text = text(g['designation'], '');
                                  organization.text = text(
                                    g['organization'],
                                    '',
                                  );
                                  address.text = text(g['address'], '');
                                }
                              });
                            },
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Guest category',
                      ),
                      isExpanded: true,
                      items: categories
                          .map(
                            (g) => DropdownMenuItem(
                              value: number(g['id']),
                              child: Text(
                                '${g['code']} · ${g['name']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              categoryId = v;
                              quote = null;
                            }),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => pickDate(true),
                      icon: const Icon(Icons.login),
                      label: Text('Arrival\n${timestamp(start.toString())}'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => pickDate(false),
                      icon: const Icon(Icons.logout),
                      label: Text('Departure\n${timestamp(end.toString())}'),
                    ),
                    TextFormField(
                      controller: count,
                      decoration: const InputDecoration(
                        labelText: 'Number of guests',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0
                          ? null
                          : 'Enter a positive whole number',
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: tariffId,
                      decoration: const InputDecoration(
                        labelText: 'Tariff version',
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Automatic active tariff'),
                        ),
                        ...tariffs.map(
                          (t) => DropdownMenuItem(
                            value: number(t['id']),
                            child: Text(
                              text(t['name']),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              tariffId = v;
                              quote = null;
                            }),
                    ),
                    field(reference, 'Reference letter number'),
                    field(refDate, 'Reference date (YYYY-MM-DD)'),
                    field(purpose, 'Purpose', lines: 2),
                    field(notes, 'Internal notes', lines: 2),
                  ]),
                  if (widget.mode == 'approved') ...[
                    const SizedBox(height: 24),
                    Text(
                      'Guest details on this booking',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    FieldGrid([
                      field(guestName, 'Guest name', required: true),
                      field(guestMobile, 'Guest mobile', required: true),
                      field(guestEmail, 'Guest email'),
                      field(designation, 'Designation'),
                      field(organization, 'Organization'),
                      field(address, 'Address', lines: 2),
                    ]),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notify guest after saving'),
                      value: notify,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => notify = v),
                    ),
                  ],
                  if (widget.mode != 'draft') ...[
                    const SizedBox(height: 16),
                    field(
                      reason,
                      'Reason for changes',
                      required: true,
                      lines: 2,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Room allocation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Times are Dhaka-local. Unavailable rooms cannot be selected.',
                  ),
                  const SizedBox(height: 12),
                  if (roomBusy)
                    const LinearProgressIndicator()
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rooms.map((r) {
                        final id = number(r['id']);
                        return FilterChip(
                          label: Text('${r['code']} · ${r['name']}'),
                          selected: roomIds.contains(id),
                          onSelected: busy || r['available'] != true
                              ? null
                              : (v) => setState(() {
                                  v ? roomIds.add(id) : roomIds.remove(id);
                                  quote = null;
                                }),
                        );
                      }).toList(),
                    ),
                  if (quote != null) ...[
                    const SizedBox(height: 20),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quoted total: ${money(quote!['total_minor'])}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (quote!['provisional'] == true)
                            const Text(
                              'Provisional — tariff approval is required before confirmation.',
                            ),
                          const Text(
                            'VAT included. The server revalidates this price and availability when saved.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
