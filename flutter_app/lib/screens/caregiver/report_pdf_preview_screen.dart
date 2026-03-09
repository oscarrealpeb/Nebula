import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/data/skill_catalog.dart';

class ReportSkillMetric {
  const ReportSkillMetric({
    required this.id,
    required this.title,
    required this.score,
    required this.previousScore,
    required this.evidenceSessions,
    required this.errorRatePercent,
  });

  final String id;
  final String title;
  final double score;
  final double previousScore;
  final int evidenceSessions;
  final double errorRatePercent;
}

class ReportSessionEntry {
  const ReportSessionEntry({
    required this.gameLabel,
    required this.startedAtMillis,
    required this.durationMinutes,
    required this.correctAnswers,
    required this.totalAttempts,
    required this.mistakes,
  });

  final String gameLabel;
  final int startedAtMillis;
  final int durationMinutes;
  final int correctAnswers;
  final int totalAttempts;
  final int mistakes;
}

class ChildReportPdfData {
  const ChildReportPdfData({
    required this.caregiverName,
    required this.childName,
    required this.generatedAtMillis,
    required this.periodDays,
    required this.dailyMinutes,
    required this.hourlyMinutes,
    required this.skills,
    required this.sessions,
  });

  final String caregiverName;
  final String childName;
  final int generatedAtMillis;
  final int periodDays;
  final Map<String, int> dailyMinutes;
  final Map<int, int> hourlyMinutes;
  final List<ReportSkillMetric> skills;
  final List<ReportSessionEntry> sessions;
}

