import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/api.dart';
import '../../widgets/common.dart';

/// Renders with Flutter's text engine so Bengali shaping matches the app.
/// All figures come from the authenticated confirmation response.
class BookingDocument {
  static Future<void>? _fonts;
  static Future<void> _loadFonts() async {
    for (final family in ['Roboto', 'NotoSansBengali']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
  }

  static Future<Uint8List> render(Json data, String format) async {
    if (!['pdf', 'jpg'].contains(format)) {
      throw ArgumentError.value(format, 'format');
    }
    if (text(data['number'], '').isEmpty || object(data['finance']).isEmpty) {
      throw StateError(
        'Booking confirmation is incomplete. Please refresh and retry.',
      );
    }
    await (_fonts ??= _loadFonts());
    final guest = object(data['guest']);
    final property = object(data['property']);
    final finance = object(data['finance']);
    final blocks = <({String value, double size, bool bold})>[];
    void line(String value, {double size = 15, bool bold = false}) {
      blocks.add((value: value, size: size, bold: bold));
    }

    void field(String label, dynamic value) => line('$label: ${text(value)}');
    String amount(dynamic value) =>
        'BDT ${(number(value) / 100).toStringAsFixed(2)}';
    line(text(property['name'], 'Coxbazarbanglo'), size: 26, bold: true);
    line(text(property['address'], "Cox's Bazar, Bangladesh"));
    line('BOOKING & PAYMENT SUMMARY', size: 19, bold: true);
    field('Booking', data['number']);
    field('Status', human(data['status']));
    if (data['status'] != 'confirmed' &&
            data['status'] != 'checked_in' &&
            data['status'] != 'checked_out' ||
        data['provisional'] == true) {
      line('This document does not authorize a confirmed stay.', bold: true);
    }
    line('Guest information', size: 19, bold: true);
    for (final entry in {
      'name': 'Name',
      'designation': 'Designation',
      'organization': 'Organization',
      'mobile': 'Mobile',
      'email': 'Email',
    }.entries) {
      field(entry.value, guest[entry.key]);
    }
    field('Category', data['category']);
    line('Stay information (Asia/Dhaka)', size: 19, bold: true);
    field('Arrival', timestamp(data['check_in_at']));
    field('Departure', timestamp(data['check_out_at']));
    field('Guests', data['guest_count']);
    field('Reference', data['reference_letter']);
    field('Reference date', data['reference_date']);
    line('Rooms', size: 19, bold: true);
    for (final room in rows(data['rooms'])) {
      line(
        '${text(room['code'])} — ${text(room['name'])} · ${text(room['floor'])} · ${room['ac_type'] == 'ac' ? 'AC' : 'Non-AC'}',
      );
    }
    line('Payment summary', size: 19, bold: true);
    if (data['provisional'] == true) {
      field('Provisional quote', amount(data['quote_total_minor']));
    }
    field('Charges after credits', amount(finance['charges_minor']));
    field(
      'Net paid',
      amount(number(finance['paid_minor']) - number(finance['refunded_minor'])),
    );
    field('Balance', amount(finance['balance_minor']));
    field('Payment status', human(finance['payment_status']));
    line(
      'Room tariffs include VAT. Negative balance represents an overpayment. This booking summary is not a separate payment receipt.',
      size: 12,
    );
    field('Booking revision', data['version']);
    field('Generated (Dhaka)', timestamp(data['generated_at']));
    line('Please contact the rest-house office for assistance.', size: 12);

    const width = 794.0, height = 1123.0, margin = 48.0, scale = 1.5;
    final pages = <Uint8List>[];
    var recorder = ui.PictureRecorder();
    var canvas = ui.Canvas(recorder)..scale(scale);
    void background() => canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()..color = const ui.Color(0xffffffff),
    );
    background();
    var y = margin;
    Future<void> finish() async {
      final footer = TextPainter(
        text: TextSpan(
          text: 'Coxbazarbanglo · Page ${pages.length + 1}',
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            color: ui.Color(0xff52635f),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: width - margin * 2);
      footer.paint(canvas, const ui.Offset(margin, height - 32));
      footer.dispose();
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        (width * scale).round(),
        (height * scale).round(),
      );
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError('Unable to render document');
        pages.add(bytes.buffer.asUint8List());
      } finally {
        image.dispose();
        picture.dispose();
      }
    }

    for (final block in blocks) {
      final painter = TextPainter(
        text: TextSpan(
          text: block.value,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontFamilyFallback: const ['NotoSansBengali'],
            fontSize: block.size,
            fontWeight: block.bold ? FontWeight.w700 : FontWeight.w400,
            color: const ui.Color(0xff163d36),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: width - margin * 2);
      if (y + painter.height > height - 60) {
        await finish();
        recorder = ui.PictureRecorder();
        canvas = ui.Canvas(recorder)..scale(scale);
        background();
        y = margin;
      }
      painter.paint(canvas, ui.Offset(margin, y));
      y += painter.height + (block.bold ? 14 : 9);
      painter.dispose();
    }
    await finish();
    if (format == 'pdf') {
      final document = pw.Document(
        title: 'Booking ${data['number']}',
        author: 'Coxbazarbanglo',
      );
      for (final page in pages) {
        document.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (_) =>
                pw.Image(pw.MemoryImage(page), fit: pw.BoxFit.contain),
          ),
        );
      }
      return document.save();
    }
    final decoded = pages.map((p) => img.decodePng(p)!).toList();
    final combined = img.Image(
      width: decoded.first.width,
      height: decoded.fold<int>(0, (sum, page) => sum + page.height),
    );
    var offset = 0;
    for (final page in decoded) {
      img.compositeImage(combined, page, dstY: offset);
      offset += page.height;
    }
    return Uint8List.fromList(img.encodeJpg(combined, quality: 90));
  }
}
