/// Lite-first edition policy.
/// Pro genişletmeleri bu dosyadan türetilecek.
class AppFlavor {
  const AppFlavor._();

  static const appName = 'Fircalc Lite';
  static const packageSuffix = '.lite';

  // Feature gates for Lite.
  static const enableAdvancedFinanceTools = false;
  static const enableLiveMarketProviders = true;
  static const enableExcelExport = false;
  static const enablePortfolioTools = false;
}
