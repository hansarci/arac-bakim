import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/vehicle.dart';
import '../utils/date_utils.dart';
import '../utils/formatters.dart';

final _green = PdfColor.fromInt(0xFF2F7D57);
final _red = PdfColor.fromInt(0xFFC8503F);
final _ink = PdfColor.fromInt(0xFF14201A);
final _muted = PdfColor.fromInt(0xFF556055);
final _line = PdfColor.fromInt(0xFFD5DDD8);
final _okLine = PdfColor.fromInt(0xFF2F9E64);
final _okText = PdfColor.fromInt(0xFF1E7A4B);
final _warnLine = PdfColor.fromInt(0xFFE0901F);
final _warnText = PdfColor.fromInt(0xFFB06E0E);
final _warnBg = PdfColor.fromInt(0xFFFFF7EA);
final _badText = PdfColor.fromInt(0xFFB23C2B);
final _badBg = PdfColor.fromInt(0xFFFDEFEC);

/// Bir yıl bloğu (bir sütun). Çok kayıtlı yıllar sayfaya sığsın diye parçalanır.
class _YearBlock {
  final String title;
  final int? count;
  final List<HistoryItem> items;
  _YearBlock({required this.title, required this.count, required this.items});
}

class PdfReportService {
  static const int _maxPerBlock = 18;

