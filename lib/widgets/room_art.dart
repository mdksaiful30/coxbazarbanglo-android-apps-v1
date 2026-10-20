import 'package:flutter/material.dart';

import '../core/api.dart';
import 'common.dart';

class RoomArtwork extends StatelessWidget {
  const RoomArtwork({super.key, required this.room, this.width = 118});
  final Json room;
  final double width;
  static String captionFor(Json room) {
    const names = {
      'অপেক্ষমান কক্ষ': 'Waiting Room',
      'বাঁকখালী': 'Bakkhali',
      'মাতামুহুরী': 'Matamuhuri',
      'রেজু': 'Rezu',
      'সাঙ্গু': 'Sangu',
      'কর্ণফুলি': 'Karnaphuli',
      'ধরলা': 'Dharla',
      '৩ নং রুম': 'Room 3',
      '৪ নং রুম': 'Room 4',
      'জলকদর': 'Jalkadar',
      'উজানটিয়া': 'Ujantia',
      'কুহুলিকা': 'Kuhulika',
      'নাফ': 'Naf',
      'স্যুট': 'Suite',
      'ইনানী': 'Inani',
      'হিমছড়ি': 'Himchhari',
      'সোনাদিয়া': 'Sonadia',
    };
    final name = text(room['name'], '').trim();
    var english = text(room['name_en'], '').trim();
    var bengali = text(room['name_bn'], '').trim();
    for (final entry in names.entries) {
      if (name == entry.key ||
          name.toLowerCase() == entry.value.toLowerCase()) {
        if (english.isEmpty) english = entry.value;
        if (bengali.isEmpty) bengali = entry.key;
        break;
      }
    }
    final lines = <String>{
      if (english.isNotEmpty) english,
      if (bengali.isNotEmpty) bengali,
    };
    return lines.isEmpty
        ? text(room['name'], text(room['code'], 'Room'))
        : lines.join('\n');
  }

  static String assetFor(Json room) {
    final name = text(room['name'], '').toLowerCase();
    final type = text(room['room_type'], '').toLowerCase();
    final bed = text(room['bed_type'], '').toLowerCase();
    if (name.contains('অপেক্ষ') || name.contains('waiting')) {
      return 'assets/rooms/waiting.jpg';
    }
    if (type == 'suite' ||
        name.contains('স্যুট') ||
        name.contains('suite') ||
        bed.contains('স্যুট')) {
      return 'assets/rooms/suite.jpg';
    }
    final ac = room['ac_type'] == 'ac';
    final couple =
        bed.contains('কাপল') ||
        bed.contains('couple') ||
        bed.contains('queen') ||
        bed.contains('king');
    return 'assets/rooms/${ac ? 'ac' : 'nonac'}-${couple ? 'double' : 'twin'}.jpg';
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            assetFor(room),
            width: width,
            height: width * 1.1,
            fit: BoxFit.cover,
            semanticLabel: '${captionFor(room)} room artwork',
            errorBuilder: (context, error, stack) => Container(
              width: width,
              height: width * 1.1,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.bed_outlined, size: 34),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          captionFor(room),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );
}

class RoomRecordView extends StatelessWidget {
  const RoomRecordView({
    super.key,
    required this.room,
    required this.available,
    this.onEdit,
  });
  final Json room;
  final bool available;
  final VoidCallback? onEdit;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text(room['code']),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: 1,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          text(room['name']),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${room['ac_type'] == 'ac' ? 'Air conditioned' : 'Non-AC'} · ${text(room['capacity'])} guests',
                        ),
                        if (text(room['bed_type'], '').isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            text(room['bed_type']),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Housekeeping: ${human(room['housekeeping'])}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  RoomArtwork(room: room, width: c.maxWidth < 340 ? 86 : 118),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusPill(available ? 'ready' : 'booked'),
                  if (onEdit != null)
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      label: const Text('Edit room'),
                    ),
                ],
              ),
              if (!available) ...[
                const SizedBox(height: 8),
                Text(
                  'Unavailable for this interval',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
