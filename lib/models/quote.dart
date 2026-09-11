// 시세 모델. realtime 응답에서 만듦.
// price, prevClose, open/high/low, volume, listedShares
// 등락액 = price - prevClose, 등락률 = (price - prevClose) / prevClose
// 시가총액 = price * listedShares
// 상승/하락/보합 판별도 여기서 (UI가 색만 고르게).
