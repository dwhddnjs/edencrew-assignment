// 종목 기본 정보. id는 "domestic:{symbol}" canonical 형태.
// symbol, name, market(거래소명) — 검색/관심/상세가 공통으로 씀.
class Stock {
  final String symbol;
  final String name;
  final String market;

  const Stock({required this.symbol, required this.name, required this.market});

  String get id => 'domestic:$symbol';
}
