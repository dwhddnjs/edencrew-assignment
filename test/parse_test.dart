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

  test('자동완성: 지수 · 시장지표 항목의 null 필드에도 터지지 않는다', () {
    // 실제 응답. target 에 index, marketindicator 가 들어 있어서
    // nationCode 가 null 인 항목이 같이 온다.
    final json = {
      'query': '코스피',
      'items': [
        {
          'code': 'KOSPI',
          'name': '코스피',
          'typeName': null,
          'nationCode': null,
          'category': 'index',
        },
        {
          'code': '005930',
          'name': '삼성전자',
          'typeName': '코스피',
          'nationCode': 'KOR',
          'category': 'stock',
        },
      ],
    };

    final stocks = AutocompleteItemDto.listFromJson(
      json,
    ).where((e) => e.isDomesticStock).map((e) => e.toModel()).toList();

    expect(stocks.map((s) => s.symbol), ['005930']);
  });

  test('실시간 시세: 종목코드나 현재가가 빠진 항목은 건너뛰고 나머지는 살아남는다', () {
    final json = {
      'result': {
        'areas': [
          {
            'datas': [
              // 현재가가 없다. 0 으로 채우면 0 원 / -100% 가 그려진다.
              {
                'cd': '005930',
                'nv': null,
                'pcv': 10,
                'ov': 1,
                'hv': 1,
                'lv': 1,
                'aq': 1,
                'countOfListedStock': 1,
              },
              // 종목코드가 없다. 예전에는 여기서 목록 전체가 실패했다.
              {
                'cd': null,
                'nv': 100,
                'pcv': 100,
                'ov': 1,
                'hv': 1,
                'lv': 1,
                'aq': 1,
                'countOfListedStock': 1,
              },
              {
                'cd': '000660',
                'nv': 200,
                'pcv': 100,
                'ov': 1,
                'hv': 1,
                'lv': 1,
                'aq': 1,
                'countOfListedStock': 1,
              },
            ],
          },
        ],
      },
    };

    final quotes = {
      for (final d in RealtimeItemDto.listFromJson(json)) d.cd: d.toModel(),
    };

    // 쓸 수 없는 두 항목은 아예 빠진다. 화면에서는 스켈레톤으로 남는다.
    expect(quotes.keys, ['000660']);
    expect(quotes['000660']!.price, 200);
  });
}
