// 관심 / 검색 목록이 함께 쓰는 행 치수와 구분선.

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 시안 행 높이 60 = 본문 59 + 구분선 1. Scale 토큰에 없는 값이라 직접 쓴다.
const double kListRowHeight = 59;

/// 행 아래에 실선을 하나 둔다. (시안의 구분선)
class Divided extends StatelessWidget {
  const Divided({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // DecoratedBox 는 자리를 차지하지 않는다. 구분선 1 을 행 높이에 더하려면
    // Container 여야 한다. (BoxDecoration.padding 이 테두리 두께를 준다)
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: context.colors.borderSubtle,
            width: context.dimens.borderHairline,
          ),
        ),
      ),
      child: child,
    );
  }
}
