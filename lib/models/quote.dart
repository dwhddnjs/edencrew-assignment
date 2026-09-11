// 시세 모델. realtime 응답에서 만듦.
// price, prevClose, open/high/low, volume, listedShares
// 등락액 = price - prevClose, 등락률 = (price - prevClose) / prevClose
// 시가총액 = price * listedShares
// 상승/하락/보합 판별도 여기서 (UI가 색만 고르게).

enum PriceDirection { up, down, flat }

class Quote {
  final String symbol;
  final int price;
  final int prevClose;
  final int open;
  final int high;
  final int low;
  final int volume;
  final int listedShares;

  const Quote({
    required this.symbol,
    required this.price,
    required this.prevClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.listedShares,
  });

  /// 등락액. 음수면 하락.
  int get change => price - prevClose;

  /// 등락률. 0.0353 = 3.53%.
  double get changeRate => prevClose == 0 ? 0 : change / prevClose;

  /// 시가총액.
  int get marketCap => price * listedShares;

  /// 상승 / 하락 / 보합.
  PriceDirection get direction {
    if (price > prevClose) return PriceDirection.up;
    if (price < prevClose) return PriceDirection.down;
    return PriceDirection.flat;
  }
}
