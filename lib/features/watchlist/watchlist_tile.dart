// 관심 목록 한 행. 종목명 / 코드 · 시장 / 현재가 / 등락.
// 시세를 아직 못 받았으면 오른쪽을 스켈레톤으로 그린다.

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../models/quote.dart';
import '../../models/stock.dart';
import '../../theme/theme.dart';
import '../common/list_row.dart';

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
        // 글자 크기를 키운 기기에서는 행이 늘어나야 하므로 최소 높이로 둔다.
        constraints: const BoxConstraints(minHeight: kListRowHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dimens.space4),
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
                        fontSize: 15,
                        height: 20 / 15, // lh 20
                        letterSpacing: -0.2,
                        fontWeight: AppTypography.medium,
                      ),
                    ),
                    Text(
                      '${stock.symbol} · ${stock.market}',
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 11,
                        height: 16 / 11, // lh 16
                        letterSpacing: 0,
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
            fontSize: 15,
            height: 20 / 15, // lh 20
            letterSpacing: -0.2,
            fontWeight: AppTypography.medium,
          ),
        ),
        Text(
          Fmt.change(quote.change, quote.changeRate),
          style: TextStyle(
            color: changeColor,
            fontSize: 11,
            height: 16 / 11, // lh 16
            letterSpacing: 0,
            fontWeight: AppTypography.medium,
          ),
        ),
      ],
    );
  }
}

/// 시세를 기다리는 동안의 자리 표시. 시안의 두 막대 치수(64×16, 48×12)를 쓴다.
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
        bar(64, 16),
        const SizedBox(height: 2), // 시안 간격. Scale 토큰에 없다.
        bar(48, 12),
      ],
    );
  }
}
