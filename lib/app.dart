// MaterialApp + AppTheme 적용, 하단 탭 바(관심/검색) 셸.

import 'package:flutter/material.dart';

import 'data/stock_repository.dart';
import 'features/search/search_screen.dart';
import 'features/watchlist/watchlist_screen.dart';
import 'state/favorites.dart';
import 'theme/theme.dart';

class EdencrewApp extends StatefulWidget {
  const EdencrewApp({super.key});

  @override
  State<EdencrewApp> createState() => _EdencrewAppState();
}

class _EdencrewAppState extends State<EdencrewApp> {
  /// 앱 전체가 저장소 하나를 공유한다. 일별 시세 페이지 캐시가
  /// 여기 붙어 있어서, 상세 화면을 다시 열어도 받아 둔 페이지를 재사용한다.
  final StockRepository _repo = StockRepository();
  late final Favorites _favorites = Favorites(repo: _repo);

  @override
  void dispose() {
    _favorites.dispose();
    _repo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '이든크루 평가 과제',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: HomeShell(favorites: _favorites, repo: _repo),
    );
  }
}

/// 하단 탭 바와 두 화면을 들고 있는 셸.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.favorites, required this.repo});

  final Favorites favorites;
  final StockRepository repo;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack 이라 탭을 오가도 각 화면의 스크롤과 입력이 유지된다.
      body: IndexedStack(
        index: _tab,
        children: [
          WatchlistScreen(favorites: widget.favorites),
          SearchScreen(repo: widget.repo, favorites: widget.favorites),
        ],
      ),
      bottomNavigationBar: _TabBar(
        current: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onChanged});

  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: dimens.tabBarHeight,
          child: Row(
            children: [
              _TabItem(
                icon: Icons.star,
                inactiveIcon: Icons.star_border,
                label: '관심',
                selected: current == 0,
                onTap: () => onChanged(0),
              ),
              _TabItem(
                icon: Icons.search,
                inactiveIcon: Icons.search,
                label: '검색',
                selected: current == 1,
                onTap: () => onChanged(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.inactiveIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;

  /// 시안에서 비활성 관심 탭은 속이 빈 별이다.
  final IconData inactiveIcon;

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final color = selected ? colors.navActive : colors.navInactive;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? icon : inactiveIcon,
              size: dimens.iconMd + dimens.space1,
              color: color,
            ),
            SizedBox(height: dimens.space1),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected
                    ? AppTypography.medium
                    : AppTypography.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