Future<Uint8List> buildChildReportPdfBytes(ChildReportPdfData data) async {
  final doc = pw.Document();
  final generatedAt =
      DateTime.fromMillisecondsSinceEpoch(data.generatedAtMillis);

  final totalMinutes = data.sessions.fold<int>(
    0,
    (sum, item) => sum + item.durationMinutes,
  );
  final totalAttempts = data.sessions.fold<int>(
    0,
    (sum, item) => sum + item.totalAttempts,
  );
  final totalCorrect = data.sessions.fold<int>(
    0,
    (sum, item) => sum + item.correctAnswers.clamp(0, item.totalAttempts),
  );
  final avgAccuracy =
      totalAttempts <= 0 ? 0.0 : ((totalCorrect * 100.0) / totalAttempts);
  final activeDays =
      data.dailyMinutes.values.where((value) => value > 0).length;
  final avgDailyMinutes =
      data.periodDays <= 0 ? 0.0 : (totalMinutes / data.periodDays);
  final avgSessionMinutes =
      data.sessions.isEmpty ? 0.0 : (totalMinutes / data.sessions.length);
  final dominantHour = _dominantHour(data.hourlyMinutes);
  final periodDistribution = _periodDistribution(data.hourlyMinutes);

  final sortedSkills = [...data.skills]
    ..sort((a, b) => b.score.compareTo(a.score));
  final strengths =
      sortedSkills.where((item) => item.score >= 80).take(2).toList();
  final priorities = [...sortedSkills]
    ..sort((a, b) => a.score.compareTo(b.score));
  final prioritySkills =
      priorities.where((item) => item.score < 60).take(2).toList();

  final executiveSummary = _buildExecutiveSummary(
    skills: sortedSkills,
    strengths: strengths,
    priorities: prioritySkills,
    sessionsCount: data.sessions.length,
  );
  final caregiverRecommendations =
      _buildCaregiverRecommendations(prioritySkills);
  final therapistSuggestions = _buildTherapistSuggestions(prioritySkills);

  doc.addPage(
    pw.MultiPage(
      pageTheme: const pw.PageTheme(
        margin: pw.EdgeInsets.all(26),
      ),
      build: (context) => [
        pw.Text(
          'Reporte de uso y desempeno funcional',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text('Nino: ${data.childName}'),
        pw.Text('Cuidador: ${data.caregiverName}'),
        pw.Text('Periodo evaluado: ultimos ${data.periodDays} dias'),
        pw.Text('Generado: ${_formatDateTime(generatedAt)}'),
        pw.SizedBox(height: 4),
        pw.Text(
          'Nota: este reporte apoya la evaluacion clinica y no constituye diagnostico.',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Resumen ejecutivo',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              ...executiveSummary.map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text('- $line'),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Visual rapido (lectura intuitiva)',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Las graficas resumen cuando y cuanto se usa la app.',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 6),
        _buildDailyUsageBars(data.dailyMinutes),
        pw.SizedBox(height: 10),
        _buildPeriodPieChart(periodDistribution),
        pw.SizedBox(height: 12),
        pw.Text(
          'Uso y adherencia',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: const ['Indicador', 'Valor'],
          headerStyle: _tableHeaderStyle(),
          cellStyle: _tableCellStyle,
          columnWidths: const {
            0: pw.FlexColumnWidth(2.8),
            1: pw.FlexColumnWidth(1.7),
          },
          data: [
            ['Sesiones en el periodo', data.sessions.length.toString()],
            ['Minutos totales', totalMinutes.toString()],
            ['Dias con uso', activeDays.toString()],
            ['Promedio diario', '${avgDailyMinutes.toStringAsFixed(1)} min'],
            [
              'Promedio por sesion',
              '${avgSessionMinutes.toStringAsFixed(1)} min'
            ],
            ['Franja horaria dominante', _formatHourLabel(dominantHour)],
            ['Precision promedio', '${avgAccuracy.toStringAsFixed(1)}%'],
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Rendimiento por habilidad',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        if (sortedSkills.isEmpty)
          pw.Text('Sin datos suficientes para habilidades.')
        else
          _tableNoRepeatHeader(
            headers: const [
              'Habilidad',
              'Puntaje',
              'Interpretacion',
              'Tendencia',
              'Evidencia',
              'Confianza'
            ],
            columnWidths: const {
              0: pw.FlexColumnWidth(2.3),
              1: pw.FlexColumnWidth(0.9),
              2: pw.FlexColumnWidth(1.9),
              3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(1.1),
              5: pw.FlexColumnWidth(1.1),
            },
            rows: sortedSkills.map((item) {
              final trend = _trendLabel(item.score, item.previousScore);
              return [
                item.title,
                '${item.score.toStringAsFixed(0)}/100',
                _stateLabel(item.score),
                trend,
                '${item.evidenceSessions} sesiones',
                _confidenceLabel(item.evidenceSessions),
              ];
            }).toList(),
          ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Perfil de error por habilidad',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        if (sortedSkills.isEmpty)
          pw.Text('Sin datos suficientes.')
        else
          pw.TableHelper.fromTextArray(
            headers: const ['Habilidad', 'Error estimado'],
            headerStyle: _tableHeaderStyle(),
            cellStyle: _tableCellStyle,
            columnWidths: const {
              0: pw.FlexColumnWidth(2.8),
              1: pw.FlexColumnWidth(1.2),
            },
            data: sortedSkills
                .where((item) => item.errorRatePercent > 0)
                .take(6)
                .map((item) => [
                      item.title,
                      '${item.errorRatePercent.toStringAsFixed(1)}%',
                    ])
                .toList(),
          ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Generalizacion funcional',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        if (prioritySkills.isEmpty)
          pw.Text('No hay habilidades criticas en este periodo.')
        else
          ...prioritySkills.map((item) {
            final skill = skillById(item.id);
            final example = skill?.everydayExamples.trim() ?? '';
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '- ${item.title}: ${example.isEmpty ? 'sin ejemplo disponible' : example}',
              ),
            );
          }),
        pw.SizedBox(height: 12),
        pw.Text(
          'Recomendaciones para cuidador',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        ...caregiverRecommendations.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text('- $line'),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Sugerencias para terapeuta',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        ...therapistSuggestions.map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text('- $line'),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Calidad de datos',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(_qualityNote(data.sessions.length)),
        pw.SizedBox(height: 12),
        pw.Text(
          'Anexo: sesiones recientes',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        if (data.sessions.isEmpty)
          pw.Text('Sin sesiones registradas.')
        else
          pw.TableHelper.fromTextArray(
            headers: const [
              'Fecha',
              'Juego',
              'Duracion',
              'Aciertos',
              'Intentos',
              'Errores',
            ],
            headerStyle: _tableHeaderStyle(),
            cellStyle: _tableCellStyle,
            columnWidths: const {
              0: pw.FlexColumnWidth(2.0),
              1: pw.FlexColumnWidth(2.1),
              2: pw.FlexColumnWidth(1.0),
              3: pw.FlexColumnWidth(0.9),
              4: pw.FlexColumnWidth(0.9),
              5: pw.FlexColumnWidth(0.9),
            },
            data: data.sessions.take(20).map((item) {
              return [
                _formatDateTime(
                  DateTime.fromMillisecondsSinceEpoch(item.startedAtMillis),
                ),
                item.gameLabel,
                '${item.durationMinutes} min',
                item.correctAnswers.toString(),
                item.totalAttempts.toString(),
                item.mistakes.toString(),
              ];
            }).toList(),
          ),
        pw.NewPage(),
        pw.Text(
          'Guia rapida para interpretar este reporte',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        _guideBullet(
          'Puntaje por habilidad (0 a 100): valores altos indican mejor desempeno observado en las sesiones.',
        ),
        _guideBullet(
          'Tendencia: compara este periodo frente al anterior. "Mejora relevante" sugiere avance, "Descenso" requiere seguimiento.',
        ),
        _guideBullet(
          'Confianza: depende de la cantidad de sesiones por habilidad. Con baja evidencia, interpretar con cautela.',
        ),
        _guideBullet(
          'Error estimado: porcentaje aproximado de respuestas incorrectas en la habilidad.',
        ),
        _guideBullet(
          'Las metricas apoyan el seguimiento. No reemplazan la valoracion clinica profesional.',
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Referencia de interpretacion',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: const ['Indicador', 'Lectura sugerida'],
          headerStyle: _tableHeaderStyle(),
          cellStyle: _tableCellStyle,
          columnWidths: const {
            0: pw.FlexColumnWidth(1.5),
            1: pw.FlexColumnWidth(2.7),
          },
          data: const [
            [
              'Fortaleza consolidada',
              'Habilidad funcional en este periodo; mantener y generalizar.'
            ],
            [
              'En consolidacion',
              'Hay avance parcial; mantener practica guiada y reforzar.'
            ],
            [
              'Requiere apoyo prioritario',
              'Priorizar ejercicios dirigidos y seguimiento cercano.'
            ],
            [
              'Calidad de datos baja',
              'Menos de 4 sesiones: usar como referencia inicial, no conclusiva.'
            ],
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          'Contexto de juegos y habilidades',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: const ['Juego', 'Habilidades que trabaja', 'Como aporta'],
          headerStyle: _tableHeaderStyle(),
          cellStyle: _tableCellStyle,
          columnWidths: const {
            0: pw.FlexColumnWidth(1.2),
            1: pw.FlexColumnWidth(1.9),
            2: pw.FlexColumnWidth(2.6),
          },
          data: _buildGameContextRows(),
        ),
      ],
    ),
  );

  return doc.save();
}

class ReportPdfPreviewScreen extends StatelessWidget {
  const ReportPdfPreviewScreen({
    super.key,
    required this.data,
  });

  final ChildReportPdfData data;

  @override
  Widget build(BuildContext context) {
    final safeChildName =
        data.childName.trim().isEmpty ? 'nino' : data.childName.trim();
    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(data.generatedAtMillis);
    final filename =
        'reporte_${safeChildName.replaceAll(' ', '_')}_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}.pdf';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista previa del reporte'),
      ),
      body: PdfPreview(
        canDebug: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowSharing: true,
        allowPrinting: true,
        pdfFileName: filename,
        build: (format) => buildChildReportPdfBytes(data),
      ),
    );
  }
}

const pw.TextStyle _tableCellStyle = pw.TextStyle(
  fontSize: 8.1,
);

pw.TextStyle _tableHeaderStyle() {
  return pw.TextStyle(
    fontSize: 8.6,
    fontWeight: pw.FontWeight.bold,
  );
}

pw.Widget _tableNoRepeatHeader({
  required List<String> headers,
  required List<List<String>> rows,
  required Map<int, pw.TableColumnWidth> columnWidths,
}) {
  final headerRow = pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
    children: headers.map((header) {
      return pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(header, style: _tableHeaderStyle()),
      );
    }).toList(),
  );

  final bodyRows = rows.map((row) {
    return pw.TableRow(
      children: row.map((cell) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(cell, style: _tableCellStyle),
        );
      }).toList(),
    );
  }).toList();

  return pw.Table(
    border: const pw.TableBorder(
      left: pw.BorderSide(),
      right: pw.BorderSide(),
      top: pw.BorderSide(),
      bottom: pw.BorderSide(),
      horizontalInside: pw.BorderSide(),
      verticalInside: pw.BorderSide(),
    ),
    columnWidths: columnWidths,
    children: [headerRow, ...bodyRows],
  );
}

pw.Widget _guideBullet(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('- '),
        pw.Expanded(child: pw.Text(text)),
      ],
    ),
  );
}