  /// Raporu üretir ve telefonun paylaşım menüsünü (WhatsApp, e-posta vb.) açar.
  static Future<void> shareReport(
    Vehicle v, {
    required bool includeDates,
    required bool includeHistory,
  }) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));
    final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          _topBar(),
          pw.SizedBox(height: 14),
          _vehicleBlock(v),
          pw.SizedBox(height: 10),
          _facts(v),
          if (includeDates) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('YASAL SÜRELER'),
            pw.SizedBox(height: 6),
            _dates(v),
          ],
          if (includeHistory) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('BAKIM GEÇMİŞİ'),
            pw.SizedBox(height: 6),
            ..._history(v),
          ],
        ],
      ),
    );

    final bytes = await doc.save();
    final plate = v.plate.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    final name = plate.isEmpty ? 'arac' : plate;
    await Printing.sharePdf(bytes: bytes, filename: 'bakim-raporu-$name.pdf');
  }

  // ---------------------------------------------------------------- parçalar

  static pw.Widget _topBar() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _green, width: 2.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ARAÇ BAKIM',
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold, color: _green)),
              pw.Text('Araç bakım raporu',
                  style: pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Rapor tarihi', style: pw.TextStyle(fontSize: 8, color: _muted)),
              pw.Text(todayTrDate(),
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _vehicleBlock(Vehicle v) {
    final typeLine = v.modelYear != null ? '${v.type} · Model yılı ${v.modelYear}' : v.type;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(v.name,
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _ink, width: 1.2),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(v.plate,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
            ),
          ],
        ),
        pw.Text(typeLine, style: pw.TextStyle(fontSize: 9, color: _muted)),
      ],
    );
  }

  static pw.Widget _facts(Vehicle v) {
    pw.Widget cell(String value, String label) => pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _line, width: 0.8),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              children: [
                pw.Text(value,
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold, color: _ink)),
                pw.Text(label, style: pw.TextStyle(fontSize: 7.5, color: _muted)),
              ],
            ),
          ),
        );

    return pw.Row(
      children: [
        cell(fmtThousands(v.km), 'toplam ${v.unit}'),
        pw.SizedBox(width: 8),
        cell('${v.history.length}', 'kayıtlı işlem'),
        pw.SizedBox(width: 8),
        cell('${v.age}', 'yıl yaşında'),
      ],
    );
  }

  static pw.Widget _sectionTitle(String t) => pw.Text(t,
      style: pw.TextStyle(
          fontSize: 8, fontWeight: pw.FontWeight.bold, color: _muted, letterSpacing: 0.8));

  // ----------------------------------------------------------- yasal süreler

  static pw.Widget _dates(Vehicle v) {
    final nextInspection = calcNextInspection(v.lastInspectionDate, v.inspectionInterval);
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _dateBox('MUAYENE', nextInspection),
        pw.SizedBox(width: 8),
        _dateBox('TRAFİK SİGORTASI', v.trafficInsuranceDate),
        pw.SizedBox(width: 8),
        _dateBox('KASKO', v.kaskoDate),
      ],
    );
  }

  static pw.Widget _dateBox(String label, String? date) {
    final int? d = daysUntil(date);
    PdfColor bar;
    PdfColor bg = PdfColors.white;
    PdfColor subColor;
    String sub;
    if (d == null) {
      bar = _line;
      subColor = _muted;
      sub = 'Tarih girilmemiş';
    } else if (d < 0) {
      bar = _red;
      bg = _badBg;
      subColor = _badText;
      sub = '${d.abs()} gün geçti';
    } else if (d <= 15) {
      bar = _warnLine;
      bg = _warnBg;
      subColor = _warnText;
      sub = d == 0 ? 'bugün' : '$d gün kaldı';
    } else {
      bar = _okLine;
      subColor = _okText;
      sub = '$d gün kaldı';
    }

    final side = pw.BorderSide(color: _line, width: 0.8);
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: pw.BoxDecoration(
          color: bg,
          border: pw.Border(
            left: pw.BorderSide(color: bar, width: 4),
            top: side,
            right: side,
            bottom: side,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 7.5, color: _muted)),
            pw.SizedBox(height: 2),
            pw.Text(d == null ? '—' : date!,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.SizedBox(height: 1),
            pw.Text(sub, style: pw.TextStyle(fontSize: 8, color: subColor)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ bakım geçmişi

  static List<pw.Widget> _history(Vehicle v) {
    if (v.history.isEmpty) {
      return [
        pw.Text('Henüz işlem kaydı yok',
            style: pw.TextStyle(fontSize: 9, color: _muted)),
      ];
    }

    // Yıllara göre grupla
    final grouped = <int, List<HistoryItem>>{};
    for (final h in v.history) {
      final y = parseTrDate(h.date)?.year ?? 0;
      grouped.putIfAbsent(y, () => []).add(h);
    }
    final years = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 0) return 1; // tarihsizler en sona
        if (b == 0) return -1;
        return a.compareTo(b);
      });

    final blocks = <_YearBlock>[];
    for (final y in years) {
      final items = grouped[y]!;
      items.sort((a, b) {
        final da = parseTrDate(a.date);
        final db = parseTrDate(b.date);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return da.compareTo(db);
      });
      for (var i = 0; i < items.length; i += _maxPerBlock) {
        final end = i + _maxPerBlock > items.length ? items.length : i + _maxPerBlock;
        blocks.add(_YearBlock(
          title: y == 0 ? 'Tarihsiz' : (i == 0 ? '$y' : '$y (devam)'),
          count: i == 0 ? items.length : null,
          items: items.sublist(i, end),
        ));
      }
    }

    // Izgara: her satırda iki yıl yan yana; Table aynı satırdaki hücreleri aynı
    // yüksekliğe getirir, böylece kırmızı kapanış çizgileri hizalı biter.
    final rows = <pw.TableRow>[];
    for (var i = 0; i < blocks.length; i += 2) {
      final left = blocks[i];
      final right = i + 1 < blocks.length ? blocks[i + 1] : null;
      rows.add(pw.TableRow(children: [
        _yearCell(left, isRight: false),
        right == null ? pw.SizedBox() : _yearCell(right, isRight: true),
      ]));
    }

    return [
      pw.Table(
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
        columnWidths: const {
          0: pw.FlexColumnWidth(),
          1: pw.FlexColumnWidth(),
        },
        children: rows,
      ),
    ];
  }

  static pw.Widget _yearCell(_YearBlock b, {required bool isRight}) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: pw.EdgeInsets.only(left: isRight ? 10 : 0, right: isRight ? 0 : 10, bottom: 6),
      decoration: pw.BoxDecoration(
        border: isRight
            ? pw.Border(
                left: pw.BorderSide(color: _line, width: 1),
                bottom: pw.BorderSide(color: _red, width: 1.3), // yıl sonu çizgisi
              )
            : pw.Border(
                bottom: pw.BorderSide(color: _red, width: 1.3), // yıl sonu çizgisi
              ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 3),
            margin: const pw.EdgeInsets.only(bottom: 3),
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1.2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(b.title,
                    style: pw.TextStyle(
                        fontSize: 13, fontWeight: pw.FontWeight.bold, color: _green)),
                pw.Text(b.count == null ? '' : '${b.count} işlem',
                    style: pw.TextStyle(fontSize: 8, color: _muted)),
              ],
            ),
          ),
          ...b.items.map(_itemRow),
        ],
      ),
    );
  }

  static pw.Widget _itemRow(HistoryItem h) {
    final shortDate = h.date.length >= 5 ? h.date.substring(0, 5) : h.date;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(h.cat,
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold, color: _okText)),
                if (h.sub.isNotEmpty)
                  pw.Text(h.sub,
                      style: pw.TextStyle(
                          fontSize: 8, color: PdfColor.fromInt(0xFF445044))),
              ],
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(shortDate,
                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _ink)),
              pw.Text(h.km > 0 ? '${fmtThousands(h.km)} km' : '—',
                  style: pw.TextStyle(fontSize: 7.5, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Araç Bakım uygulamasıyla oluşturuldu',
              style: pw.TextStyle(fontSize: 7.5, color: _muted)),
          pw.Text('Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7.5, color: _muted)),
        ],
      ),
    );
  }
}
