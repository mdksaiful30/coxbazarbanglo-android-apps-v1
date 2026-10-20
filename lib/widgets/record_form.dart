import 'package:flutter/material.dart';

import '../core/api.dart';
import 'common.dart';

class FormFieldSpec {
  const FormFieldSpec(
    this.keyName,
    this.label, {
    this.required = false,
    this.options,
    this.numeric = false,
    this.lines = 1,
    this.secret = false,
    this.hint,
  });
  final String keyName, label;
  final bool required, numeric, secret;
  final int lines;
  final Map<String, String>? options;
  final String? hint;
}

/// Reusable validated editor for guests, room readiness, staff, tariffs and finance.
class RecordForm extends StatefulWidget {
  const RecordForm({
    super.key,
    required this.title,
    required this.fields,
    required this.save,
    this.initial = const {},
    this.message,
    this.saveLabel = 'Save changes',
  });
  final String title, saveLabel;
  final List<FormFieldSpec> fields;
  final Json initial;
  final Future<void> Function(Json values) save;
  final String? message;
  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> controllers;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    controllers = {
      for (final f in widget.fields)
        f.keyName: TextEditingController(
          text: text(widget.initial[f.keyName], ''),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final values = <String, dynamic>{};
      for (final f in widget.fields) {
        final value = controllers[f.keyName]!.text.trim();
        if (value.isEmpty && !f.required) continue;
        values[f.keyName] = f.numeric ? int.parse(value) : value;
      }
      await widget.save(values);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => DialogFrame(
    title: widget.title,
    busy: busy,
    actions: [
      FilledButton(
        onPressed: busy ? null : save,
        child: Text(busy ? 'Saving…' : widget.saveLabel),
      ),
    ],
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message != null) ...[
            Text(widget.message!),
            const SizedBox(height: 20),
          ],
          if (error != null) ...[
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
          ],
          FieldGrid(
            widget.fields.map((f) {
              String? validate(String? v) {
                if (f.required && (v == null || v.trim().isEmpty)) {
                  return '${f.label} is required';
                }
                if (f.numeric &&
                    v != null &&
                    v.isNotEmpty &&
                    int.tryParse(v) == null) {
                  return 'Enter a whole number';
                }
                return null;
              }

              if (f.options != null) {
                return DropdownButtonFormField<String>(
                  initialValue:
                      f.options!.containsKey(controllers[f.keyName]!.text)
                      ? controllers[f.keyName]!.text
                      : null,
                  decoration: InputDecoration(labelText: f.label),
                  isExpanded: true,
                  items: f.options!.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (v) => controllers[f.keyName]!.text = v ?? '',
                  validator: validate,
                );
              }
              return TextFormField(
                controller: controllers[f.keyName],
                decoration: InputDecoration(
                  labelText: f.label,
                  helperText: f.hint,
                ),
                enabled: !busy,
                obscureText: f.secret,
                maxLines: f.lines,
                keyboardType: f.numeric ? TextInputType.number : null,
                validator: validate,
              );
            }).toList(),
          ),
        ],
      ),
    ),
  );
}

const guestFields = [
  FormFieldSpec('name', 'Guest name', required: true),
  FormFieldSpec('designation', 'Designation'),
  FormFieldSpec('organization', 'Organization'),
  FormFieldSpec(
    'mobile',
    'Mobile number',
    required: true,
    hint: '+88017XXXXXXXX',
  ),
  FormFieldSpec('email', 'Email'),
  FormFieldSpec('address', 'Address', lines: 2),
];
const reasonField = FormFieldSpec('reason', 'Reason', required: true, lines: 2);
