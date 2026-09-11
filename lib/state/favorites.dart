// 관심 종목 목록 = 3개 화면이 공유하는 유일한 상태.
// ChangeNotifier 하나로 충분. 화면에서는 ListenableBuilder 로 구독.
// add / remove / contains(symbol) 정도면 됨.
// 정렬 기준(현재가순/등락률순/가나다순)도 여기 둘지 화면에 둘지 판단.
