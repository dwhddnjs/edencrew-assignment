// 일별 시세 표. 날짜 / 종가 / 등락 / 거래량.

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/daily_price.dart';
import '../../theme/theme.dart';

class DailyPriceTable extends StatelessWidget {
  const DailyPriceTable({super.key, required this.prices});

  final List<DailyPrice> prices;

  /// 컬럼 폭 비율. 시안의 각 컬럼 오른쪽 끝 위치(42% / 71% / 100%)에 맞췄다.
  /// 거래량이 가장 길어서(29,113,466) 등락과 함께 넓게 잡는다.
  static const _flex = [3, 4, 5, 5];

  /// 표의 모든 글자. 시안 텍스트 레이어가 11/16 이다.
  static const _fontSize = 11.0;
  static const _height = 16 / _fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일별 시세',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: AppTypography.bold,
          ),
        ),
        SizedBox(height: dimens.space1),
        const _HeaderRow(),
        for (final p in prices) _Row(price: p),
      ],
    );
  }
}

/// 표의 한 줄. 위쪽 구분선은 [DecoratedBox] 로 그려서 행 높이를 늘리지 않는다.
/// (시안의 행 간격이 32 인데 테두리가 높이를 먹으면 33 이 된다)
class _TableRow extends StatelessWidget {
  const _TableRow({required this.cells, this.divider = false});

  final List<Widget> cells;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider
            ? Border(
                top: BorderSide(
                  color: colors.borderSubtle,
                  width: dimens.borderHairline,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dimens.space2),
        child: Row(
          children: [
            for (final (i, cell) in cells.indexed)
              Expanded(flex: DailyPriceTable._flex[i], child: cell),
          ],
        ),
      ),
    );
  }
}

Widget _cell(String text, Color color, {bool right = true, bool bold = false}) {
  return Text(
    text,
    textAlign: right ? TextAlign.right : TextAlign.left,
    style: TextStyle(
      color: color,
      fontSize: DailyPriceTable._fontSize,
      height: DailyPriceTable._height,
      fontWeight: bold ? AppTypography.medium : AppTypography.regular,
    ),
  );
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final c = context.colors.textSecondary;
    return _TableRow(
      cells: [
        _cell('날짜', c, right: false),
        _cell('종가', c),
        _cell('등락', c),
        _cell('거래량', c),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.price});

  final DailyPrice price;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final changeColor = price.change > 0
        ? colors.priceUpText
        : price.change < 0
        ? colors.priceDownText
        : colors.priceFlatText;

    return _TableRow(
      divider: true,
      cells: [
        _cell(Fmt.date(price.date), colors.textSecondary, right: false),
        _cell(Fmt.price(price.close), colors.textPrimary),
        _cell(Fmt.signed(price.change), changeColor),
        _cell(Fmt.price(price.volume), colors.textSecondary),
      ],
    );
  }
}
