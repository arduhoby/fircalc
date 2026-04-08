import '../../../core/types/currency_code.dart';
import '../../../core/types/decimal_value.dart';
import '../domain/market_data_repository.dart';
import '../domain/market_models.dart';

class InMemoryMarketRepository implements MarketDataRepository {
  const InMemoryMarketRepository({required this.source, required this.seed});

  final DataSourceType source;
  final DecimalValue seed;

  @override
  Future<ExchangeRateQuote?> getExchangeRate({
    required String base,
    required String quote,
    bool forceRefresh = false,
  }) async {
    if (base != 'TRY' || quote != 'USD') return null;

    return ExchangeRateQuote(
      base: CurrencyCode.tryCode,
      quote: CurrencyCode.usd,
      buy: seed,
      sell: seed.plus(DecimalValue.parse('0.05')),
      timestamp: DateTime.now(),
      source: source,
      status: source == DataSourceType.cache
          ? MarketDataStatus.stale
          : MarketDataStatus.live,
    );
  }
}
