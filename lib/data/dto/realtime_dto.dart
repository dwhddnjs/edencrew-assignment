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

  factory RealtimeItemDto.fromJson(Map<String, dynamic> json) {
    // 한 종목이라도 필드가 비면 관심 목록 전체 갱신이 실패한다.
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

  /// result.areas[*].datas[*] 를 전부 펼쳐서 파싱.
  static List<RealtimeItemDto> listFromJson(Map<String, dynamic> json) {
    final areas =
        (json['result'] as Map<String, dynamic>)['areas'] as List<dynamic>;
    return areas
        .expand((a) => (a as Map<String, dynamic>)['datas'] as List<dynamic>)
        .map((e) => RealtimeItemDto.fromJson(e as Map<String, dynamic>))
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
