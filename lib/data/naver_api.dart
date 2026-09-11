import 'dart:convert';

import 'package:http/http.dart' as http;

/// 네이버 endpoint 호출만 담당한다.
/// 파싱은 data/dto, 모델 변환은 StockRepository 가 한다.
class NaverApi {
  NaverApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  /// 검색 자동완성.
  Future<Map<String, dynamic>> autocomplete(String query) {
    return _getJson(
      Uri.https('ac.stock.naver.com', '/ac', {
        'q': query,
        'target': 'stock,ipo,index,marketindicator',
      }),
    );
  }

  /// 실시간 시세. 여러 종목을 한 번의 요청으로 받는다.
  Future<Map<String, dynamic>> realtime(List<String> symbols) {
    return _getJson(
      Uri.https('polling.finance.naver.com', '/api/realtime', {
        'query': 'SERVICE_ITEM:${symbols.join(',')}',
      }),
    );
  }

  /// 종목 메타데이터 (이름, 거래소명).
  Future<Map<String, dynamic>> stockMeta(String symbol) {
    return _getJson(
      Uri.https(
        'stock.naver.com',
        '/api/securityFe/api/fchart/domestic/stock/$symbol',
      ),
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await _client.get(uri).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('naver ${res.statusCode}: $uri');
    }
    // realtime 응답은 UTF-8이 아니다(EUC-KR). 한글 필드는 쓰지 않으므로
    // 깨진 바이트만 버리고 숫자/종목코드를 읽는다.
    return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true))
        as Map<String, dynamic>;
  }

  void close() => _client.close();
}
