import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_vault/main.dart';

void main() {
  testWidgets('lock screen renders', (tester) async {
    await tester.pumpWidget(const ObsidianVaultApp());
    await tester.pump();
    expect(find.text('الخزنة'), findsOneWidget);
  });
}
