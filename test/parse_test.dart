import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:edencrew_assignment_starter/data/dto/autocomplete_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/realtime_dto.dart';
import 'package:edencrew_assignment_starter/data/dto/stock_meta_dto.dart';
import 'package:edencrew_assignment_starter/models/quote.dart';

/// assets/mock 의 응답 파일을 그대로 읽는다.
/// lossy: realtime 응답은 EUC-KR 이라 한글이 깨진다. 숫자만 쓰므로 허용.
Map<String, dynamic> load(String name, {bool lossy = false}) {
  final bytes = File('assets/mock/$name').readAsBytesSync();
  return jsonDecode(utf8.decode(bytes, allowMalformed: lossy))
      as Map<String, dynamic>;
}

void main() {
  test('자동완성: 파싱 + 국내주식 필터 + Stock 변환', () {
    final stocks = AutocompleteItemDto.listFromJson(
      load('autocomplete.json'),
    ).where((e) => e.isDomesticStock).map((e) => e.toModel()).toList();

    expect(stocks, isNotEmpty);
    expect(stocks.every((s) => s.symbol.length == 6), isTrue);

    final samsung = stocks.firstWhere((s) => s.symbol == '005930');
    expect(samsung.name, '삼성전자');
    expect(samsung.market, '코스피');
    expect(samsung.id, 'domestic:005930');
  });

  test('메타: 파싱 + Stock 변환', () {
    final stock = StockMetaDto.fromJson(load('meta.json')).toModel();

    expect(stock.symbol, '005930');
    expect(stock.name, '삼성전자');
    expect(stock.market, '코스피');
  });

  test('실시간: 중첩 평탄화 + symbol 맵 + 계산 getter', () {
    final quotes = {
      for (final d in RealtimeItemDto.listFromJson(
        load('realtime.json', lossy: true),
      ))
        d.cd: d.toModel(),
    };

    final q = quotes['005930']!;
    expect(q.price, 259500);
    expect(q.prevClose, 269000);
    expect(q.open, 258000);
    expect(q.high, 261500);
    expect(q.low, 256500);
    expect(q.volume, 13938673);

    expect(q.change, -9500);
    expect(q.direction, PriceDirection.down);
    expect(q.changeRate, closeTo(-0.0353, 0.0001));
    expect(q.marketCap, 259500 * 5846278608);
  });

  test('전일종가 0이면 등락률은 0 (0으로 나누기 방지)', () {
    const q = Quote(
      symbol: '000000',
      price: 100,
      prevClose: 0,
      open: 0,
      high: 0,
      low: 0,
      volume: 0,
      listedShares: 0,
    );

    expect(q.changeRate, 0);
    expect(q.direction, PriceDirection.up);
  });
}
