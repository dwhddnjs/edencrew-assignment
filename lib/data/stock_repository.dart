import '../models/quote.dart';
import '../models/stock.dart';
import 'dto/autocomplete_dto.dart';
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

  void dispose() => _api.close();
}
