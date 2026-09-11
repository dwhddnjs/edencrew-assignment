// 일별 시세 한 행. date(yyyyMMdd), close, open, high, low, volume.
// 차트 캔들과 일별 시세 표가 같이 씀.

class DailyPrice {
  final String date;
  final int close;
  final int open;
  final int high;
  final int low;
  final int volume;

  const DailyPrice({
    required this.date,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });
}
