import 'package:flutter/material.dart';

import '../../core/api.dart';
import '../../core/session.dart';
import '../../widgets/common.dart';
import '../../widgets/workspace_ui.dart';
import 'booking_detail.dart';
import 'booking_editor.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});
  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  final search = TextEditingController();
  List<Json> bookings = [];
  String status = '';
  int page = 1;
  bool next = false, loading = true, moreBusy = false;
  String? error;
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
      if (more) {
        moreBusy = true;
      } else {
        loading = true;
        page = 1;
      }
      error = null;
    });
    try {
      final r = await AppScope.of(context).api.get(
        'bookings',
        query: {
          'search': search.text,
          'page': more ? page + 1 : 1,
          'per_page': 25,
          if (status.isNotEmpty) 'status': status,
        },
      );
      if (mounted) {
        setState(() {
          if (more) {
            bookings.addAll(rows(r['data']));
            page++;
          } else {
            bookings = rows(r['data']);
          }
          next = r['next_page_url'] != null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          moreBusy = false;
        });
      }
    }
  }

  Future<void> create() async {
    final id = await adaptiveDialog<int>(context, const BookingEditor());
    if (id != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookingDetailScreen(id: id)),
      );
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          WorkspaceHeading(
            s.label('Bookings', 'বুকিং'),
            'Guest stays, approvals and payment history.',
            icon: Icons.hotel_outlined,
            action: FilledButton.icon(
              onPressed: create,
              icon: const Icon(Icons.add),
              label: const Text('New booking'),
            ),
          ),
          Panel(
            padding: const EdgeInsets.all(16),
            child: FieldGrid([
              TextField(
                controller: search,
                decoration: InputDecoration(
                  labelText: 'Find name, mobile or booking',
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    onPressed: load,
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: (_) => load(),
              ),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Booking status'),
                isExpanded: true,
                items:
                    [
                          '',
                          'draft',
                          'pending_approval',
                          'confirmed',
                          'checked_in',
                          'checked_out',
                          'rejected',
                          'cancelled',
                          'no_show',
                        ]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(v.isEmpty ? 'All statuses' : human(v)),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  status = v ?? '';
                  load();
                },
              ),
            ]),
          ),
          if (!loading && error == null) ...[
            const SizedBox(height: 16),
            WorkspaceCounts([
              ('Loaded bookings', '${bookings.length}'),
              (
                'Awaiting approval',
                '${bookings.where((b) => b['status'] == 'pending_approval').length}',
              ),
            ]),
          ],
          const SizedBox(height: 24),
          LoadView(
            loading: loading,
            error: error,
            retry: load,
            child: Column(
              children: [
                if (bookings.isEmpty)
                  const WorkspaceEmpty(
                    message: 'No bookings match your filters.',
                    icon: Icons.hotel_outlined,
                  ),
                ...bookings.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BookingRecordView(
                      booking: b,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BookingDetailScreen(id: number(b['id'])),
                          ),
                        );
                        await load();
                      },
                    ),
                  ),
                ),
                if (next)
                  OutlinedButton(
                    onPressed: moreBusy ? null : () => load(more: true),
                    child: Text(moreBusy ? 'Loading…' : 'Load more bookings'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
