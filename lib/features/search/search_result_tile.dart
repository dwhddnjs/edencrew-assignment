// 검색 결과 한 행. 검색어 일치 부분 하이라이트 + 관심 등록 별.

import 'package:flutter/material.dart';

import '../../models/stock.dart';
import '../../theme/theme.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    super.key,
    required this.stock,
    required this.query,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.onTap,
  });

  final Stock stock;

  /// 종목명에서 이 부분을 `searchHighlight` 색으로 칠한다.
  final String query;

  final bool isFavorite;
  final VoidCallback onToggleFavorite;
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
          padding: EdgeInsets.only(
            left: dimens.space4,
            top: dimens.space3,
            bottom: dimens.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HighlightedName(name: stock.name, query: query),
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
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                iconSize: dimens.iconMd + dimens.space1,
                color: isFavorite
                    ? colors.favoriteActive
                    : colors.favoriteInactive,
                tooltip: isFavorite ? '관심 해제' : '관심 등록',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 검색어와 일치하는 구간만 색을 바꾼 종목명.
///
/// 종목코드로 검색하면 이름에 일치 구간이 없으므로 그대로 그린다.
class _HighlightedName extends StatelessWidget {
  const _HighlightedName({required this.name, required this.query});

  final String name;
  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final base = TextStyle(
      color: colors.textPrimary,
      fontSize: 16,
      fontWeight: AppTypography.medium,
    );

    final at = query.isEmpty
        ? -1
        : name.toLowerCase().indexOf(query.toLowerCase());

    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        style: base,
        children: at < 0
            ? [TextSpan(text: name)]
            : [
                TextSpan(text: name.substring(0, at)),
                TextSpan(
                  text: name.substring(at, at + query.length),
                  style: TextStyle(color: colors.searchHighlight),
                ),
                TextSpan(text: name.substring(at + query.length)),
              ],
      ),
    );
  }
}
