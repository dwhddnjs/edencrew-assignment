// 실시간 시세 응답 DTO.
// cd=symbol, nv=현재가, pcv=전일종가, ov/hv/lv, aq=거래량, countOfListedStock
// symbol -> Quote 맵으로 변환해서 돌려주기.
import '../../models/quote.dart';

/// 실시간 시세 응답의 종목 하나.
class RealtimeItemDto {
  final String cd;
  final int nv;
  final int pcv;
  final int ov;
  final int hv;
  final int lv;
  final int aq;
  final int countOfListedStock;

  const RealtimeItemDto({
    required this.cd,
    required this.nv,
    required this.pcv,
    required this.ov,
    required this.hv,
    required this.lv,
    required this.aq,
    required this.countOfListedStock,
  });

  /// 종목코드와 현재가가 있는 항목만 넘어온다. ([hasCore])
  factory RealtimeItemDto.fromJson(Map<String, dynamic> json) {
    // 보조 필드가 비어도 파싱은 계속한다.
    // 부분 실패를 전체 실패로 키우지 않는다.
    int n(String key) => (json[key] as num?)?.toInt() ?? 0;
    return RealtimeItemDto(
      cd: json['cd'] as String,
      nv: n('nv'),
      pcv: n('pcv'),
      ov: n('ov'),
      hv: n('hv'),
      lv: n('lv'),
      aq: n('aq'),
      countOfListedStock: n('countOfListedStock'),
    );
  }

  /// 종목코드와 현재가가 둘 다 있는 항목인지.
  ///
  /// 둘 중 하나라도 없으면 시세로 쓸 수 없다. 거래정지 종목처럼 `nv` 가
  /// 빠진 항목을 0 으로 채우면 `0 원 / -100%` 가 진짜 시세처럼 그려진다.
  static bool hasCore(Map<String, dynamic> json) =>
      json['cd'] is String && json['nv'] is num;

  /// result.areas[*].datas[*] 를 전부 펼쳐서 파싱.
  ///
  /// 쓸 수 없는 항목은 건너뛴다. 한 종목 때문에 목록 전체 갱신이 실패하면
  /// 멀쩡한 나머지 종목까지 에러 화면으로 덮인다.
  static List<RealtimeItemDto> listFromJson(Map<String, dynamic> json) {
    final areas =
        (json['result'] as Map<String, dynamic>)['areas'] as List<dynamic>;
    return areas
        .expand((a) => (a as Map<String, dynamic>)['datas'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where(hasCore)
        .map(RealtimeItemDto.fromJson)
        .toList();
  }

  Quote toModel() => Quote(
    symbol: cd,
    price: nv,
    prevClose: pcv,
    open: ov,
    high: hv,
    low: lv,
    volume: aq,
    listedShares: countOfListedStock,
  );
}
