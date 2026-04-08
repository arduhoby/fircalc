import '../domain/market_models.dart';

abstract class MarketDataRepository {
  Future<ExchangeRateQuote?> getExchangeRate({
    required String base,
    required String quote,
    bool forceRefresh = false,
  });
}
