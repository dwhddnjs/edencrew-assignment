// 관심 등록 / 해제 토스트. 아이콘 + 문구.

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 화면 하단에 등록/해제 결과를 알린다.
///
/// 시안(`04 · 검색 · 관심 등록 토스트` / `05 · 검색 · 관심 해제 토스트`) 대조:
/// 좌우 여백 space4, 탭 바와 12 띄움, 라운드 radiusLg, 배경 surfaceOverlay,
/// 좌우 안쪽 여백 space4, 아이콘 20, 문구 13 bold / lh 18.
///
/// 노출 시간(2초)과 사라지는 방식은 시안에 정의가 없어 직접 정했다.
/// 연속으로 별을 누르면 이전 토스트를 지우고 새로 띄운다. 큐에 쌓이면
/// 마지막으로 누른 상태와 화면의 문구가 어긋나기 때문이다.
void showFavoriteToast(BuildContext context, {required bool added}) {
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
        margin: EdgeInsets.fromLTRB(
          dimens.space4,
          0,
          dimens.space4,
          dimens.space3,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space4,
          // 시안 토스트 높이 46 = 아이콘 20 + 위아래 13. Scale 토큰에 없다.
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dimens.radiusLg),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              added ? Icons.star : Icons.star_border,
              size: dimens.iconMd,
              color: added ? colors.favoriteActive : colors.favoriteInactive,
            ),
            // 시안 아이콘-문구 간격 6. Scale 토큰에 없다.
            const SizedBox(width: 6),
            Text(
              added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                height: 18 / 13, // lh 18
                letterSpacing: 0,
                fontWeight: AppTypography.bold,
              ),
            ),
          ],
        ),
      ),
    );
}
