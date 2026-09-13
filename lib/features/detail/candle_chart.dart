// 캔들 차트. 패키지 없이 CustomPainter 로 그린다.
// 상승 몸통 chartLineUp, 하락 몸통 chartLineDown, 보합 몸통 chartLineFlat,
// 심지 chartBaseline.

import 'package:flutter/material.dart';

import '../../models/daily_price.dart';
import '../../theme/theme.dart';

class CandleChart extends StatelessWidget {
  const CandleChart({super.key, required this.prices});

  /// 최신이 앞인 순서(저장소가 주는 그대로). 그릴 때 뒤집어서 왼쪽이 과거다.
  final List<DailyPrice> prices;

  /// 시안의 차트 영역 높이.
  static const height = 200.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return SizedBox(
      height: height,
      // 고가/저가가 영역 끝에 붙지 않도록 시안만큼 위아래를 비워 둔다.
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dimens.space6),
        child: CustomPaint(
          size: Size.infinite,
          painter: _CandlePainter(
            prices: prices.reversed.toList(),
            up: colors.chartLineUp,
            down: colors.chartLineDown,
            flat: colors.chartLineFlat,
            wick: colors.chartBaseline,
          ),
        ),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({
    required this.prices,
    required this.up,
    required this.down,
    required this.flat,
    required this.wick,
  });

  /// 오래된 날짜가 앞.
  final List<DailyPrice> prices;
  final Color up;
  final Color down;

  /// 심지와 보합 몸통에 함께 쓴다.
  final Color flat;

  /// 고가 ~ 저가 선. 몸통보다 흐리다.
  final Color wick;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    // 기간 전체의 고가/저가로 y 범위를 잡는다.
    var lowest = prices.first.low;
    var highest = prices.first.high;
    for (final p in prices) {
      if (p.low < lowest) lowest = p.low;
      if (p.high > highest) highest = p.high;
    }
    // 전 구간이 같은 값이면 0으로 나누게 되므로 최소 폭을 준다.
    final span = (highest - lowest).clamp(1, 1 << 62);

    double y(int price) => size.height * (1 - (price - lowest) / span);

    final slot = size.width / prices.length;
    // 캔들 사이가 붙어 보이지 않도록 슬롯의 60%만 몸통으로 쓴다.
    final bodyWidth = (slot * 0.6).clamp(1.0, 12.0);
    final wickPaint = Paint()..color = wick;

    for (var i = 0; i < prices.length; i++) {
      final p = prices[i];
      final center = slot * (i + 0.5);

      // 심지: 고가 ~ 저가.
      canvas.drawRect(
        Rect.fromLTRB(center - 0.5, y(p.high), center + 0.5, y(p.low)),
        wickPaint,
      );

      // 몸통: 시가 ~ 종가. 보합이면 선으로만 남아 사라지므로 최소 높이를 준다.
      final top = y(p.close > p.open ? p.close : p.open);
      final bottom = y(p.close > p.open ? p.open : p.close);
      canvas.drawRect(
        Rect.fromLTRB(
          center - bodyWidth / 2,
          top,
          center + bodyWidth / 2,
          bottom - top < 1 ? top + 1 : bottom,
        ),
        Paint()
          ..color = p.close > p.open
              ? up
              : p.close < p.open
              ? down
              : flat,
      );
    }
  }

  @override
  bool shouldRepaint(_CandlePainter old) =>
      old.prices != prices ||
      old.up != up ||
      old.down != down ||
      old.flat != flat ||
      old.wick != wick;
}
