// 숫자·날짜 포맷 한 곳에 모음. 3개 화면이 전부 씀.
// - 가격: 1,000 단위 콤마
// - 등락: 부호 포함 "-400 (-0.22%)"
// - 축약: 거래량 "29,113천", 시가총액 "1,063조"
// - 날짜: yyyyMMdd -> "MM.DD"

/// 화면에 보이는 숫자 표기는 전부 여기를 거친다.
abstract final class Fmt {
  /// "259500" -> "259,500". 음수 부호는 그대로 둔다.
  static String price(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );

  /// 등락액. 0이 아니면 부호를 붙인다. "+1,200" / "-400" / "0"
  static String signed(int v) => v > 0 ? '+${price(v)}' : price(v);

  /// 등락률. 0.0353 -> "+3.53%"
  static String rate(double v) {
    final pct = v * 100;
    final sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(2)}%';
  }

  /// 관심 목록 행에 쓰는 "-400 (-0.22%)" 형태.
  static String change(int amount, double changeRate) =>
      '${signed(amount)} (${rate(changeRate)})';

  /// 거래량은 천 단위로 줄인다. 29,113,000 -> "29,113천"
  static String volume(int v) =>
      v.abs() >= 1000 ? '${price(v ~/ 1000)}천' : price(v);

  /// 시가총액은 조 / 억 순으로 줄인다. 1.063e15 -> "1,063조"
  static String marketCap(int v) {
    if (v.abs() >= 1000000000000) return '${price(v ~/ 1000000000000)}조';
    if (v.abs() >= 100000000) return '${price(v ~/ 100000000)}억';
    return price(v);
  }

  /// "20260911" -> "09.11"
  static String date(String yyyyMMdd) =>
      '${yyyyMMdd.substring(4, 6)}.${yyyyMMdd.substring(6, 8)}';
}
