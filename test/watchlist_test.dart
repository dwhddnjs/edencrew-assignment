import 'dart:io';

import 'package:edencrew_assignment_starter/app.dart';
import 'package:edencrew_assignment_starter/data/naver_api.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/state/favorites.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
const hynix = Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피');

/// 목 파일에 없는 종목이라 시세가 채워지지 않는다 = 스켈레톤 대상.
const kakao = Stock(symbol: '035720', name: '카카오', market: '코스피');

/// 네트워크를 타지 않는 앱 셸을 띄운다.
Future<Favorites> pumpShell(
  WidgetTester tester,
  List<Stock> stocks, {
  SortBy sort = SortBy.name,
}) async {
  final bytes = File('assets/mock/realtime.json').readAsBytesSync();
  final client = MockClient((_) async => http.Response.bytes(bytes, 200));
  final repo = StockRepository(api: NaverApi(client: client));
  final favorites = Favorites(repo: repo);
  for (final s in stocks) {
    favorites.toggle(s);
  }
  favorites.setSort(sort);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: HomeShell(favorites: favorites, repo: repo),
    ),
  );
  await tester.pumpAndSettle();
  return favorites;
}

Color colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  const colors = AppColors.dark();

  testWidgets('행에 종목명 · 코드 · 시장 · 현재가 · 등락이 모두 보인다', (tester) async {
    await pumpShell(tester, [samsung]);

    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.text('005930 · 코스피'), findsOneWidget);
    expect(find.text('259,500'), findsOneWidget);
    expect(find.text('-9,500 (-3.53%)'), findsOneWidget);
  });

  testWidgets('하락은 파랑, 상승은 빨강, 보합은 회색', (tester) async {
    // 목 데이터는 둘 다 하락이므로 상승/보합은 Quote 색 규칙으로 따로 확인한다.
    await pumpShell(tester, [samsung]);
    expect(colorOf(tester, '-9,500 (-3.53%)'), colors.priceDownText);

    expect(colors.priceUpText, isNot(colors.priceDownText));
    expect(colors.priceFlatText, isNot(colors.priceDownText));
  });

  testWidgets('시세가 없는 행은 등락 대신 스켈레톤을 그린다', (tester) async {
    await pumpShell(tester, [samsung, kakao]);

    expect(find.text('카카오'), findsOneWidget);
    // 카카오는 목 응답에 없어 가격 텍스트가 아예 없다.
    expect(find.text('0'), findsNothing);
    expect(find.text('0 (0.00%)'), findsNothing);
    // 삼성전자 행은 정상적으로 채워진다.
    expect(find.text('259,500'), findsOneWidget);
  });

  testWidgets('정렬 시트에서 고르면 칩 문구와 체크 위치가 바뀐다', (tester) async {
    // 목 데이터가 두 종목뿐이라 세 기준의 결과 순서가 우연히 같다.
    // 순서 자체는 favorites_test 가 검증하고, 여기서는 화면 반영만 본다.
    await pumpShell(tester, [samsung, hynix]);

    expect(find.text('가나다순'), findsOneWidget);

    await tester.tap(find.text('가나다순'));
    await tester.pumpAndSettle();
    // 시트가 열리면 헤더 칩과 시트 항목에 '가나다순' 이 둘 다 있다.
    expect(find.text('정렬'), findsOneWidget);
    expect(find.text('가나다순'), findsNWidgets(2));

    await tester.tap(find.text('현재가순'));
    await tester.pumpAndSettle();

    expect(find.text('현재가순'), findsOneWidget);
    expect(find.text('가나다순'), findsNothing);

    // 다시 열면 체크가 '현재가순' 으로 옮겨가 있다.
    await tester.tap(find.text('현재가순'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('새로고침 버튼이 시세를 다시 받는다', (tester) async {
    final favorites = await pumpShell(tester, [samsung]);
    expect(favorites.quoteOf('005930'), isNotNull);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(find.text('259,500'), findsOneWidget);
  });
}
