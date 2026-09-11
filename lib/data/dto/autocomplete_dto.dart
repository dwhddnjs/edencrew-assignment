// 검색 자동완성 응답 DTO.
// 필드: code, name, typeCode, typeName, url, nationCode, category
// 필터: 국내 주식만 + 6자리 종목코드만 -> Stock 으로 변환
import '../../models/stock.dart';

/// 검색 자동완성 응답의 항목 하나. 서버 필드명 그대로 받는다.
class AutocompleteItemDto {
  final String code;
  final String name;
  final String typeName;
  final String nationCode;
  final String category;

  const AutocompleteItemDto({
    required this.code,
    required this.name,
    required this.typeName,
    required this.nationCode,
    required this.category,
  });

  factory AutocompleteItemDto.fromJson(Map<String, dynamic> json) {
    return AutocompleteItemDto(
      code: json['code'] as String,
      name: json['name'] as String,
      typeName: json['typeName'] as String,
      nationCode: json['nationCode'] as String,
      category: json['category'] as String,
    );
  }

  /// 응답 전체에서 items 배열만 꺼내 파싱.
  static List<AutocompleteItemDto> listFromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>;
    return items
        .map((e) => AutocompleteItemDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static final _sixDigits = RegExp(r'^\d{6}$');

  /// 국내 주식 + 6자리 종목코드만 통과.
  bool get isDomesticStock =>
      nationCode == 'KOR' && category == 'stock' && _sixDigits.hasMatch(code);

  Stock toModel() => Stock(symbol: code, name: name, market: typeName);
}
