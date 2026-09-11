// 관심 종목 목록 = 3개 화면이 공유하는 유일한 상태.
// ChangeNotifier 하나로 충분. 화면에서는 ListenableBuilder 로 구독.

import 'package:flutter/foundation.dart';

import '../data/stock_repository.dart';
import '../models/quote.dart';
import '../models/stock.dart';

enum SortBy {
  price('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const SortBy(this.label);

  /// 헤더 칩과 정렬 바텀시트에 그대로 쓰는 문구.
  final String label;
}

/// 관심 종목과 그 시세를 함께 들고 있는다.
///
/// 시세를 여기 두는 이유: `현재가순` / `등락률순` 정렬이 시세를 알아야 가능하고,
/// 관심 종목 전체를 한 번의 요청으로 받으므로 목록과 같은 곳에 있는 편이 자연스럽다.
class Favorites extends ChangeNotifier {
  Favorites({required StockRepository repo}) : _repo = repo;

  final StockRepository _repo;

  final List<Stock> _stocks = [];
  final Map<String, Quote> _quotes = {};

  /// 시안의 기본값이 `가나다순` 이다.
  SortBy _sortBy = SortBy.name;
  bool _loading = false;
  bool _error = false;

  SortBy get sortBy => _sortBy;
  bool get isLoading => _loading;
  bool get isEmpty => _stocks.isEmpty;

  /// 마지막 갱신이 실패했는지. 이전에 받아 둔 시세가 있으면 그건 그대로 쓴다.
  bool get hasError => _error;

  /// 시세를 한 건도 못 받은 상태. 이럴 때만 목록 대신 에러 화면을 띄운다.
  bool get hasNoQuotes => _quotes.isEmpty;

  /// 아직 시세를 받지 못했으면 null. 화면에서 스켈레톤으로 그린다.
  Quote? quoteOf(String symbol) => _quotes[symbol];

  bool contains(String symbol) => _stocks.any((s) => s.symbol == symbol);

  /// 정렬이 적용된 목록. 화면은 이것만 그리면 된다.
  ///
  /// 시세를 아직 못 받은 행은 비교할 값이 없으므로 항상 뒤로 보내고,
  /// 그 안에서는 가나다순으로 둔다. (시안에 정의가 없어 직접 정한 규칙)
  List<Stock> get items {
    final sorted = [..._stocks];
    if (_sortBy == SortBy.name) {
      sorted.sort((a, b) => a.name.compareTo(b.name));
      return sorted;
    }
    sorted.sort((a, b) {
      final qa = _quotes[a.symbol];
      final qb = _quotes[b.symbol];
      if (qa == null || qb == null) {
        if (qa == qb) return a.name.compareTo(b.name);
        return qa == null ? 1 : -1;
      }
      return _sortBy == SortBy.price
          ? qb.price.compareTo(qa.price)
          : qb.changeRate.compareTo(qa.changeRate);
    });
    return sorted;
  }

  /// 별 아이콘 토글. 등록됐으면 true 를 돌려주어 토스트 문구를 정하게 한다.
  ///
  /// 시세는 여기서 받지 않는다. 관심 화면에 들어올 때 한 번에 받는 편이
  /// 요청 수가 적고, 검색 화면에서는 어차피 시세를 쓰지 않는다.
  bool toggle(Stock stock) {
    if (contains(stock.symbol)) {
      _stocks.removeWhere((s) => s.symbol == stock.symbol);
      _quotes.remove(stock.symbol);
      notifyListeners();
      return false;
    }
    _stocks.add(stock);
    notifyListeners();
    return true;
  }

  void setSort(SortBy value) {
    if (_sortBy == value) return;
    _sortBy = value;
    notifyListeners();
  }

  /// 관심 종목 전체 시세를 한 번의 요청으로 다시 받는다.
  ///
  /// 실패는 삼키지 않고 `hasError` 로 남긴다. 화면이 스켈레톤을 영원히
  /// 띄운 채 멈춰 있으면 사용자는 로딩 중인지 실패인지 알 수 없다.
  Future<void> refresh() async {
    if (_stocks.isEmpty || _loading) return;
    _loading = true;
    _error = false;
    notifyListeners();
    try {
      _quotes.addAll(await _repo.quotes([for (final s in _stocks) s.symbol]));
    } catch (_) {
      _error = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
