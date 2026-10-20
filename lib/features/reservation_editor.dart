import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../widgets/common.dart';

class ReservationEditor extends StatefulWidget {
  const ReservationEditor({super.key});
  @override
  State<ReservationEditor> createState() => _ReservationEditorState();
}

class _ReservationEditorState extends State<ReservationEditor> {
  final reason = TextEditingController();
  final form = GlobalKey<FormState>();
  final selected = <int>{};
  List<Json> rooms = [];
  String kind = 'reservation';
  bool busy = false, loading = true;
  String? error;
  DateTime start = dhakaNow();
  late DateTime end = start.add(const Duration(days: 1));
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final s = AppScope.of(context);
      await s.loadCatalog();
      if (mounted) setState(() => rooms = rows(s.catalog['rooms']));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pick(bool first) async {
    final value = first ? start : end;
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null || !mounted) return;
    setState(() {
      final d = date.copyWith(hour: time.hour, minute: time.minute);
      if (first) {
        start = d;
      } else {
        end = d;
      }
    });
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (selected.isEmpty || !end.isAfter(start)) {
      setState(() => error = 'Select rooms and an end time after the start.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AppScope.of(context).api.send('POST', 'room-blocks', {
        'kind': kind,
        'reason': reason.text.trim(),
        'room_ids': selected.toList()..sort(),
        'starts_at': dhakaInput(start),
        'ends_at': dhakaInput(end),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DialogFrame(
    title: 'Reserve rooms',
    busy: busy,
    actions: [
      FilledButton(
        onPressed: busy || loading ? null : save,
        child: Text(busy ? 'Saving…' : 'Reserve rooms'),
      ),
    ],
    child: Form(
      key: form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null) ...[
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<String>(
            initialValue: kind,
            decoration: const InputDecoration(labelText: 'Reservation type'),
            items: const [
              DropdownMenuItem(
                value: 'reservation',
                child: Text('Fixed-time reservation'),
              ),
              DropdownMenuItem(
                value: 'maintenance',
                child: Text('Maintenance'),
              ),
            ],
            onChanged: busy ? null : (v) => setState(() => kind = v!),
          ),
          const SizedBox(height: 18),
          FieldGrid([
            OutlinedButton.icon(
              onPressed: busy ? null : () => pick(true),
              icon: const Icon(Icons.event),
              label: Text('From\n${timestamp(start.toString())}'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => pick(false),
              icon: const Icon(Icons.event_available),
              label: Text('Until\n${timestamp(end.toString())}'),
            ),
          ]),
          const SizedBox(height: 18),
          TextFormField(
            controller: reason,
            enabled: !busy,
            decoration: const InputDecoration(labelText: 'Reason'),
            maxLines: 2,
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Enter a reason' : null,
          ),
          const SizedBox(height: 20),
          const Text(
            'Choose rooms. Times are Asia/Dhaka; the server checks for conflicts.',
          ),
          const SizedBox(height: 12),
          if (loading)
            const LinearProgressIndicator()
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rooms
                  .map(
                    (r) => FilterChip(
                      label: Text('${r['code']} — ${r['name']}'),
                      selected: selected.contains(number(r['id'])),
                      onSelected: busy
                          ? null
                          : (v) => setState(() {
                              v
                                  ? selected.add(number(r['id']))
                                  : selected.remove(number(r['id']));
                            }),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    ),
  );
}
