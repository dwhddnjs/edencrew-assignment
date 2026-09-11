// 관심 등록 / 해제 토스트. 아이콘 + 문구.

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 화면 하단에 등록/해제 결과를 알린다.
///
/// 시안(`04 · 관심 등록 토스트` / `05 · 관심 해제 토스트`) 대조로 정한 값:
/// 좌우 여백 space4, 좌우 안쪽 여백 space5, 라운드 radiusLg,
/// 아이콘-문구 간격 space3, 문구 15 medium.
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
        margin: EdgeInsets.all(dimens.space4),
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space5,
          vertical: dimens.space3,
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
            SizedBox(width: dimens.space3),
            Text(
              added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: AppTypography.medium,
              ),
            ),
          ],
        ),
      ),
    );
}
