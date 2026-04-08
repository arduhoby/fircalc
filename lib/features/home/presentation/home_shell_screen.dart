import 'package:flutter/material.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/flavor/app_flavor.dart';
import '../../calculator_standard/presentation/standard_calculator_screen.dart';
import '../../calculator_tape/presentation/tape_screen.dart';
import '../../finance_tools/presentation/finance_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../market_data/presentation/market_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context).strings;
    final pages = const [
      StandardCalculatorScreen(),
      TapeScreen(),
      FinanceScreen(),
      MarketScreen(),
      HistoryScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(AppFlavor.appName)),
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 900)
            NavigationRail(
              selectedIndex: _index,
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
                  icon: const Icon(Icons.history),
                  label: Text(strings.history),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(strings.settings),
                ),
              ],
            ),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? NavigationBar(
              selectedIndex: _index,
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
                  icon: const Icon(Icons.history),
                  label: strings.history,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  label: strings.settings,
                ),
              ],
            )
          : null,
    );
  }
}
