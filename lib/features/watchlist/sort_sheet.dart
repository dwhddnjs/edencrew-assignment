// 정렬 바텀시트. 선택된 기준에 체크 표시.

import 'package:flutter/material.dart';

import '../../state/favorites.dart';
import '../../theme/theme.dart';

/// 정렬 기준을 고르는 바텀시트를 띄운다. 고르면 즉시 반영하고 닫는다.
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
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(dimens.radiusLg),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                dimens.space5,
                dimens.space5,
                dimens.space5,
                dimens.space3,
              ),
              child: Text(
                '정렬',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
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
            SizedBox(height: dimens.space4),
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
        height: dimens.rowMinHeight + dimens.space2,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dimens.space5),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
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
