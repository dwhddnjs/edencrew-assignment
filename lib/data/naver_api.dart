import 'dart:convert';

import 'package:http/http.dart' as http;

/// 네이버 endpoint 호출만 담당한다.
/// 파싱은 data/dto, 모델 변환은 StockRepository 가 한다.
class NaverApi {
  NaverApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  /// finance.naver.com 은 User-Agent 가 없으면 404 페이지를 돌려준다.
  static const _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

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
  /// 일별 시세. JSON 이 아니라 HTML 을 돌려준다.
  Future<String> dailyPrice(String symbol, int page) {
    return _getHtml(
      Uri.https('finance.naver.com', '/item/sise_day.naver', {
        'code': symbol,
        'page': '$page',
      }),
    );
  }

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

  /// 일별 시세 HTML 은 EUC-KR 이다. Dart 기본 코덱에 EUC-KR 이 없고,
  /// 이 페이지에서 읽어야 하는 값(날짜·가격·거래량·페이지 번호)은 전부
  /// ASCII 라서 latin1 로 바이트를 1:1 대응시켜 읽는다.
  ///
  /// 안전한 이유: EUC-KR / CP949 의 한글은 선행 0x81~0xFE, 후행
  /// 0x41~0x5A / 0x61~0x7A / 0x81~0xFE 로만 이루어진다. `<`, `>`, `"`,
  /// `/`, 숫자는 그 범위에 없으므로 한글이 태그나 숫자로 잘못 보일 수 없다.
  /// 한글 본문(`상승`/`하락` 등)은 깨지지만 파서가 읽지 않는다.
  Future<String> _getHtml(Uri uri) async {
    final res = await _client
        .get(uri, headers: const {'User-Agent': _userAgent})
        .timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('naver ${res.statusCode}: $uri');
    }
    return latin1.decode(res.bodyBytes, allowInvalid: true);
  }

  void close() => _client.close();
}
