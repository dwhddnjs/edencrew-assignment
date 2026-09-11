import 'package:edencrew_assignment_starter/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('시작 화면이 다크 테마로 렌더링된다', (tester) async {
    await tester.pumpWidget(const EdencrewApp());
    await tester.pump();

    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('관심 종목이 없으면 빈 상태를 보여주고 헤더와 탭 바는 남는다', (tester) async {
    await tester.pumpWidget(const EdencrewApp());
    await tester.pump();

    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
    // 헤더의 '관심' 과 탭 바의 '관심' 두 개.
    expect(find.text('관심'), findsNWidgets(2));
    expect(find.text('검색'), findsOneWidget);
    expect(find.text('가나다순'), findsOneWidget);
  });

  testWidgets('정렬 칩을 누르면 바텀시트가 열리고 선택이 반영된다', (tester) async {
    await tester.pumpWidget(const EdencrewApp());
    await tester.pump();

    await tester.tap(find.text('가나다순'));
    await tester.pumpAndSettle();

    expect(find.text('정렬'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('등락률순'));
    await tester.pumpAndSettle();

    expect(find.text('등락률순'), findsOneWidget);
    expect(find.text('가나다순'), findsNothing);
  });
}
