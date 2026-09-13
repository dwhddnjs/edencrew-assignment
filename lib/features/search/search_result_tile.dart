// 검색 결과 한 행. 검색어 일치 부분 하이라이트 + 관심 등록 별.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/stock.dart';
import '../../theme/theme.dart';
import '../common/list_row.dart';

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
        // 글자 크기를 키운 기기에서는 행이 늘어나야 하므로 최소 높이로 둔다.
        constraints: const BoxConstraints(minHeight: kListRowHeight),
        child: Padding(
          // 오른쪽은 별의 탭 상자가 여백까지 먹는다. (아래 주석)
          padding: EdgeInsets.only(
            left: dimens.space4,
            right: dimens.space1,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HighlightedName(name: stock.name, query: query),
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
              // 아이콘은 시안 자리(오른쪽 여백 16 + 24 칸의 가운데)에 두고,
              // 누를 수 있는 상자만 48 으로 넓힌다.
              IconButton(
                onPressed: onToggleFavorite,
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                iconSize: dimens.iconMd + dimens.space1,
                color: isFavorite
                    ? colors.favoriteActive
                    : colors.favoriteInactive,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
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
      fontSize: 15,
      height: 20 / 15, // lh 20
      letterSpacing: 0,
      fontWeight: AppTypography.medium,
    );

    // 소문자로 바꾼 문자열에서 찾은 위치라, 길이가 달라지는 문자가 섞이면
    // 원본에서 끝 위치가 넘칠 수 있다. (예: 'İ' 는 소문자로 두 글자)
    final at = query.isEmpty
        ? -1
        : name.toLowerCase().indexOf(query.toLowerCase());
    final end = math.min(at + query.length, name.length);

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
                  text: name.substring(at, end),
                  style: TextStyle(color: colors.searchHighlight),
                ),
                TextSpan(text: name.substring(end)),
              ],
      ),
    );
  }
}
