import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/progress_entry.dart';
import 'package:intl/intl.dart';

class PdfExporter {
  static final _fmt = DateFormat('dd MMM yyyy', 'es');

  static Future<void> exportProgress(List<ProgressEntry> entries) async {
    final doc = pw.Document();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey800, width: 1.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('PIVOTE — Selección Bogotá',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800)),
            pw.Text('Registro de Progreso · Clasificatorios Oct 2026',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ],
        ),
      ),
      build: (_) => [
        pw.SizedBox(height: 16),
        pw.Text('HISTORIAL DE PROGRESO',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey900)),
        pw.SizedBox(height: 4),
        pw.Text('Generado: ${_fmt.format(DateTime.now())} · ${entries.length} registros',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        pw.SizedBox(height: 20),
        if (entries.isNotEmpty) ..._buildWeightTable(entries),
        pw.SizedBox(height: 20),
        if (entries.isNotEmpty) ..._buildPainTable(entries),
        pw.SizedBox(height: 20),
        ..._buildNotes(entries),
      ],
    ));

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'progreso_pivote_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static List<pw.Widget> _buildWeightTable(List<ProgressEntry> entries) {
    final weightRows = entries.where((e) => e.peso != null).toList();
    if (weightRows.isEmpty) return [];

    return [
      pw.Text('Peso Corporal', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: ['Fecha', 'Peso (kg)'],
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.center,
        data: weightRows.map((e) => [_fmt.format(e.fecha), '${e.peso!.toStringAsFixed(1)} kg']).toList(),
      ),
    ];
  }

  static List<pw.Widget> _buildPainTable(List<ProgressEntry> entries) {
    final painRows = entries.where(
      (e) => e.dolorLumbar != null || e.dolorHombro != null || e.dolorRodilla != null,
    ).toList();
    if (painRows.isEmpty) return [];

    return [
      pw.Text('Registro de Dolor', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: ['Fecha', 'Lumbar /10', 'Hombro D /10', 'Rodilla I /10'],
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.center,
        data: painRows.map((e) => [
          _fmt.format(e.fecha),
          e.dolorLumbar?.toString() ?? '-',
          e.dolorHombro?.toString() ?? '-',
          e.dolorRodilla?.toString() ?? '-',
        ]).toList(),
      ),
    ];
  }

  static List<pw.Widget> _buildNotes(List<ProgressEntry> entries) {
    final notesRows = entries.where((e) => e.notas.isNotEmpty).toList();
    if (notesRows.isEmpty) return [];
    return [
      pw.Text('Notas', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      ...notesRows.map((e) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 6),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.blueGrey200),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(_fmt.format(e.fecha),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700)),
          pw.SizedBox(height: 2),
          pw.Text(e.notas, style: const pw.TextStyle(fontSize: 9)),
        ]),
      )),
    ];
  }
}
