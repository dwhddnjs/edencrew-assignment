// 요약 카드. 시가 / 고가 / 저가 / 거래량 / 시가총액.

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/quote.dart';
import '../../theme/theme.dart';

/// 시안대로 위 3개(시가·고가·저가), 아래 2개(거래량·시가총액)로 나눈다.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;

    return Column(
      children: [
        Row(
          children: [
            _Card(label: '시가', value: Fmt.price(quote.open)),
            SizedBox(width: dimens.space2),
            _Card(label: '고가', value: Fmt.price(quote.high)),
            SizedBox(width: dimens.space2),
            _Card(label: '저가', value: Fmt.price(quote.low)),
          ],
        ),
        SizedBox(height: dimens.space2),
        Row(
          children: [
            _Card(label: '거래량', value: Fmt.volume(quote.volume)),
            SizedBox(width: dimens.space2),
            _Card(label: '시가총액', value: Fmt.marketCap(quote.marketCap)),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space3,
          vertical: dimens.space2,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(dimens.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                height: 16 / 11,
                fontWeight: AppTypography.regular,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  height: 24 / 15,
                  fontWeight: AppTypography.medium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
