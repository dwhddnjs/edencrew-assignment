// 일별 시세 한 행. date(yyyyMMdd), close, open, high, low, volume.
// 차트 캔들과 일별 시세 표가 같이 씀.

class DailyPrice {
  final String date;
  final int close;

  /// 전일비. 표의 `등락` 열이 이 값이다.
  ///
  /// 인접한 행의 종가 차이로도 구할 수 있지만, 기간의 마지막 행은
  /// 그 앞 행이 없어 계산이 불가능하다. HTML 에 이미 들어있는 값을
  /// 그대로 읽는 편이 간단하고 빠지는 행도 없다.
  final int change;

  final int open;
  final int high;
  final int low;
  final int volume;

  const DailyPrice({
    required this.date,
    required this.close,
    required this.change,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });

  /// 등락률. 전일 종가 = close - change.
  double get changeRate {
    final prevClose = close - change;
    return prevClose == 0 ? 0 : change / prevClose;
  }
}

/// 상세 화면의 기간 탭.
enum ChartPeriod {
  month1('1개월', 20),
  month3('3개월', 60),
  month6('6개월', 120),
  year1('1년', 245);

  const ChartPeriod(this.label, this.days);

  final String label;

  /// 대략적인 거래일 수. 1페이지 = 10거래일이므로 여기서 페이지 수가 나온다.
  final int days;

  int get pages => (days / 10).ceil();
}
