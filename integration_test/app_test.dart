// 시뮬레이터에서 실제 앱을 띄우고 실제 네이버 API 로 주요 흐름을 확인한다.
// 위젯 테스트(test/)는 목 응답을 쓰므로 여기서만 잡히는 문제가 있다.
//
//   flutter test integration_test/app_test.dart -d <device>

import 'package:edencrew_assignment_starter/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 실제 네트워크 응답을 기다린다. pumpAndSettle 은 응답을 기다려 주지 않는다.
Future<void> settle(WidgetTester tester, [int seconds = 12]) async {
  final deadline = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await settle(tester, 4);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('검색 -> 관심 등록 -> 관심 탭 -> 상세 전체 흐름', (tester) async {
    await tester.pumpWidget(const EdencrewApp());
    await settle(tester, 2);

    expect(find.text('관심 종목이 없습니다'), findsOneWidget);

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    // 지수 항목이 섞여 오는 검색어. 예외 없이 '결과 없음' 으로 끝나야 한다.
    await search(tester, '코스피');
    expect(find.text('검색 결과가 없습니다'), findsOneWidget);

    await search(tester, '삼성전자');
    expect(find.text('삼성전자'), findsWidgets);

    // 관심 등록 -> 토스트
    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    await settle(tester, 3);

    // 검색 탭에서 담은 종목의 시세가 관심 탭에서 채워져야 한다.
    await tester.tap(find.text('관심'));
    await settle(tester, 8);

    expect(find.text('관심 종목이 없습니다'), findsNothing);
    expect(find.text('시세를 불러오지 못했습니다'), findsNothing);
    // 현재가가 실제로 그려졌는지. 천 단위 구분자가 붙은 숫자를 찾는다.
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(w.data ?? ''),
      ),
      findsWidgets,
      reason: '관심 탭으로 옮겨 왔을 때 시세를 받아야 한다',
    );

    // 상세 진입
    await tester.tap(find.text('삼성전자').first);
    await settle(tester, 10);

    expect(find.text('005930 · 코스피'), findsOneWidget);
    expect(find.text('1개월'), findsOneWidget);
    expect(find.text('종목 정보를 불러오지 못했습니다'), findsNothing);

    // 로딩이 끝나기 전에 기간을 연달아 바꿔도 중복 요청 없이 그려져야 한다.
    await tester.tap(find.text('3개월'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('1년'));
    await settle(tester, 20);

    expect(find.text('종목 정보를 불러오지 못했습니다'), findsNothing);
    expect(find.text('거래량'), findsWidgets);
  });
}
