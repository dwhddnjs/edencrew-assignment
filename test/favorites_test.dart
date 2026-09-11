import 'dart:io';

import 'package:edencrew_assignment_starter/data/naver_api.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/stock.dart';
import 'package:edencrew_assignment_starter/state/favorites.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// realtime.json 은 005930 / 000660 / 035420 세 종목을 담고 있다.
Favorites build({List<Uri>? calls}) {
  final bytes = File('assets/mock/realtime.json').readAsBytesSync();
  final client = MockClient((req) async {
    calls?.add(req.url);
    return http.Response.bytes(bytes, 200);
  });
  return Favorites(
    repo: StockRepository(api: NaverApi(client: client)),
  );
}

const samsung = Stock(symbol: '005930', name: '삼성전자', market: '코스피');
const hynix = Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피');

void main() {
  test('토글은 등록 true / 해제 false 를 돌려준다', () {
    final f = build();
    expect(f.isEmpty, isTrue);
    expect(f.toggle(samsung), isTrue);
    expect(f.contains('005930'), isTrue);
    expect(f.toggle(samsung), isFalse);
    expect(f.isEmpty, isTrue);
  });

  test('관심 종목 전체를 한 번의 요청으로 받는다', () async {
    final calls = <Uri>[];
    final f = build(calls: calls)..toggle(samsung);
    calls.clear();

    f.toggle(hynix);
    await f.refresh();

    expect(calls.length, 1);
    expect(calls.single.queryParameters['query'], 'SERVICE_ITEM:005930,000660');
  });

  test('시세를 받기 전에는 quoteOf 가 null (스켈레톤)', () async {
    final f = build()..toggle(samsung);
    expect(f.quoteOf('005930'), isNull);
    await f.refresh();
    expect(f.quoteOf('005930'), isNotNull);
  });

  test('가나다순은 시세 없이도 동작한다', () {
    final f = build()
      ..toggle(samsung)
      ..toggle(hynix)
      ..setSort(SortBy.name);
    expect([for (final s in f.items) s.name], ['SK하이닉스', '삼성전자']);
  });

  test('현재가순은 내림차순, 시세 없는 행은 뒤로', () async {
    final f = build()..toggle(samsung);
    await f.refresh();
    // 시세에 없는 종목이라 quote 가 채워지지 않는다.
    f.toggle(const Stock(symbol: '999999', name: '없는종목', market: '코스피'));

    expect(f.items.first.symbol, '005930');
    expect(f.items.last.symbol, '999999');
  });

  test('빈 목록이면 요청하지 않는다', () async {
    final calls = <Uri>[];
    await build(calls: calls).refresh();
    expect(calls, isEmpty);
  });
}
