import '../models/daily_price.dart';
import '../models/quote.dart';
import '../models/stock.dart';
import 'dto/autocomplete_dto.dart';
import 'dto/daily_price_dto.dart';
import 'dto/realtime_dto.dart';
import 'dto/stock_meta_dto.dart';
import 'naver_api.dart';

/// 화면이 사용하는 창구. NaverApi 와 DTO 를 조합해 모델을 돌려준다.
/// 화면은 네이버 응답 구조를 전혀 모른다.
class StockRepository {
  StockRepository({NaverApi? api}) : _api = api ?? NaverApi();

  final NaverApi _api;

  /// 검색어로 국내 주식만 찾는다.
  Future<List<Stock>> search(String query) async {
    if (query.trim().isEmpty) return const [];

    final json = await _api.autocomplete(query.trim());
    return AutocompleteItemDto.listFromJson(
      json,
    ).where((e) => e.isDomesticStock).map((e) => e.toModel()).toList();
  }

  /// 여러 종목의 시세를 한 번의 요청으로 받아 symbol 로 찾을 수 있게 정리한다.
  Future<Map<String, Quote>> quotes(List<String> symbols) async {
    if (symbols.isEmpty) return const {};

    final json = await _api.realtime(symbols);
    return {
      for (final dto in RealtimeItemDto.listFromJson(json))
        dto.cd: dto.toModel(),
    };
  }

  /// 단일 종목의 시세. 상세 화면용.
  Future<Quote?> quote(String symbol) async {
    final result = await quotes([symbol]);
    return result[symbol];
  }

  /// 종목명, 거래소명.
  Future<Stock> stock(String symbol) async {
    final json = await _api.stockMeta(symbol);
    return StockMetaDto.fromJson(json).toModel();
  }

  /// 종목별 일별 시세 캐시. 받은 페이지는 다시 받지 않는다.
  final Map<String, _DailyPriceCache> _daily = {};

  /// 기간 탭이 요구하는 거래일 수만큼만 페이지를 이어서 받는다.
  ///
  /// - 이미 받아 둔 페이지는 재사용하고 모자란 페이지만 추가로 요청한다.
  ///   (`1개월` -> `1년` 으로 옮기면 3~25 페이지만 받는다)
  /// - `lastPage` 를 넘는 페이지는 요청하지 않는다.
  Future<List<DailyPrice>> dailyPrices(
    String symbol,
    ChartPeriod period,
  ) async {
    final cache = _daily.putIfAbsent(symbol, _DailyPriceCache.new);

    while (cache.fetchedPages < period.pages) {
      final next = cache.fetchedPages + 1;
      if (next > cache.lastPage) break;

      final page = DailyPricePageDto.fromHtml(
        await _api.dailyPrice(symbol, next),
      );
      cache.prices.addAll(page.prices);
      cache.fetchedPages = next;
      cache.lastPage = page.lastPage;

      // 상장 폐지 등으로 빈 페이지가 오면 더 받아도 소용없다.
      if (page.prices.isEmpty) break;
    }

    return cache.prices.take(period.days).toList();
  }

  void dispose() => _api.close();
}

class _DailyPriceCache {
  final List<DailyPrice> prices = [];

  /// 1페이지부터 여기까지 연속으로 받아 둔 상태다.
  int fetchedPages = 0;

  /// 첫 응답을 받기 전에는 알 수 없으므로 일단 열어 둔다.
  int lastPage = 1 << 30;
}
