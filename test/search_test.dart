import 'dart:io';

import 'package:edencrew_assignment_starter/app.dart';
import 'package:edencrew_assignment_starter/data/naver_api.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/state/favorites.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 자동완성 목 응답을 돌려주는 셸을 검색 탭에서 시작한 상태로 띄운다.
Future<Favorites> pumpSearch(
  WidgetTester tester, {
  String mockFile = 'autocomplete.json',
}) async {
  final bytes = File('assets/mock/$mockFile').readAsBytesSync();
  final client = MockClient((_) async => http.Response.bytes(bytes, 200));
  final repo = StockRepository(api: NaverApi(client: client));
  final favorites = Favorites(repo: repo);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: HomeShell(favorites: favorites, repo: repo),
    ),
  );
  await tester.tap(find.text('검색'));
  await tester.pumpAndSettle();
  return favorites;
}

/// 디바운스(300ms)가 지난 뒤 결과가 그려질 때까지 기다린다.
Future<void> type(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('검색어 입력 전에는 초기 빈 상태를 보여준다', (tester) async {
    await pumpSearch(tester);

    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    expect(find.text('종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.'), findsOneWidget);
  });

  testWidgets('입력은 디바운스 뒤에 한 번만 요청한다', (tester) async {
    final calls = <Uri>[];
    final bytes = File('assets/mock/autocomplete.json').readAsBytesSync();
    final client = MockClient((req) async {
      calls.add(req.url);
      return http.Response.bytes(bytes, 200);
    });
    final repo = StockRepository(api: NaverApi(client: client));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomeShell(
          favorites: Favorites(repo: repo),
          repo: repo,
        ),
      ),
    );
    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    // 한 글자씩 빠르게 입력한다.
    for (final q in ['삼', '삼성', '삼성전']) {
      await tester.enterText(find.byType(TextField), q);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(calls.length, 1);
    expect(calls.single.queryParameters['q'], '삼성전');
  });

  testWidgets('결과 행에 종목명·코드·시장과 별이 보인다', (tester) async {
    await pumpSearch(tester);
    await type(tester, '삼성');

    expect(find.text('005930 · 코스피'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsWidgets);
  });

  testWidgets('검색어와 일치하는 부분만 searchHighlight 색으로 칠한다', (tester) async {
    await pumpSearch(tester);
    await type(tester, '삼성');

    const colors = AppColors.dark();
    final name = tester.widget<Text>(
      find.byWidgetPredicate(
        (w) => w is Text && w.textSpan?.toPlainText() == '삼성전자',
      ),
    );
    final spans = (name.textSpan! as TextSpan).children!.cast<TextSpan>();

    expect(spans[0].text, '');
    expect(spans[1].text, '삼성');
    expect(spans[1].style?.color, colors.searchHighlight);
    expect(spans[2].text, '전자');
    expect(spans[2].style?.color, isNull); // 기본 스타일(textPrimary) 상속
  });

  testWidgets('별을 누르면 관심에 즉시 반영되고 토스트가 뜬다', (tester) async {
    final favorites = await pumpSearch(tester);
    await type(tester, '삼성');

    await tester.tap(find.byIcon(Icons.star_border).first);
    await tester.pump();

    expect(favorites.contains('005930'), isTrue);
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsWidgets); // 채워진 별로 바뀐다

    await tester.tap(find.byIcon(Icons.star).first);
    await tester.pump();

    expect(favorites.contains('005930'), isFalse);
    expect(find.text('관심이 해제되었습니다'), findsOneWidget);
  });

  testWidgets('결과가 없으면 검색어를 그대로 넣은 문구를 보여준다', (tester) async {
    await pumpSearch(tester, mockFile: 'autocomplete_empty.json');
    await type(tester, 'ㄱㄴㄷ');

    expect(find.text('검색 결과가 없습니다'), findsOneWidget);
    expect(find.text("'ㄱㄴㄷ'와\n일치하는 검색 결과를 찾지 못했습니다."), findsOneWidget);
  });

  testWidgets('입력을 지우면 다시 초기 상태로 돌아간다', (tester) async {
    await pumpSearch(tester);
    await type(tester, '삼성');
    expect(find.text('005930 · 코스피'), findsOneWidget);

    await tester.tap(find.byTooltip('지우기'));
    await tester.pumpAndSettle();

    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
    expect(find.text('005930 · 코스피'), findsNothing);
  });
}
