import '../../models/stock.dart';

/// 종목 메타데이터 응답. 화면의 "005930 · 코스피" 가 이 값.
class StockMetaDto {
  final String symbolCode;
  final String stockName;
  final String stockExchangeNameKor;

  const StockMetaDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  factory StockMetaDto.fromJson(Map<String, dynamic> json) {
    return StockMetaDto(
      symbolCode: json['symbolCode'] as String,
      stockName: json['stockName'] as String,
      stockExchangeNameKor: json['stockExchangeNameKor'] as String,
    );
  }

  Stock toModel() =>
      Stock(symbol: symbolCode, name: stockName, market: stockExchangeNameKor);
}
