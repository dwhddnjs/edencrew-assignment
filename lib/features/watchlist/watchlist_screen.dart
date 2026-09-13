// 관심 화면. 헤더(정렬 칩 · 새로고침) + 목록 / 빈 상태.
// 헤더와 하단 탭 바는 빈 상태에서도 그대로 남는다.

import 'package:flutter/material.dart';

import '../../data/stock_repository.dart';
import '../../state/favorites.dart';
import '../../theme/theme.dart';
import '../common/empty_state.dart';
import '../common/list_row.dart';
import '../common/refresh_icon.dart';
import '../detail/detail_screen.dart';
import 'sort_sheet.dart';
import 'watchlist_tile.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({
    super.key,
    required this.favorites,
    required this.repo,
  });

  final Favorites favorites;
  final StockRepository repo;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  @override
  void initState() {
    super.initState();
    // 검색 화면에서 추가한 종목의 시세는 여기 들어올 때 한 번에 받는다.
    widget.favorites.refresh();
  }

  Widget _body(BuildContext context) {
    final favorites = widget.favorites;

    if (favorites.isEmpty) {
      return EmptyState(
        icon: Icons.star_border,
        iconColor: context.colors.favoriteInactive,
        title: '관심 종목이 없습니다',
        description: '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
      );
    }

    // 한 번이라도 받아 둔 시세가 있으면 그걸 계속 보여준다. 갱신 한 번
    // 실패했다고 화면을 통째로 에러로 덮을 이유는 없다.
    if (favorites.hasError && favorites.hasNoQuotes) {
      return EmptyState(
        icon: Icons.cloud_off,
        iconColor: context.colors.textDisabled,
        title: '시세를 불러오지 못했습니다',
        description: '네트워크 상태를 확인한 뒤\n다시 시도해 주세요.',
        onRetry: favorites.refresh,
      );
    }

    return _List(favorites: favorites, repo: widget.repo);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: widget.favorites,
        builder: (context, _) => Column(
          children: [
            _Header(favorites: widget.favorites),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.favorites, required this.repo});

  final Favorites favorites;
  final StockRepository repo;

  @override
  Widget build(BuildContext context) {
    final items = favorites.items;

    return RefreshIndicator(
      onRefresh: favorites.refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        // 시안은 마지막 행 아래에도 구분선이 있다. (separated 는 사이에만 넣는다)
        itemBuilder: (context, i) => Divided(
          child: WatchlistTile(
            stock: items[i],
            quote: favorites.quoteOf(items[i].symbol),
            onTap: () => openDetail(
              context,
              stock: items[i],
              repo: repo,
              favorites: favorites,
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.favorites});

  final Favorites favorites;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return SizedBox(
      // 시안 헤더 높이 52. Scale 토큰에 없는 값이라 직접 쓴다.
      height: 52,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Row(
          children: [
            Text(
              '관심',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 19,
                height: 22 / 19, // lh 22
                letterSpacing: -0.2,
                fontWeight: AppTypography.bold,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () => showSortSheet(context, favorites),
              borderRadius: BorderRadius.circular(dimens.radiusSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    favorites.sortBy.label,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 18 / 13, // lh 18
                      letterSpacing: 0,
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  // 시안 화살표는 Material 의 arrow_downward(정사각형)보다
                  // 좁고 길다. south 가 시안과 같은 모양이다.
                  Icon(
                    Icons.south,
                    size: dimens.iconSm,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
            SizedBox(width: dimens.space4),
            // IconButton 은 M3 기본 minimumSize 40x40 을 갖고 있어서
            // padding·constraints 를 0 으로 줘도 상자가 20 보다 커진다.
            // 오른쪽 여백과 아이콘 간격이 16 을 넘어 보이던 원인.
            InkWell(
              onTap: favorites.isLoading ? null : favorites.refresh,
              borderRadius: BorderRadius.circular(dimens.radiusSm),
              child: RefreshIcon(
                size: dimens.iconMd,
                color: favorites.isLoading
                    ? colors.textDisabled
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
