// 관심 목록 한 행. 종목명 / 코드 · 시장 / 현재가 / 등락.
// 시세를 아직 못 받았으면 오른쪽을 스켈레톤으로 그린다.

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/quote.dart';
import '../../models/stock.dart';
import '../../theme/theme.dart';

class WatchlistTile extends StatelessWidget {
  const WatchlistTile({
    super.key,
    required this.stock,
    required this.quote,
    this.onTap,
  });

  final Stock stock;

  /// null 이면 아직 시세를 받지 못한 상태다.
  final Quote? quote;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dimens.space4,
            vertical: dimens.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stock.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    SizedBox(height: dimens.space1),
                    Text(
                      '${stock.symbol} · ${stock.market}',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                        fontWeight: AppTypography.regular,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: dimens.space3),
              quote == null ? const _PriceSkeleton() : _Price(quote: quote!),
            ],
          ),
        ),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final changeColor = switch (quote.direction) {
      PriceDirection.up => colors.priceUpText,
      PriceDirection.down => colors.priceDownText,
      PriceDirection.flat => colors.priceFlatText,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Fmt.price(quote.price),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: AppTypography.bold,
          ),
        ),
        SizedBox(height: dimens.space1),
        Text(
          Fmt.change(quote.change, quote.changeRate),
          style: TextStyle(
            color: changeColor,
            fontSize: 12,
            fontWeight: AppTypography.medium,
          ),
        ),
      ],
    );
  }
}

/// 시세를 기다리는 동안의 자리 표시. 실제 값과 같은 높이를 차지해서
/// 시세가 도착해도 행이 흔들리지 않는다.
class _PriceSkeleton extends StatelessWidget {
  const _PriceSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.feedbackSkeleton,
        borderRadius: BorderRadius.circular(dimens.radiusSm),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        bar(80, 18),
        SizedBox(height: dimens.space1),
        bar(56, 12),
      ],
    );
  }
}
