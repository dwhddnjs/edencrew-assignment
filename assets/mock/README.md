# 목 응답

앱이 쓰는 네 개 엔드포인트의 실제 응답을 저장해 둔 것입니다.
테스트(`test/`)가 이 파일들을 `MockClient` 에 물려 네트워크 없이 돌아갑니다.

| 파일 | 요청 |
| --- | --- |
| `autocomplete.json` | `ac.stock.naver.com/ac?q=삼성&target=stock,ipo,index,marketindicator` |
| `autocomplete_empty.json` | 같은 요청, 결과가 없을 때 (`q=ㄱㄴㄷ`) |
| `realtime.json` | `polling.finance.naver.com/api/realtime?query=SERVICE_ITEM:005930,000660` |
| `meta.json` | `stock.naver.com/api/securityFe/api/fchart/domestic/stock/005930` |
| `sise_day.html` | `finance.naver.com/item/sise_day.naver?code=005930&page=1` |

`realtime.json` 과 `sise_day.html` 은 UTF-8 이 아닙니다(EUC-KR).
읽는 방법은 `docs/NAVER_API.md` 와 `lib/data/naver_api.dart` 를 참고해 주세요.
