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
    this.onRetry,
  });

  final IconData icon;
  final Color iconColor;
  final String title;

  /// 줄바꿈은 호출하는 쪽에서 `\n` 으로 넣는다. (시안의 두 줄 문구)
  final String description;

  /// 네트워크 실패로 이 상태를 보여줄 때만 준다. 시안의 빈 상태에는 없다.
  final VoidCallback? onRetry;

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
            Icon(icon, size: 40, color: iconColor),
            SizedBox(height: dimens.space3),
            Text(
              title,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 19,
                height: 22 / 19, // lh 22
                letterSpacing: -0.2,
                fontWeight: AppTypography.bold,
              ),
            ),
            SizedBox(height: dimens.space3),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 11,
                height: 14 / 11, // lh 14
                letterSpacing: 0,
                fontWeight: AppTypography.regular,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: dimens.space4),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: colors.accentDefault,
                ),
                child: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
