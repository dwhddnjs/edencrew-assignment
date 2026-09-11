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
    // 요청이 stock,ipo,index,marketindicator 라서 지수("코스피")와
    // 시장지표("달러") 항목이 섞여 온다. 이 항목들은 nationCode 가 null 이다.
    // 걸러내는 건 isDomesticStock 이지만 파싱이 먼저라 여기서 버티지 못하면
    // 검색 전체가 실패한다. 빈 문자열이면 어차피 필터에서 떨어진다.
    String s(String key) => json[key] as String? ?? '';
    return AutocompleteItemDto(
      code: s('code'),
      name: s('name'),
      typeName: s('typeName'),
      nationCode: s('nationCode'),
      category: s('category'),
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
