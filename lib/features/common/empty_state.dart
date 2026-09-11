// 빈 상태 공용 위젯. 관심 / 검색 / 검색결과 세 군데가 같은 형태를 쓴다.

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 아이콘 + 제목 + 설명을 세로 가운데에 놓는다.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  /// 줄바꿈은 호출하는 쪽에서 `\n` 으로 넣는다. (시안의 두 줄 문구)
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor),
            SizedBox(height: dimens.space4),
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: AppTypography.bold,
              ),
            ),
            SizedBox(height: dimens.space2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 13,
                fontWeight: AppTypography.regular,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
