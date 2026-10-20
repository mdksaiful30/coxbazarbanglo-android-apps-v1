import 'package:flutter/material.dart';

import '../core/api.dart';
import 'common.dart';

class WorkspaceHeading extends StatelessWidget {
  const WorkspaceHeading(
    this.title,
    this.subtitle, {
    super.key,
    this.action,
    this.icon = Icons.dashboard_outlined,
  });
  final String title, subtitle;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer.withValues(alpha: .65),
            colors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.primary, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
              ),
            ],
          );
          if (c.maxWidth > 650) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: heading),
                if (action != null) ...[const SizedBox(width: 24), action!],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          );
        },
      ),
    );
  }
}

class RecordMeta extends StatelessWidget {
  const RecordMeta(this.icon, this.value, {super.key});
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class WorkspaceCounts extends StatelessWidget {
  const WorkspaceCounts(this.items, {super.key});
  final List<(String, String)> items;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: items
        .map(
          (item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${item.$1}  ${item.$2}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        )
        .toList(),
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });
  final String label, value;
  final IconData icon;
  final Color accent;
  @override
  Widget build(BuildContext context) => Card(
    child: Container(
      constraints: const BoxConstraints(minHeight: 146),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 23),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class WorkspaceEmpty extends StatelessWidget {
  const WorkspaceEmpty({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Panel(
      child: Column(
        children: [
          Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class BookingRecordView extends StatelessWidget {
  const BookingRecordView({
    super.key,
    required this.booking,
    required this.onTap,
  });
  final Json booking;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      text(booking['number']),
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: colors.primary, letterSpacing: .5),
                    ),
                    StatusPill(text(booking['status'])),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text(object(booking['guest_snapshot'])['name']),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                RecordMeta(
                  Icons.login_rounded,
                  'Check-in · ${timestamp(booking['check_in_at'])}',
                ),
                RecordMeta(
                  Icons.logout_rounded,
                  'Check-out · ${timestamp(booking['check_out_at'])}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: rows(booking['rooms'])
                      .map(
                        (room) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(
                              alpha: .5,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '${room['code']} · ${room['name']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DirectoryRecordView extends StatelessWidget {
  const DirectoryRecordView({
    super.key,
    required this.kind,
    required this.record,
    required this.actions,
  });
  final String kind;
  final Json record;
  final Widget actions;
  @override
  Widget build(BuildContext context) {
    final r = record;
    final colors = Theme.of(context).colorScheme;
    final person = kind == 'Guests' || kind == 'Staff';
    final name = person
        ? text(r['name'])
        : kind == 'Notifications'
        ? '${human(r['channel'])} delivery'
        : human(r['action']);
    final icon = switch (kind) {
      'Guests' => Icons.person_outline,
      'Staff' => Icons.badge_outlined,
      'Notifications' => Icons.send_outlined,
      _ => Icons.history_rounded,
    };
    final accent = kind == 'Notifications' && r['status'] == 'failed'
        ? colors.error
        : colors.primary;
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: person
                        ? Text(
                            name.characters.first.toUpperCase(),
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          )
                        : Icon(icon, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          switch (kind) {
                            'Guests' => text(r['organization'], 'Guest record'),
                            'Staff' => human(r['role']),
                            'Notifications' =>
                              'Booking ${text(r['booking_id'])}',
                            _ =>
                              '${human(r['entity'] ?? r['entity_type'])} · #${text(r['entity_id'])}',
                          },
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (kind == 'Staff')
                StatusPill(
                  r['active'] == true || r['active'] == 1
                      ? 'active'
                      : 'disabled',
                ),
              if (kind == 'Notifications') StatusPill(text(r['status'])),
              if (kind == 'Guests') ...[
                RecordMeta(Icons.phone_outlined, text(r['mobile'])),
                if (text(r['email'], '').isNotEmpty)
                  RecordMeta(Icons.mail_outline, text(r['email'])),
                if (text(r['designation'], '').isNotEmpty)
                  RecordMeta(Icons.work_outline, text(r['designation'])),
              ],
              if (kind == 'Staff')
                RecordMeta(Icons.mail_outline, text(r['email'])),
              if (kind == 'Notifications') ...[
                RecordMeta(
                  Icons.alternate_email,
                  text(r['destination'], 'No destination recorded'),
                ),
                RecordMeta(Icons.schedule, timestamp(r['created_at'])),
                if (text(r['last_error'], '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      text(r['last_error']),
                      style: TextStyle(color: colors.error),
                    ),
                  ),
              ],
              if (kind == 'Audit trail') ...[
                RecordMeta(Icons.schedule, timestamp(r['created_at'])),
                RecordMeta(
                  Icons.person_outline,
                  r['actor_id'] == null
                      ? 'System action'
                      : 'Staff ID ${r['actor_id']}',
                ),
              ],
              const SizedBox(height: 14),
              Divider(color: colors.outlineVariant.withValues(alpha: .5)),
              const SizedBox(height: 4),
              actions,
            ],
          ),
        ),
      ),
    );
  }
}
