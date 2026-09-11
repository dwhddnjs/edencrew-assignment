import 'dart:io';

import 'package:edencrew_assignment_starter/data/naver_api.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/features/detail/candle_chart.dart';
import 'package:edencrew_assignment_starter/features/detail/daily_price_table.dart';
import 'package:edencrew_assignment_starter/features/detail/summary_card.dart';
import 'package:edencrew_assignment_starter/features/detail/detail_screen.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/state/favorites.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');

/// 실시간 시세는 realtime.json, 일별 시세는 sise_day.html 을 돌려준다.
({Favorites favorites, List<Uri> calls, StockRepository repo}) backend() {
  final realtime = File('assets/mock/realtime.json').readAsBytesSync();
  final html = File('assets/mock/sise_day.html').readAsBytesSync();
  final calls = <Uri>[];

  final client = MockClient((req) async {
    calls.add(req.url);
    final isDaily = req.url.path.contains('sise_day');
    return http.Response.bytes(isDaily ? html : realtime, 200);
  });
  final repo = StockRepository(api: NaverApi(client: client));
  return (favorites: Favorites(repo: repo), calls: calls, repo: repo);
}

Future<List<Uri>> pumpDetail(WidgetTester tester) async {
  final b = backend();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: DetailScreen(stock: samsung, repo: b.repo, favorites: b.favorites),
    ),
  );
  await tester.pumpAndSettle();
  return b.calls;
}

List<int> pagesOf(List<Uri> calls) => [
  for (final u in calls)
    if (u.path.contains('sise_day')) int.parse(u.queryParameters['page']!),
];

void main() {
  testWidgets('헤더에 종목명과 코드 · 시장이 보인다', (tester) async {
    await pumpDetail(tester);

    expect(find.text('삼성전자'), findsOneWidget);
    expect(find.text('005930 · 코스피'), findsOneWidget);
  });

  testWidgets('현재가와 등락을 보여준다. 등락액은 부호 없이 방향 아이콘이 붙는다', (tester) async {
    await pumpDetail(tester);

    expect(find.text('259,500'), findsWidgets);
    expect(find.text('9,500 (-3.53%)'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_up), findsNothing);
  });

  testWidgets('요약 카드 5개를 축약 표기로 보여준다', (tester) async {
    await pumpDetail(tester);

    // '거래량' 은 표의 컬럼 헤더에도 있으므로 카드 안쪽으로 범위를 좁힌다.
    Finder inCards(String text) => find.descendant(
      of: find.byType(SummaryCards),
      matching: find.text(text),
    );

    for (final label in ['시가', '고가', '저가', '거래량', '시가총액']) {
      expect(inCards(label), findsOneWidget);
    }
    // 거래량·시가총액은 축약한다. (29,113천 / 1,063조 형태)
    expect(
      find.descendant(
        of: find.byType(SummaryCards),
        matching: find.textContaining('천'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SummaryCards),
        matching: find.textContaining('조'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('일별 시세 표에 날짜 MM.DD 와 부호 있는 등락이 나온다', (tester) async {
    await pumpDetail(tester);

    for (final column in ['날짜', '종가', '등락', '거래량']) {
      expect(
        find.descendant(
          of: find.byType(DailyPriceTable),
          matching: find.text(column),
        ),
        findsOneWidget,
      );
    }
    // 목 서버가 모든 page 에 같은 1페이지 HTML 을 돌려주므로 날짜가 겹친다.
    expect(find.text('09.11'), findsWidgets);
    expect(find.text('-9,500'), findsWidgets);
    expect(find.text('22,517,075'), findsWidgets);
  });

  testWidgets('첫 진입은 1개월 = 2페이지만 받는다', (tester) async {
    final calls = await pumpDetail(tester);
    expect(pagesOf(calls), [1, 2]);
  });

  testWidgets('기간 탭을 바꾸면 모자란 페이지만 이어 받는다', (tester) async {
    final calls = await pumpDetail(tester);
    calls.clear();

    await tester.tap(find.text('3개월'));
    await tester.pumpAndSettle();
    expect(pagesOf(calls), [3, 4, 5, 6]);

    // 되돌아가면 요청이 없어야 한다.
    calls.clear();
    await tester.tap(find.text('1개월'));
    await tester.pumpAndSettle();
    expect(pagesOf(calls), isEmpty);
  });

  testWidgets('헤더의 별로 관심 등록/해제가 된다', (tester) async {
    final b = backend();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: DetailScreen(
          stock: samsung,
          repo: b.repo,
          favorites: b.favorites,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();

    expect(b.favorites.contains('005930'), isTrue);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('일별 시세가 비어 있어도 차트가 터지지 않는다', (tester) async {
    // 상장 첫날 등 데이터가 비는 경우.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CandleChart(prices: [])),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
