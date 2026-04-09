import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/flavor/app_flavor.dart';
import '../../calculator_standard/presentation/standard_calculator_screen.dart';
import '../../calculator_tape/application/tape_controller.dart';
import '../../calculator_tape/presentation/tape_screen.dart';
import '../../finance_tools/presentation/finance_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../market_data/application/market_news_provider.dart';
import '../../market_data/application/market_quote_provider.dart';
import '../../market_data/presentation/market_screen.dart';
import '../../settings/application/display_settings_controller.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  static const _marketIndex = 3;
  static const _newsIndex = 4;
  static const _historyIndex = 5;
  static const _settingsIndex = 6;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;
    final navIndex = _index > _newsIndex ? 0 : _index;
    final pages = const [
      StandardCalculatorScreen(),
      TapeScreen(),
      FinanceScreen(),
      MarketScreen(),
      MarketNewsScreen(),
      HistoryScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/branding/app_logo_tree.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(AppFlavor.appName),
          ],
        ),
        actions: [
          if (_index == _marketIndex || _index == _newsIndex)
            IconButton(
              onPressed: () {
                ref.invalidate(trackedFxRatesProvider);
                ref.invalidate(trackedMarketWatchProvider);
                ref.invalidate(marketNewsProvider);
              },
              icon: const Icon(Icons.refresh),
              tooltip: 'Yenile',
            ),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: _TapeMenuInAppBar(
              onChanged: () {
                if (mounted) setState(() {});
              },
              onOpenSettings: () {
                if (mounted) setState(() => _index = _settingsIndex);
              },
              onOpenHistory: () {
                if (mounted) setState(() => _index = _historyIndex);
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 900)
            NavigationRail(
              selectedIndex: navIndex,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(strings.standard),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(strings.tape),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: Text(strings.finance),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.candlestick_chart),
                  label: Text(strings.market),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.article_outlined),
                  label: Text(strings.news),
                ),
              ],
            ),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? NavigationBar(
              selectedIndex: navIndex,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.calculate_outlined),
                  label: strings.standard,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: strings.tape,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: strings.finance,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.candlestick_chart),
                  label: strings.market,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.article_outlined),
                  label: strings.news,
                ),
              ],
            )
          : null,
    );
  }
}

class _TapeMenuInAppBar extends ConsumerWidget {
  const _TapeMenuInAppBar({
    required this.onChanged,
    required this.onOpenSettings,
    required this.onOpenHistory,
  });

  final VoidCallback onChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(displaySettingsProvider);
    final settingsController = ref.read(displaySettingsProvider.notifier);
    final tapeController = ref.read(tapeControllerProvider.notifier);

    return PopupMenuButton<_TapeMenuAction>(
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.menu),
      tooltip: 'Menü',
      onSelected: (action) async {
        switch (action) {
          case _TapeMenuAction.toggleSaveMode:
            settingsController.toggleTapeSaveMode(
              !settings.tapeSaveModeEnabled,
            );
            onChanged();
            return;
          case _TapeMenuAction.saveSnapshot:
            if (!settings.tapeSaveModeEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Önce Save modunu açın.')),
              );
              return;
            }
            final name = await tapeController.saveSnapshotNow();
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Kaydedildi: $name')));
            return;
          case _TapeMenuAction.openSettings:
            onOpenSettings();
            return;
          case _TapeMenuAction.openHistory:
            onOpenHistory();
            return;
        }
      },
      itemBuilder: (context) => [
        CheckedPopupMenuItem<_TapeMenuAction>(
          value: _TapeMenuAction.toggleSaveMode,
          checked: settings.tapeSaveModeEnabled,
          child: const Text('Save Modu'),
        ),
        const PopupMenuItem<_TapeMenuAction>(
          value: _TapeMenuAction.saveSnapshot,
          child: Text('Kaydet'),
        ),
        const PopupMenuItem<_TapeMenuAction>(
          value: _TapeMenuAction.openSettings,
          child: Text('Ayarlar'),
        ),
        const PopupMenuItem<_TapeMenuAction>(
          value: _TapeMenuAction.openHistory,
          child: Text('Geçmiş'),
        ),
      ],
    );
  }
}

enum _TapeMenuAction { toggleSaveMode, saveSnapshot, openSettings, openHistory }
