// 종목 상세. 헤더 / 현재가 / 기간 탭 / 캔들 차트 / 요약 카드 / 일별 시세 표.

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/stock_repository.dart';
import '../../models/daily_price.dart';
import '../../models/quote.dart';
import '../../models/stock.dart';
import '../../state/favorites.dart';
import '../../theme/theme.dart';
import 'candle_chart.dart';
import 'daily_price_table.dart';
import 'summary_card.dart';

/// 검색 / 관심 목록에서 상세로 들어가는 통로.
void openDetail(
  BuildContext context, {
  required Stock stock,
  required StockRepository repo,
  required Favorites favorites,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          DetailScreen(stock: stock, repo: repo, favorites: favorites),
    ),
  );
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.stock,
    required this.repo,
    required this.favorites,
  });

  final Stock stock;
  final StockRepository repo;
  final Favorites favorites;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  ChartPeriod _period = ChartPeriod.month1;
  Quote? _quote;
  List<DailyPrice> _prices = const [];

  @override
  void initState() {
    super.initState();
    _loadQuote();
    _loadPrices(_period);
  }

  Future<void> _loadQuote() async {
    final quote = await widget.repo.quote(widget.stock.symbol);
    if (mounted) setState(() => _quote = quote);
  }

  /// 기간을 바꿀 때마다 부른다. 이미 받아 둔 페이지는 저장소가 재사용하므로
  /// 여기서는 캐시를 신경 쓰지 않아도 된다.
  Future<void> _loadPrices(ChartPeriod period) async {
    final prices = await widget.repo.dailyPrices(widget.stock.symbol, period);
    if (mounted && period == _period) setState(() => _prices = prices);
  }

  void _changePeriod(ChartPeriod period) {
    if (period == _period) return;
    setState(() => _period = period);
    _loadPrices(period);
  }

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final quote = _quote;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(stock: widget.stock, favorites: widget.favorites),
            Divider(
              height: dimens.borderHairline,
              thickness: dimens.borderHairline,
              color: context.colors.borderSubtle,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  dimens.space4,
                  dimens.space4,
                  dimens.space4,
                  dimens.space6,
                ),
                children: [
                  if (quote != null) _PriceHeadline(quote: quote),
                  SizedBox(height: dimens.space4),
                  _PeriodTabs(current: _period, onChanged: _changePeriod),
                  SizedBox(height: dimens.space4),
                  CandleChart(prices: _prices),
                  SizedBox(height: dimens.space5),
                  if (quote != null) SummaryCards(quote: quote),
                  SizedBox(height: dimens.space6),
                  DailyPriceTable(prices: _prices),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stock, required this.favorites});

  final Stock stock;
  final Favorites favorites;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space2,
        vertical: dimens.space2,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            iconSize: dimens.iconMd + dimens.space1,
            color: colors.textPrimary,
            tooltip: '뒤로',
          ),
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
                    fontSize: 17,
                    fontWeight: AppTypography.bold,
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
          ListenableBuilder(
            listenable: favorites,
            builder: (context, _) {
              final isFavorite = favorites.contains(stock.symbol);
              return IconButton(
                onPressed: () => favorites.toggle(stock),
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                iconSize: dimens.iconMd + dimens.space2,
                color: isFavorite
                    ? colors.favoriteActive
                    : colors.favoriteInactive,
                tooltip: isFavorite ? '관심 해제' : '관심 등록',
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 현재가와 등락. 방향은 아이콘이 나타내므로 등락액은 절대값으로 쓴다.
class _PriceHeadline extends StatelessWidget {
  const _PriceHeadline({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final (color, icon) = switch (quote.direction) {
      PriceDirection.up => (colors.priceUpText, Icons.arrow_drop_up),
      PriceDirection.down => (colors.priceDownText, Icons.arrow_drop_down),
      PriceDirection.flat => (colors.priceFlatText, null),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          Fmt.price(quote.price),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 32,
            fontWeight: AppTypography.bold,
          ),
        ),
        SizedBox(width: dimens.space2),
        if (icon != null) Icon(icon, size: dimens.iconMd + 8, color: color),
        Text(
          '${Fmt.price(quote.change.abs())} (${Fmt.rate(quote.changeRate)})',
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: AppTypography.medium,
          ),
        ),
      ],
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.current, required this.onChanged});

  final ChartPeriod current;
  final ValueChanged<ChartPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Row(
      children: [
        for (final period in ChartPeriod.values)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              behavior: HitTestBehavior.opaque,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: dimens.space2),
                decoration: BoxDecoration(
                  color: period == current ? colors.accentBg : null,
                  borderRadius: BorderRadius.circular(dimens.radiusMd),
                ),
                child: Text(
                  period.label,
                  style: TextStyle(
                    color: period == current
                        ? colors.accentDefault
                        : colors.textSecondary,
                    fontSize: 14,
                    fontWeight: period == current
                        ? AppTypography.medium
                        : AppTypography.regular,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
