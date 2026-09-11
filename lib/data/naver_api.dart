// endpoint 4개 HTTP 호출만 담당. 파싱은 dto/ 가 함.
// 1. GET https://ac.stock.naver.com/ac                (검색 자동완성)
// 2. GET https://polling.finance.naver.com/api/realtime (실시간 시세, 여러 종목 한 번에)
// 3. GET https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol} (메타)
// 4. GET https://finance.naver.com/item/sise_day.naver  (일별 시세 HTML, EUC-KR)
