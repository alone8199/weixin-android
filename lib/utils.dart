import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

const List<Color> _avatarPalette = [
  Color(0xFF07C160),
  Color(0xFF3B82F6),
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFF14B8A6),
  Color(0xFFEC4899),
  Color(0xFF0EA5E9),
  Color(0xFF84CC16),
  Color(0xFFF97316),
];

Color colorFromName(String name) {
  if (name.isEmpty) return _avatarPalette.first;
  return _avatarPalette[name.hashCode.abs() % _avatarPalette.length];
}

Widget gradientAvatar(String name, {double size = 44}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [colorFromName(name), colorFromName(name + 'x')],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text(
        (name.isNotEmpty) ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: size * 0.42,
        ),
      ),
    ),
  );
}

/// 生成一张渐变 PNG 的 base64 data URL（用于发送图片，避免引入额外依赖）
Future<String> makeGradientImageDataUrl([int? hue]) async {
  final h = hue ?? Random().nextInt(360);
  final h2 = (h + 50) % 360;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()
    ..shader = ui.Gradient.linear(
      Offset.zero,
      const Offset(220, 220),
      [
        HSLColor.fromAHSL(1, h.toDouble(), 0.65, 0.55).toColor(),
        HSLColor.fromAHSL(1, h2.toDouble(), 0.65, 0.45).toColor(),
      ],
    );
  canvas.drawRect(const Rect.fromLTWH(0, 0, 220, 220), paint);
  for (var i = 0; i < 5; i++) {
    final r = Random().nextDouble() * 60 + 18;
    canvas.drawCircle(
      Offset(Random().nextDouble() * 220, Random().nextDouble() * 220),
      r,
      Paint()
        ..color = HSLColor.fromAHSL(1, Random().nextInt(360).toDouble(), 0.8, 0.7)
            .toColor()
            .withOpacity(0.3),
    );
  }
  final pic = recorder.endRecording();
  final img = await pic.toImage(220, 220);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final b64 = base64Encode(bytes!.buffer.asUint8List());
  return 'data:image/png;base64,$b64';
}

LinearGradient gradientFromHue(int hue) {
  final h2 = (hue + 50) % 360;
  return LinearGradient(
    colors: [
      HSLColor.fromAHSL(1, hue.toDouble(), 0.7, 0.62).toColor(),
      HSLColor.fromAHSL(1, h2.toDouble(), 0.7, 0.48).toColor(),
    ],
  );
}

String fmtTime(int ts) {
  if (ts == 0) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  final now = DateTime.now();
  if (d.year == now.year &&
      d.month == now.month &&
      d.day == now.day) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  if (d.year == now.year) return '${d.month}月${d.day}日';
  return '${d.year}年${d.month}月${d.day}日';
}

String fmtFull(int ts) {
  if (ts == 0) return '';
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  return '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