pw.Widget _buildDailyUsageBars(Map<String, int> dailyMinutes) {
  final entries = dailyMinutes.entries.toList();
  if (entries.isEmpty) {
    return pw.Text('Sin datos diarios para graficar.');
  }
  final maxValue =
      entries.fold<int>(0, (max, item) => item.value > max ? item.value : max);

  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Grafica de barras: minutos por dia (ultimo bloque semanal)',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Escala: la barra mas larga representa $maxValue min.',
          style: const pw.TextStyle(fontSize: 8),
        ),
        pw.SizedBox(height: 6),
        ...entries.map((entry) {
          final ratio = maxValue <= 0 ? 0.0 : entry.value / maxValue;
          final width = ratio * 190.0;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 34,
                  child: pw.Text(
                    entry.key,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
                pw.Expanded(
                  child: pw.Container(
                    height: 10,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(3),
                      border:
                          pw.Border.all(color: PdfColors.grey300, width: .5),
                    ),
                    child: pw.Align(
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Container(
                        width: width < 2 ? 2 : width,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue500,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.SizedBox(
                  width: 30,
                  child: pw.Text(
                    '${entry.value} min',
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

pw.Widget _buildPeriodPieChart(Map<String, double> distribution) {
  final entries = distribution.entries.where((item) => item.value > 0).toList();
  if (entries.isEmpty) {
    return pw.Text('Sin datos por franja horaria para graficar.');
  }

  const palette = <PdfColor>[
    PdfColors.blue400,
    PdfColors.orange400,
    PdfColors.purple400,
    PdfColors.teal400,
  ];

  return pw.Container(
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 130,
          height: 130,
          child: pw.Chart(
            grid: pw.PieGrid(),
            datasets: [
              for (var i = 0; i < entries.length; i++)
                pw.PieDataSet(
                  value: entries[i].value,
                  color: palette[i % palette.length],
                  legendPosition: pw.PieLegendPosition.none,
                  innerRadius: 16,
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Grafica circular: distribucion de uso por franja horaria',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Rangos: Madrugada 00-05 | Manana 06-11 | Tarde 12-17 | Noche 18-23.',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 4),
              for (var i = 0; i < entries.length; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: 9,
                        height: 9,
                        decoration: pw.BoxDecoration(
                          color: palette[i % palette.length],
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Expanded(
                        child: pw.Text(
                          '${entries[i].key}: ${entries[i].value.toStringAsFixed(1)}%',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              pw.SizedBox(height: 2),
              pw.Text(
                _dominantPeriodMessage(entries),
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Map<String, double> _periodDistribution(Map<int, int> hourlyMinutes) {
  final buckets = <String, int>{
    'Madrugada': 0,
    'Manana': 0,
    'Tarde': 0,
    'Noche': 0,
  };

  for (final entry in hourlyMinutes.entries) {
    final hour = entry.key;
    final minutes = entry.value.clamp(0, 24 * 60);
    if (hour >= 6 && hour <= 11) {
      buckets['Manana'] = (buckets['Manana'] ?? 0) + minutes;
    } else if (hour >= 12 && hour <= 17) {
      buckets['Tarde'] = (buckets['Tarde'] ?? 0) + minutes;
    } else if (hour >= 18 && hour <= 23) {
      buckets['Noche'] = (buckets['Noche'] ?? 0) + minutes;
    } else {
      buckets['Madrugada'] = (buckets['Madrugada'] ?? 0) + minutes;
    }
  }

  final total = buckets.values.fold<int>(0, (sum, value) => sum + value);
  if (total <= 0) {
    return {
      'Madrugada': 0,
      'Manana': 0,
      'Tarde': 0,
      'Noche': 0,
    };
  }

  return {
    for (final entry in buckets.entries)
      entry.key: (entry.value * 100.0) / total,
  };
}

String _dominantPeriodMessage(List<MapEntry<String, double>> entries) {
  if (entries.isEmpty) return 'No hay una franja dominante.';
  final sorted = [...entries]..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.first;
  return 'Franja dominante: ${top.key} (${top.value.toStringAsFixed(1)}%).';
}

List<List<String>> _buildGameContextRows() {
  final rowsByGame = <String, ({List<String> skills, List<String> helps})>{};

  for (final skill in skillCatalog) {
    for (final link in skill.relatedGames) {
      final current = rowsByGame[link.gameKey];
      if (current == null) {
        rowsByGame[link.gameKey] = (
          skills: <String>[skill.title],
          helps: <String>[link.howItHelps],
        );
      } else {
        if (!current.skills.contains(skill.title)) {
          current.skills.add(skill.title);
        }
        if (!current.helps.contains(link.howItHelps)) {
          current.helps.add(link.howItHelps);
        }
      }
    }
  }

  final rows = <List<String>>[];
  for (final entry in rowsByGame.entries) {
    final gameKey = entry.key;
    final label = gameLabelByKey[gameKey] ?? gameKey;
    final skills = entry.value.skills.join(', ');
    final helps = _truncate(entry.value.helps.join(' / '), 140);
    rows.add([label, skills, helps]);
  }
  rows.sort((a, b) => a.first.compareTo(b.first));
  return rows;
}

String _truncate(String value, int maxChars) {
  final text = value.trim();
  if (text.length <= maxChars) return text;
  return '${text.substring(0, maxChars - 3)}...';
}

List<String> _buildExecutiveSummary({
  required List<ReportSkillMetric> skills,
  required List<ReportSkillMetric> strengths,
  required List<ReportSkillMetric> priorities,
  required int sessionsCount,
}) {
  if (sessionsCount <= 0) {
    return const [
      'No hay sesiones en el periodo evaluado.',
      'Aun no es posible construir un perfil de desempeno confiable.',
      'Se recomienda completar al menos 4 sesiones para una primera lectura.',
    ];
  }

  final lines = <String>[];
  if (strengths.isNotEmpty) {
    lines.add(
      'Fortalezas observadas: ${strengths.map((item) => item.title).join(', ')}.',
    );
  } else {
    lines.add('No se identifican fortalezas consolidadas en este periodo.');
  }

  if (priorities.isNotEmpty) {
    lines.add(
      'Areas que requieren apoyo: ${priorities.map((item) => item.title).join(', ')}.',
    );
  } else {
    lines.add('No se observan areas criticas (<60) en este periodo.');
  }

  final bestImprovement = _bestImprovement(skills);
  if (bestImprovement != null) {
    lines.add(
      'Mejor tendencia: ${bestImprovement.title} (${(bestImprovement.score - bestImprovement.previousScore).toStringAsFixed(0)} puntos).',
    );
  }

  final recommendation = priorities.isNotEmpty
      ? 'Priorizar ${priorities.first.title} en sesiones guiadas de 10 a 15 min, 4 o 5 dias por semana.'
      : 'Mantener frecuencia y reforzar variacion de actividades.';
  lines.add(recommendation);

  return lines;
}

List<String> _buildCaregiverRecommendations(
    List<ReportSkillMetric> priorities) {
  if (priorities.isEmpty) {
    return const [
      'Mantener una rutina de uso 4 o 5 dias por semana.',
      'Reforzar en casa con ejemplos cotidianos de comunicacion funcional.',
      'Registrar observaciones breves despues de cada sesion.',
    ];
  }
  final first = priorities.first;
  final firstSkill = skillById(first.id);
  final firstGame = firstSkill?.relatedGames.isNotEmpty == true
      ? firstSkill!.relatedGames.first.gameKey
      : '';
  final firstGameLabel = firstGame.isEmpty ? 'juego relacionado' : firstGame;

  return [
    'Dedicar 10 a 15 min diarios a ${first.title} con apoyo adulto.',
    'Practicar la habilidad en situaciones reales y con refuerzo positivo inmediato.',
    'Priorizar $firstGameLabel durante 2 semanas y comparar cambios.',
  ];
}

List<String> _buildTherapistSuggestions(List<ReportSkillMetric> priorities) {
  if (priorities.isEmpty) {
    return const [
      'Mantener el plan terapeutico actual y revisar avance mensual.',
      'Aumentar complejidad de forma progresiva sin reducir adherencia.',
    ];
  }
  final first = priorities.first;
  final second = priorities.length > 1 ? priorities[1] : null;
  return [
    'Focalizar la intervencion en ${first.title}.',
    if (second != null) 'Monitorear de forma conjunta ${second.title}.',
    'Revisar variabilidad de errores y necesidad de apoyos en contexto real.',
  ];
}

ReportSkillMetric? _bestImprovement(List<ReportSkillMetric> skills) {
  ReportSkillMetric? best;
  var bestDelta = 0.0;
  for (final item in skills) {
    if (item.previousScore < 0) continue;
    final delta = item.score - item.previousScore;
    if (delta > bestDelta) {
      bestDelta = delta;
      best = item;
    }
  }
  return best;
}

String _stateLabel(double score) {
  if (score >= 80) return 'Fortaleza consolidada';
  if (score >= 60) return 'En consolidacion';
  return 'Requiere apoyo prioritario';
}

String _trendLabel(double current, double previous) {
  if (previous < 0) return 'Sin linea base';
  final delta = current - previous;
  if (delta >= 8) return 'Mejora relevante';
  if (delta <= -8) return 'Descenso';
  return 'Estable';
}

String _confidenceLabel(int evidenceSessions) {
  if (evidenceSessions <= 3) return 'Baja evidencia';
  if (evidenceSessions <= 7) return 'Evidencia media';
  return 'Alta evidencia';
}

String _qualityNote(int sessionsCount) {
  if (sessionsCount < 4) {
    return 'Calidad de datos baja: interpretar con cautela (menos de 4 sesiones).';
  }
  if (sessionsCount < 8) {
    return 'Calidad de datos media: util para seguimiento inicial y ajuste temprano.';
  }
  return 'Calidad de datos alta: patron suficientemente consistente para seguimiento clinico.';
}

int _dominantHour(Map<int, int> hourlyMinutes) {
  var bestHour = -1;
  var bestValue = -1;
  for (final entry in hourlyMinutes.entries) {
    final hour = entry.key;
    final value = entry.value;
    if (value > bestValue) {
      bestValue = value;
      bestHour = hour;
    }
  }
  return bestHour;
}

String _formatHourLabel(int hour) {
  if (hour < 0 || hour > 23) return 'Sin datos';
  return '${hour.toString().padLeft(2, '0')}:00';
}

String _formatDateTime(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  final h = value.hour.toString().padLeft(2, '0');
  final min = value.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}
