// 정렬 바텀시트. 선택된 기준에 체크 표시.

import 'package:flutter/material.dart';

import '../../state/favorites.dart';
import '../../theme/theme.dart';

/// 정렬 기준을 고르는 바텀시트를 띄운다. 고르면 즉시 반영하고 닫는다.
///
/// 시안(`01 · 관심_sort`) 대조로 정한 값:
/// 배경 surfaceOverlay, 위쪽 라운드 16, 좌우 여백 space6,
/// 제목 19 bold / lh 26, 항목 행 높이 rowMinHeight(56), 항목 15 / lh 20.
Future<void> showSortSheet(BuildContext context, Favorites favorites) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _SortSheet(favorites: favorites),
  );
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.favorites});

  final Favorites favorites;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        // 시안 라운드 16. Scale 토큰에 없는 값이라 직접 쓴다.
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                dimens.space6,
                dimens.space5,
                dimens.space6,
                dimens.space5,
              ),
              child: Text(
                '정렬',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 19,
                  height: 26 / 19, // lh 26
                  letterSpacing: -0.2,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            for (final option in SortBy.values)
              _SortOption(
                label: option.label,
                selected: favorites.sortBy == option,
                onTap: () {
                  favorites.setSort(option);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: dimens.rowMinHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dimens.space6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? colors.textPrimary : colors.textSecondary,
                    fontSize: 15,
                    height: 20 / 15, // lh 20
                    letterSpacing: 0,
                    fontWeight: selected
                        ? AppTypography.medium
                        : AppTypography.regular,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check,
                  size: dimens.iconMd,
                  color: colors.textPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
