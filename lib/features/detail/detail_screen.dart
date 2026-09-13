// 종목 상세. 헤더 / 현재가 / 기간 탭 / 캔들 차트 / 요약 카드 / 일별 시세 표.

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/stock_repository.dart';
import '../../models/daily_price.dart';
import '../../models/quote.dart';
import '../../models/stock.dart';
import '../../state/favorites.dart';
import '../../theme/theme.dart';
import '../common/empty_state.dart';
import 'candle_chart.dart';
import 'daily_price_table.dart';
import 'summary_card.dart';

/// 검색 / 관심 목록에서 상세로 들어가는 통로.
///
/// 돌아올 때까지 기다릴 수 있도록 `Future` 를 그대로 돌려준다.
/// (관심 화면은 이 화면에서 바뀐 관심 상태를 받아 시세를 다시 받는다)
Future<void> openDetail(
  BuildContext context, {
  required Stock stock,
  required StockRepository repo,
  required Favorites favorites,
}) {
  return Navigator.of(context).push(
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

  /// 헤더에 쓸 종목 정보. 검색 결과로 받은 값으로 먼저 그리고,
  /// 메타데이터 응답이 오면 거래소명이 정확한 값으로 바뀐다.
  late Stock _stock = widget.stock;

  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      await Future.wait([_loadMeta(), _loadQuote(), _loadPrices(_period)]);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 종목명·거래소명. 검색 자동완성의 값과 대개 같지만, 관심 목록에서 바로
  /// 들어온 경우까지 포함해 상세에서는 이 응답을 정본으로 쓴다.
  Future<void> _loadMeta() async {
    final stock = await widget.repo.stock(widget.stock.symbol);
    if (mounted) setState(() => _stock = stock);
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

  /// 실패하면 탭을 되돌린다. 새 탭이 켜진 채 이전 기간의 차트가 남아 있으면
  /// 화면이 거짓말을 하는 셈이라, 보여주는 데이터와 탭을 항상 붙여 둔다.
  Future<void> _changePeriod(ChartPeriod period) async {
    if (period == _period) return;
    final previous = _period;
    setState(() => _period = period);
    try {
      await _loadPrices(period);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _period = previous;
        _error = true;
      });
      _showLoadFailed();
    }
  }

  void _showLoadFailed() {
    final colors = context.colors;
    final dimens = context.dimens;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.surfaceOverlay,
          elevation: 0,
          margin: EdgeInsets.all(dimens.space4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dimens.radiusLg),
          ),
          content: Text(
            '시세를 불러오지 못했습니다',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              height: 18 / 13,
              fontWeight: AppTypography.bold,
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final quote = _quote;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(stock: _stock, favorites: widget.favorites),
            Divider(
              height: dimens.borderHairline,
              thickness: dimens.borderHairline,
              color: context.colors.borderSubtle,
            ),
            Expanded(child: _body(context, quote)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Quote? quote) {
    final dimens = context.dimens;

    // 시세를 못 받았으면 화면을 통째로 덮는다. 현재가와 요약 카드가 이 화면의
    // 본문이라, 그것만 빠진 채 차트만 남으면 왜 비었는지 알 수 없다.
    // 기간을 바꾸다 실패한 경우는 탭을 되돌리므로 여기까지 오지 않는다.
    if (_error && quote == null) {
      return EmptyState(
        icon: Icons.cloud_off,
        iconColor: context.colors.textDisabled,
        title: '종목 정보를 불러오지 못했습니다',
        description: '네트워크 상태를 확인한 뒤\n다시 시도해 주세요.',
        onRetry: _load,
      );
    }

    if (_loading && quote == null && _prices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        dimens.space4,
        dimens.space3,
        dimens.space4,
        dimens.space6,
      ),
      children: [
        if (quote != null) _PriceHeadline(quote: quote),
        SizedBox(height: dimens.space3),
        _PeriodTabs(current: _period, onChanged: _changePeriod),
        SizedBox(height: dimens.space4),
        CandleChart(prices: _prices),
        SizedBox(height: dimens.space4),
        if (quote != null) SummaryCards(quote: quote),
        SizedBox(height: dimens.space5),
        DailyPriceTable(prices: _prices),
      ],
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

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 좌우 여백을 버튼 안에 넣어 터치 영역을 48 로 넓힌다.
          // (아이콘 자체는 시안대로 화면 가장자리에서 16 떨어진다)
          _IconButton(
            icon: Icons.arrow_back,
            color: colors.textPrimary,
            tooltip: '뒤로',
            padding: EdgeInsets.only(left: dimens.space4, right: dimens.space3),
            onTap: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: dimens.space2),
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
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    '${stock.symbol} · ${stock.market}',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: AppTypography.regular,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListenableBuilder(
            listenable: favorites,
            builder: (context, _) {
              final isFavorite = favorites.contains(stock.symbol);
              return _IconButton(
                icon: isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite
                    ? colors.favoriteActive
                    : colors.favoriteInactive,
                tooltip: isFavorite ? '관심 해제' : '관심 등록',
                padding: EdgeInsets.only(
                  left: dimens.space3,
                  right: dimens.space4,
                ),
                onTap: () => favorites.toggle(stock),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 헤더의 아이콘 버튼. `IconButton` 은 최소 48x48 을 차지해서 헤더가
/// 시안보다 높아지므로, 여백을 직접 잡아 높이를 헤더에 맡긴다.
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.padding,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final EdgeInsets padding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: padding,
            child: Icon(icon, size: context.dimens.iconMd, color: color),
          ),
        ),
      ),
    );
  }
}

/// 현재가와 등락. 방향은 삼각형 기호가 나타내므로 등락액은 절대값으로 쓴다.
class _PriceHeadline extends StatelessWidget {
  const _PriceHeadline({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final (color, mark) = switch (quote.direction) {
      PriceDirection.up => (colors.priceUpText, '▲ '),
      PriceDirection.down => (colors.priceDownText, '▼ '),
      PriceDirection.flat => (colors.priceFlatText, ''),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          Fmt.price(quote.price),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 29,
            fontWeight: AppTypography.bold,
          ),
        ),
        SizedBox(width: dimens.space2),
        Text(
          '$mark${Fmt.price(quote.change.abs())} (${Fmt.rate(quote.changeRate)})',
          style: TextStyle(
            color: color,
            fontSize: 15,
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
        for (final (i, period) in ChartPeriod.values.indexed) ...[
          if (i > 0) SizedBox(width: dimens.space1),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              behavior: HitTestBehavior.opaque,
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: dimens.space1),
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
                    fontSize: 13,
                    height: 20 / 13,
                    fontWeight: period == current
                        ? AppTypography.medium
                        : AppTypography.regular,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
