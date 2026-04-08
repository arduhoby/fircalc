import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mfcalc/app/app.dart';
import 'package:mfcalc/features/home/presentation/home_shell_screen.dart';

void main() {
  testWidgets('App shell opens', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MfCalcApp()));
    await tester.pumpAndSettle();
    expect(find.byType(HomeShellScreen), findsOneWidget);
  });
}
