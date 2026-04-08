import '../domain/market_data_repository.dart';
import '../domain/market_models.dart';

class QuoteFallbackService {
  QuoteFallbackService(this.providers);

  final List<MarketDataRepository> providers;

  Future<ExchangeRateQuote?> resolve(String base, String quote) async {
    for (final provider in providers) {
      try {
        final result = await provider.getExchangeRate(base: base, quote: quote);
        if (result != null) return result;
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
