import 'package:edencrew_assignment_starter/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('가격은 천 단위 콤마, 음수 부호 유지', () {
    expect(Fmt.price(0), '0');
    expect(Fmt.price(999), '999');
    expect(Fmt.price(1000), '1,000');
    expect(Fmt.price(259500), '259,500');
    expect(Fmt.price(-9500), '-9,500');
  });

  test('등락액은 양수에만 + 를 붙인다', () {
    expect(Fmt.signed(1200), '+1,200');
    expect(Fmt.signed(-400), '-400');
    expect(Fmt.signed(0), '0');
  });

  test('등락률은 소수 2자리 퍼센트', () {
    expect(Fmt.rate(-0.0022), '-0.22%');
    expect(Fmt.rate(0.0353), '+3.53%');
    expect(Fmt.rate(0), '0.00%');
  });

  test('과제 예시 표기와 일치한다', () {
    expect(Fmt.change(-400, -0.0022), '-400 (-0.22%)');
  });

  test('거래량·시가총액 축약', () {
    expect(Fmt.volume(29113000), '29,113천');
    expect(Fmt.volume(999), '999');
    expect(Fmt.marketCap(1063000000000000), '1,063조');
    expect(Fmt.marketCap(500000000000), '5,000억');
    expect(Fmt.marketCap(12345), '12,345');
  });

  test('날짜는 MM.DD', () {
    expect(Fmt.date('20260911'), '09.11');
  });
}
