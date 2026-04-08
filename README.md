# Fircalc Lite (Lite-first)

Modüler, offline-first Flutter hesap makinesi.

## Aktif Ürün Hedefi

Bu repo şu an **Lite** üzerine odaklı ilerler.
Pro varyantı bilinçli olarak park edildi.

## Paket Kimliği

- Android applicationId: `com.melihfidan.mfcalc.lite`
- iOS bundle root: `com.melihfidan.mfcalc`

## Lite Feature Policy

Lite sürümde aktif/pasif durumlar merkezi policy dosyasında yönetilir:
- Dosya: `lib/app/flavor/app_flavor.dart`
- `enableAdvancedFinanceTools = false`
- `enableLiveMarketProviders = true`
- `enableExcelExport = false`
- `enablePortfolioTools = false`

## TCMB API Key (Yerel)

- Key dosyası: proje kökünde `tcmb.txt`
- Kod içine gömülmez; çalıştırırken `--dart-define=TCMB_API_KEY=...` ile geçilir.

Hazır komutlar:

```bash
./tool/run_lite_with_tcmb.sh -d <device_id>
./tool/build_lite_with_tcmb.sh
```

## Çalıştırma

```bash
flutter run --flavor lite -t lib/main_lite.dart
```

## Build

```bash
flutter build apk --flavor lite -t lib/main_lite.dart
```
