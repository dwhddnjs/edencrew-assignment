import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/data/dto/daily_price_dto.dart';
import 'package:edencrew_assignment_starter/data/naver_api.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/models/daily_price.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// 실제 응답과 같은 EUC-KR 바이트를 latin1 로 읽는다. (NaverApi 와 동일)
String get mockHtml =>
    latin1.decode(File('assets/mock/sise_day.html').readAsBytesSync());

/// 요청된 page 번호를 기록하면서 항상 같은 1페이지 HTML 을 돌려준다.
({StockRepository repo, List<int> pages}) build() {
  final pages = <int>[];
  final bytes = File('assets/mock/sise_day.html').readAsBytesSync();
  final client = MockClient((req) async {
    pages.add(int.parse(req.url.queryParameters['page']!));
    return http.Response.bytes(bytes, 200);
  });
  return (repo: StockRepository(api: NaverApi(client: client)), pages: pages);
}

void main() {
  group('HTML 파싱', () {
    late DailyPricePageDto page;
    setUpAll(() => page = DailyPricePageDto.fromHtml(mockHtml));

    test('한 페이지에 10거래일이 들어 있다', () {
      expect(page.prices.length, 10);
    });

    test('날짜는 yyyyMMdd 로 정규화된다', () {
      expect(page.prices.first.date, matches(RegExp(r'^\d{8}$')));
    });

    test('종가·시가·고가·저가·거래량 순서가 맞다', () {
      // 표의 숫자 순서는 종가, 전일비, 시가, 고가, 저가, 거래량.
      for (final p in page.prices) {
        expect(p.high, greaterThanOrEqualTo(p.low));
        expect(p.high, greaterThanOrEqualTo(p.close));
        expect(p.high, greaterThanOrEqualTo(p.open));
        expect(p.low, lessThanOrEqualTo(p.close));
        expect(p.volume, greaterThan(0));
      }
    });

    test('전일비는 아이콘 class 로 부호가 정해진다', () {
      // 목 데이터: 상승 4행, 하락 5행, 보합 1행.
      final signs = [for (final p in page.prices) p.change.sign];
      expect(signs.where((s) => s > 0).length, 4);
      expect(signs.where((s) => s < 0).length, 5);
      expect(signs.where((s) => s == 0).length, 1);
    });

    test('전일비로 계산한 등락률이 종가와 맞물린다', () {
      final p = page.prices.firstWhere((e) => e.change != 0);
      expect(p.changeRate, closeTo(p.change / (p.close - p.change), 1e-12));
    });

    test('lastPage 를 뽑는다', () {
      expect(page.lastPage, greaterThan(1));
    });

    test('빈 HTML 이어도 터지지 않는다', () {
      final empty = DailyPricePageDto.fromHtml('<html><body></body></html>');
      expect(empty.prices, isEmpty);
      expect(empty.lastPage, 1);
    });
  });

  group('페이지 캐시', () {
    test('1개월은 2페이지만 받는다', () async {
      final (:repo, :pages) = build();
      await repo.dailyPrices('005930', ChartPeriod.month1);
      expect(pages, [1, 2]);
    });

    test('같은 기간을 다시 요청하면 네트워크를 타지 않는다', () async {
      final (:repo, :pages) = build();
      await repo.dailyPrices('005930', ChartPeriod.month1);
      pages.clear();
      await repo.dailyPrices('005930', ChartPeriod.month1);
      expect(pages, isEmpty);
    });

    test('기간을 늘리면 모자란 페이지만 이어 받는다', () async {
      final (:repo, :pages) = build();
      await repo.dailyPrices('005930', ChartPeriod.month1); // 1,2
      pages.clear();
      await repo.dailyPrices('005930', ChartPeriod.month3); // 3..6
      expect(pages, [3, 4, 5, 6]);
    });

    test('기간을 줄이면 요청하지 않고 앞부분만 돌려준다', () async {
      final (:repo, :pages) = build();
      await repo.dailyPrices('005930', ChartPeriod.month3);
      pages.clear();
      final result = await repo.dailyPrices('005930', ChartPeriod.month1);
      expect(pages, isEmpty);
      expect(result.length, ChartPeriod.month1.days);
    });

    test('종목이 다르면 캐시를 공유하지 않는다', () async {
      final (:repo, :pages) = build();
      await repo.dailyPrices('005930', ChartPeriod.month1);
      pages.clear();
      await repo.dailyPrices('000660', ChartPeriod.month1);
      expect(pages, [1, 2]);
    });

    test('lastPage 를 넘는 페이지는 요청하지 않는다', () async {
      final pages = <int>[];
      // lastPage = 3 이고 3페이지까지만 존재하는 종목을 흉내 낸다.
      final body = mockHtml.replaceFirst(
        RegExp(r'<td class="pgRR">.*?</td>', dotAll: true),
        '<td class="pgRR"><a href="/item/sise_day.naver?code=x&page=3"></a></td>',
      );
      final client = MockClient((req) async {
        pages.add(int.parse(req.url.queryParameters['page']!));
        return http.Response.bytes(latin1.encode(body), 200);
      });
      final repo = StockRepository(api: NaverApi(client: client));

      await repo.dailyPrices('005930', ChartPeriod.year1); // 25페이지를 원한다
      expect(pages, [1, 2, 3]);
    });
  });
}
