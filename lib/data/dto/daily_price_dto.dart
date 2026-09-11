// 일별 시세 HTML 파서. JSON 아님.
// 표 숫자 순서 = 종가, 전일비, 시가, 고가, 저가, 거래량
// 1페이지 = 10거래일. lastPage 도 같이 뽑는다.

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import '../../models/daily_price.dart';

/// 일별 시세 한 페이지(= 10거래일)의 파싱 결과.
class DailyPricePageDto {
  const DailyPricePageDto({required this.prices, required this.lastPage});

  /// 최신 날짜가 앞이다. (네이버 표 순서 그대로)
  final List<DailyPrice> prices;

  /// 이 종목의 마지막 페이지. 이보다 큰 페이지는 요청하지 않는다.
  final int lastPage;

  static final _digits = RegExp(r'[^0-9]');
  static final _date = RegExp(r'^(\d{4})\.(\d{2})\.(\d{2})$');
  static final _pageParam = RegExp(r'page=(\d+)');

  factory DailyPricePageDto.fromHtml(String body) {
    final doc = html.parse(body);
    final prices = <DailyPrice>[];

    for (final row in doc.querySelectorAll('tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length != 7) continue; // 구분선 / 헤더 행

      final date = _date.firstMatch(cells[0].text.trim());
      if (date == null) continue;

      prices.add(
        DailyPrice(
          date: '${date[1]}${date[2]}${date[3]}',
          close: _int(cells[1].text),
          change: _change(cells[2]),
          open: _int(cells[3].text),
          high: _int(cells[4].text),
          low: _int(cells[5].text),
          volume: _int(cells[6].text),
        ),
      );
    }

    return DailyPricePageDto(prices: prices, lastPage: _lastPage(doc));
  }

  /// "269,500" -> 269500. 공백과 개행이 섞여 있어 숫자만 남긴다.
  static int _int(String text) =>
      int.tryParse(text.replaceAll(_digits, '')) ?? 0;

  /// 전일비 칸은 크기만 숫자로 적혀 있고 방향은 아이콘 class 에 들어 있다.
  /// `bu_pup` 상승 / `bu_pdn` 하락 / `bu_pn` 보합.
  /// 방향 문구(`상승`/`하락`)는 한글이라 읽지 않는다. NaverApi 주석 참고.
  static int _change(Element cell) {
    final magnitude = _int(cell.text);
    final classes = cell.querySelector('em')?.className ?? '';
    if (classes.contains('bu_pd')) return -magnitude;
    if (classes.contains('bu_pu')) return magnitude;
    return 0;
  }

  /// 페이지 네비게이션의 `맨뒤` 링크에서 뽑는다.
  /// 페이지가 하나뿐이면 그 링크가 없으므로 보이는 번호 중 최대값을 쓴다.
  static int _lastPage(Document doc) {
    final last = doc.querySelector('td.pgRR a')?.attributes['href'] ?? '';
    final matched = _pageParam.firstMatch(last);
    if (matched != null) return int.parse(matched[1]!);

    final pages = doc
        .querySelectorAll('table.Nnavi a')
        .map((a) => _pageParam.firstMatch(a.attributes['href'] ?? ''))
        .whereType<RegExpMatch>()
        .map((m) => int.parse(m[1]!));
    return pages.isEmpty ? 1 : pages.reduce((a, b) => a > b ? a : b);
  }
}
