import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/localization/digits.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/entities/bmi_models.dart';

class GrowthPoint {
  const GrowthPoint({required this.ageMonths, required this.bmi});

  final int ageMonths;
  final double bmi;
}

/// Value at [z] SD from the LMS parameters (used for every WHO indicator).
double bmiAtZ(Lms lms, double z) => lms.l == 0
    ? lms.m * math.exp(lms.s * z)
    : lms.m * math.pow(1 + lms.l * lms.s * z, 1 / lms.l).toDouble();

const referenceCurves = [-2.0, -1.0, 0.0, 1.0, 2.0];

/// P2-1 (ages 5–19): the person's BMI on the WHO 2007 BMI-for-age curves.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.reference,
    required this.sex,
    required this.points,
  });

  final BmiForAgeReference reference;
  final Sex sex;
  final List<GrowthPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ages = points.map((p) => p.ageMonths);
    final from = math.max(61, ages.reduce(math.min) - 12);
    final to = math.min(228, ages.reduce(math.max) + 12);

    return ReferenceChart(
      chartKey: const ValueKey('growth-chart'),
      curves: {
        for (final z in referenceCurves)
          z: [
            for (var m = from; m <= to; m++)
              if (reference.lookup(sex, m) case final lms?)
                Offset(m.toDouble(), bmiAtZ(lms, z)),
          ],
      },
      points: [for (final p in points) Offset(p.ageMonths.toDouble(), p.bmi)],
      xFrom: from.toDouble(),
      xTo: to.toDouble(),
      xStep: 12,
      xLabel: (months) => context.digits(months ~/ 12),
      legend: l10n.growthChartLegend,
      semanticLabel: l10n.growthChartSemantic(context.digits(points.length)),
    );
  }
}

/// WHO reference curves (−2…+2 SD, normal band shaded) with the person's
/// measurements. Clinical palette only; no colour carries a judgement.
class ReferenceChart extends StatelessWidget {
  const ReferenceChart({
    super.key,
    required this.curves,
    required this.points,
    required this.xFrom,
    required this.xTo,
    required this.xStep,
    required this.xLabel,
    required this.legend,
    required this.semanticLabel,
    this.chartKey,
    this.shadeFrom = -2,
    this.shadeTo = 1,
  });

  final Map<double, List<Offset>> curves;
  final List<Offset> points;
  final double xFrom;
  final double xTo;
  final double xStep;
  final String Function(double x) xLabel;
  final String legend;
  final String semanticLabel;
  final Key? chartKey;

  /// SD lines bounding the lightly shaded band.
  final double shadeFrom;
  final double shadeTo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.4,
            child: CustomPaint(
              key: chartKey,
              painter: _ChartPainter(
                lines: curves,
                points: points,
                xFrom: xFrom,
                xTo: xTo,
                xStep: xStep,
                xLabel: xLabel,
                shadeFrom: shadeFrom,
                shadeTo: shadeTo,
              ),
            ),
          ),
          const SizedBox(height: EpSpace.s2),
          Text(legend, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// A "nice" grid step (1, 2, 5 × 10ⁿ) for about five lines.
double niceStep(double range) {
  final raw = range / 5;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  for (final f in [1.0, 2.0, 5.0, 10.0]) {
    if (raw <= f * magnitude) return f * magnitude;
  }
  return 10 * magnitude;
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.lines,
    required this.points,
    required this.xFrom,
    required this.xTo,
    required this.xStep,
    required this.xLabel,
    required this.shadeFrom,
    required this.shadeTo,
  });

  final Map<double, List<Offset>> lines;
  final List<Offset> points;
  final double xFrom;
  final double xTo;
  final double xStep;
  final String Function(double x) xLabel;
  final double shadeFrom;
  final double shadeTo;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const bottom = 20.0;
    final plot = Rect.fromLTRB(left, 8, size.width - 8, size.height - bottom);

    final allY = [
      for (final l in lines.values) ...l.map((o) => o.dy),
      ...points.map((p) => p.dy),
    ];
    if (allY.isEmpty || xTo <= xFrom) return;
    final rawMin = allY.reduce(math.min), rawMax = allY.reduce(math.max);
    final yStep = niceStep(math.max(rawMax - rawMin, 1));
    final minY = (rawMin / yStep).floor() * yStep;
    final maxY = (rawMax / yStep).ceil() * yStep;

    Offset map(Offset v) => Offset(
      plot.left + (v.dx - xFrom) / (xTo - xFrom) * plot.width,
      plot.bottom - (v.dy - minY) / (maxY - minY) * plot.height,
    );

    final low = lines[shadeFrom] ?? const [];
    final high = lines[shadeTo] ?? const [];
    if (low.isNotEmpty && high.isNotEmpty) {
      final band = Path()..moveTo(map(low.first).dx, map(low.first).dy);
      for (final o in low) {
        band.lineTo(map(o).dx, map(o).dy);
      }
      for (final o in high.reversed) {
        band.lineTo(map(o).dx, map(o).dy);
      }
      band.close();
      canvas.drawPath(band, Paint()..color = EpColors.clinicalTint);
    }

    final grid = Paint()
      ..color = EpColors.clinicalLine
      ..strokeWidth = 1;
    final text = TextPainter(textDirection: TextDirection.ltr);
    void label(String s, Offset at) {
      text.text = TextSpan(
        text: s,
        style: const TextStyle(fontSize: 10, color: EpColors.clinicalText),
      );
      text.layout();
      text.paint(canvas, at - Offset(text.width / 2, 0));
    }

    for (var x = (xFrom / xStep).ceil() * xStep; x <= xTo; x += xStep) {
      final px = map(Offset(x, minY)).dx;
      canvas.drawLine(Offset(px, plot.top), Offset(px, plot.bottom), grid);
      label(xLabel(x), Offset(px, plot.bottom + 4));
    }
    for (var y = minY; y <= maxY + 1e-9; y += yStep) {
      final py = map(Offset(xFrom, y)).dy;
      canvas.drawLine(Offset(plot.left, py), Offset(plot.right, py), grid);
      label(
        y % 1 == 0 ? y.toStringAsFixed(0) : y.toStringAsFixed(1),
        Offset(left / 2, py - 6),
      );
    }

    for (final entry in lines.entries) {
      final path = Path();
      for (var i = 0; i < entry.value.length; i++) {
        final p = map(entry.value[i]);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = entry.key == 0 ? 2 : 1
          ..color = entry.key == 0 ? EpColors.clinicalStrong : EpColors.band3,
      );
    }

    final sorted = [...points]..sort((a, b) => a.dx.compareTo(b.dx));
    final trail = Path();
    for (var i = 0; i < sorted.length; i++) {
      final p = map(sorted[i]);
      i == 0 ? trail.moveTo(p.dx, p.dy) : trail.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      trail,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = EpColors.n900,
    );
    for (final p in sorted) {
      canvas.drawCircle(map(p), 4, Paint()..color = EpColors.n900);
      canvas.drawCircle(map(p), 2, Paint()..color = EpColors.n0);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.points != points || old.lines != lines;
}
