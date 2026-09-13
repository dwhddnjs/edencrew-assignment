// 새로고침 아이콘. Material 의 sync/autorenew 는 화살촉이 삼각형이라
// 시안(모서리형 화살촉, 3시·9시 갭)과 다르다. 폰트에 없어서 직접 그린다.
// 좌표는 시안과 같은 24 뷰박스 기준이고, 선 굵기 2 · 둥근 끝/이음이다.

import 'package:flutter/material.dart';

class RefreshIcon extends StatelessWidget {
  const RefreshIcon({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _RefreshPainter(color)),
    );
  }
}

class _RefreshPainter extends CustomPainter {
  const _RefreshPainter(this.color);

  final Color color;

  /// 뷰박스 24 안에서 그림이 차지하는 폭(선 굵기 포함).
  static const _artwork = 20.0;

  /// 시안은 20 상자 안에 15.65 로 그려져 있다. (프레임의 78%)
  static const _ratio = 15.65 / 20;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width * _ratio / _artwork;
    const r = Radius.circular(9);
    const r2 = Radius.circular(9.75); // 화살촉으로 빠지는 끝부분은 살짝 완만하다
    const ccw = false;

    final path = Path()
      ..moveTo(21, 12)
      ..arcToPoint(const Offset(12, 3), radius: r, clockwise: ccw)
      ..arcToPoint(const Offset(5.26, 5.74), radius: r2, clockwise: ccw)
      ..lineTo(3, 8)
      ..moveTo(3, 3)
      ..lineTo(3, 8)
      ..lineTo(8, 8)
      ..moveTo(3, 12)
      ..arcToPoint(const Offset(12, 21), radius: r, clockwise: ccw)
      ..arcToPoint(const Offset(18.74, 18.26), radius: r2, clockwise: ccw)
      ..lineTo(21, 16)
      ..moveTo(21, 21)
      ..lineTo(21, 16)
      ..lineTo(16, 16);

    // 24 뷰박스의 가운데(12,12)를 상자 가운데에 맞춘다.
    final offset = size.width / 2 - 12 * k;
    canvas.save();
    canvas.translate(offset, offset);
    canvas.drawPath(
      path.transform(Matrix4.diagonal3Values(k, k, 1).storage),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RefreshPainter old) => old.color != color;
}
