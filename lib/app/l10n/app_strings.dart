class AppStrings {
  AppStrings._(this.languageCode);

  final String languageCode;

  static AppStrings of(String languageCode) => AppStrings._(languageCode);

  bool get isTr => languageCode.toLowerCase().startsWith('tr');

  String get appTitle => isTr ? 'Fircalc Lite' : 'Fircalc Lite';
  String get standard => isTr ? 'Standart' : 'Standard';
  String get tape => isTr ? 'Şerit' : 'Tape';
  String get finance => isTr ? 'Finans' : 'Finance';
  String get market => isTr ? 'Piyasa' : 'Market';
  String get news => isTr ? 'Haber' : 'News';
  String get history => isTr ? 'Geçmiş' : 'History';
  String get settings => isTr ? 'Ayarlar' : 'Settings';
  String get offline => isTr ? 'Çevrimdışı' : 'Offline';
  String get staleData =>
      isTr ? 'Son veri gösteriliyor' : 'Showing last known data';
  String get liveData => isTr ? 'Canlı veri' : 'Live data';
}
