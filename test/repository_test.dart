import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:edencrew_assignment_starter/data/naver_api.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';

/// 요청 URI 를 기록하면서 mock 파일을 응답으로 돌려주는 가짜 클라이언트.
({StockRepository repo, List<Uri> calls}) build(String mockFile) {
  final calls = <Uri>[];
  final bytes = File('assets/mock/$mockFile').readAsBytesSync();

  final client = MockClient((req) async {
    calls.add(req.url);
    return http.Response.bytes(bytes, 200);
  });

  return (repo: StockRepository(api: NaverApi(client: client)), calls: calls);
}

void main() {
  test('관심종목이 비어 있으면 요청하지 않는다', () async {
    final t = build('realtime.json');

    expect(await t.repo.quotes([]), isEmpty);
    expect(t.calls, isEmpty);
  });

  test('검색어가 공백뿐이면 요청하지 않는다', () async {
    final t = build('autocomplete.json');

    expect(await t.repo.search('   '), isEmpty);
    expect(t.calls, isEmpty);
  });

  test('관심종목 여러 개를 요청 한 번으로 조회한다', () async {
    final t = build('realtime.json');

    final result = await t.repo.quotes(['005930', '000660']);

    expect(t.calls, hasLength(1));
    expect(
      t.calls.single.queryParameters['query'],
      'SERVICE_ITEM:005930,000660',
    );
    expect(result.keys, containsAll(['005930', '000660']));
  });

  test('검색은 국내 주식만 남긴다', () async {
    final t = build('autocomplete.json');

    final stocks = await t.repo.search('삼성');

    expect(stocks, isNotEmpty);
    expect(stocks.every((s) => s.symbol.length == 6), isTrue);
    expect(stocks.first.id, startsWith('domestic:'));
  });
}
