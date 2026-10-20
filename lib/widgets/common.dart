import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';

/// Convert BDT text to exact integer poisha without floating-point rounding.
int moneyInput(String value) {
  final input = value.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(input)) {
    throw const ApiFailure(
      'Enter a BDT amount with at most two decimal places.',
    );
  }
  final parts = input.split('.');
  return int.parse(parts[0]) * 100 +
      (parts.length == 1 ? 0 : int.parse(parts[1].padRight(2, '0')));
}

String money(dynamic minor) => NumberFormat.currency(
  locale: 'en_BD',
  symbol: 'BDT ',
  decimalDigits: 2,
).format(number(minor) / 100);
String dateOnly(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
DateTime dhakaNow() => DateTime.now().toUtc().add(const Duration(hours: 6));
String dhakaInput(DateTime d) =>
    '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(d)}+06:00';
String human(dynamic value) => text(value).replaceAll('_', ' ');
String timestamp(dynamic value) {
  if (value == null) return '—';
  // SQL-style booking timestamps already represent Dhaka time; explicit offsets are converted.
  final raw = '$value';
  final d = DateTime.tryParse(raw);
  if (d == null) return raw;
  final hasOffset =
      raw.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(raw);
  final local = hasOffset ? d.toUtc().add(const Duration(hours: 6)) : d;
  return DateFormat('dd MMM yyyy, HH:mm').format(local);
}

void notice(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final good = [
      'confirmed',
      'ready',
      'paid',
      'delivered',
      'sent',
      'active',
    ].contains(status);
    final bad = [
      'cancelled',
      'rejected',
      'failed',
      'needs_cleaning',
    ].contains(status);
    final color = good
        ? const Color(0xff167451)
        : bad
        ? Theme.of(context).colorScheme.error
        : const Color(0xff9a6911);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        human(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge
                ?.copyWith(fontSize: c.maxWidth < 600 ? 30 : 40),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: c.maxWidth < 650
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  heading,
                  if (action != null) ...[const SizedBox(height: 16), action!],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: heading),
                  if (action != null) ...[const SizedBox(width: 16), action!],
                ],
              ),
      );
    },
  );
}

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}

class LoadView extends StatelessWidget {
  const LoadView({
    super.key,
    required this.loading,
    required this.error,
    required this.retry,
    required this.child,
  });
  final bool loading;
  final String? error;
  final VoidCallback retry;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (error != null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 42),
                const SizedBox(height: 14),
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: retry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return child;
  }
}

/// Dialogs become full-screen routes on phones, and keyboard-safe bounded panels on larger screens.
Future<T?> adaptiveDialog<T>(BuildContext context, Widget child) =>
    showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        if (MediaQuery.sizeOf(context).width < 700) {
          return Dialog.fullscreen(child: SafeArea(child: child));
        }
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: MediaQuery.sizeOf(context).height * .9,
            ),
            child: child,
          ),
        );
      },
    );

class DialogFrame extends StatelessWidget {
  const DialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.busy = false,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool busy;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(spacing: 12, runSpacing: 10, children: actions),
            ),
          ),
      ],
    ),
  );
}

class FieldGrid extends StatelessWidget {
  const FieldGrid(this.children, {super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 560 ? 2 : 1;
      final width = (c.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 18,
        children: children
            .map((w) => SizedBox(width: width, child: w))
            .toList(),
      );
    },
  );
}

class DataFields extends StatelessWidget {
  const DataFields(this.data, {super.key});
  final Json data;
  @override
  Widget build(BuildContext context) => FieldGrid(
    data.entries
        .map(
          (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(human(e.key), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              SelectableText(
                e.value is List ? (e.value as List).join(', ') : text(e.value),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        )
        .toList(),
  );
}
