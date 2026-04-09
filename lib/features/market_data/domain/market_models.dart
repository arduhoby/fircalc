import '../../../core/types/currency_code.dart';
import '../../../core/types/decimal_value.dart';

enum MarketInstrumentType { fx, gold, oil, bistStock, globalStock }

enum DataSourceType {
  tcmbDaily,
  tcmbHourly,
  apiFallback,
  scraping,
  cache,
  manual,
}

enum MarketDataStatus { live, stale, manual, offline }

enum FxRateKind { daily, effective }

enum MarketWatchKind { crypto, preciousMetal, stock, energy }

class ExchangeRateQuote {
  const ExchangeRateQuote({
    required this.base,
    required this.quote,
    required this.buy,
    required this.sell,
    required this.timestamp,
    required this.source,
    required this.status,
  });

  final CurrencyCode base;
  final CurrencyCode quote;
  final DecimalValue buy;
  final DecimalValue sell;
  final DateTime timestamp;
  final DataSourceType source;
  final MarketDataStatus status;
}

class FxRateSnapshot {
  const FxRateSnapshot({
    required this.currency,
    required this.kind,
    required this.buy,
    required this.sell,
    required this.timestamp,
    required this.source,
    required this.status,
  });

  final CurrencyCode currency;
  final FxRateKind kind;
  final DecimalValue buy;
  final DecimalValue sell;
  final DateTime timestamp;
  final DataSourceType source;
  final MarketDataStatus status;
}

class MarketWatchSnapshot {
  const MarketWatchSnapshot({
    required this.code,
    required this.name,
    required this.kind,
    required this.priceTry,
    this.openTry,
    this.closeTry,
    this.lowTry,
    this.highTry,
    required this.unit,
    required this.timestamp,
    required this.source,
    required this.status,
  });

  final String code;
  final String name;
  final MarketWatchKind kind;
  final DecimalValue priceTry;
  final DecimalValue? openTry;
  final DecimalValue? closeTry;
  final DecimalValue? lowTry;
  final DecimalValue? highTry;
  final String unit;
  final DateTime timestamp;
  final DataSourceType source;
  final MarketDataStatus status;
}

class MarketHistoryPoint {
  const MarketHistoryPoint({
    required this.time,
    required this.value,
    this.label,
  });

  final DateTime time;
  final DecimalValue value;
  final String? label;
}
