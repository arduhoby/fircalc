import 'package:flutter/material.dart';

import '../../../app/flavor/app_flavor.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      'Yüzde',
      'KDV',
      'Kâr Marjı',
      'İskonto',
      'Basit Faiz',
      'Bileşik Faiz',
      if (AppFlavor.enableAdvancedFinanceTools) 'Kredi/Taksit',
      if (AppFlavor.enableAdvancedFinanceTools) 'Kur Çevirme',
      if (AppFlavor.enableAdvancedFinanceTools) 'Yatırım Getirisi',
      if (AppFlavor.enableAdvancedFinanceTools) 'Maliyet/Satış/Kârlılık',
    ];

    return SafeArea(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: cards.length,
        itemBuilder: (_, i) => Card(
          child: Center(child: Text(cards[i], textAlign: TextAlign.center)),
        ),
      ),
    );
  }
}
