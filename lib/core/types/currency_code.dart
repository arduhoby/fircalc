enum CurrencyCode {
  tryCode('TRY'),
  usd('USD'),
  eur('EUR'),
  gbp('GBP'),
  jpy('JPY'),
  cny('CNY'),
  rub('RUB');

  const CurrencyCode(this.code);
  final String code;
}
