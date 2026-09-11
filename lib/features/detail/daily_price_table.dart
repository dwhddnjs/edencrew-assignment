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
            fontSize: 16,
            fontWeight: AppTypography.bold,
          ),
        ),
        SizedBox(height: dimens.space3),
        const _HeaderRow(),
        for (final p in prices) _Row(price: p),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final style = TextStyle(
      color: colors.textTertiary,
      fontSize: 12,
      fontWeight: AppTypography.regular,
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dimens.space2),
      child: Row(
        children: [
          Expanded(
            flex: DailyPriceTable._flex[0],
            child: Text('날짜', style: style),
          ),
          Expanded(
            flex: DailyPriceTable._flex[1],
            child: Text('종가', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: DailyPriceTable._flex[2],
            child: Text('등락', style: style, textAlign: TextAlign.right),
          ),
          Expanded(
            flex: DailyPriceTable._flex[3],
            child: Text('거래량', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.price});

  final DailyPrice price;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final changeColor = price.change > 0
        ? colors.priceUpText
        : price.change < 0
        ? colors.priceDownText
        : colors.priceFlatText;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: dimens.space3),
      child: Row(
        children: [
          Expanded(
            flex: DailyPriceTable._flex[0],
            child: Text(
              Fmt.date(price.date),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
          Expanded(
            flex: DailyPriceTable._flex[1],
            child: Text(
              Fmt.price(price.close),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
          Expanded(
            flex: DailyPriceTable._flex[2],
            child: Text(
              Fmt.signed(price.change),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: changeColor,
                fontSize: 14,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
          Expanded(
            flex: DailyPriceTable._flex[3],
            child: Text(
              Fmt.price(price.volume),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
