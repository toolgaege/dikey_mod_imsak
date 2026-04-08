import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dikey_mod_sultan_mescidi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize date formatting for Turkish locale
    await initializeDateFormatting('tr', null);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const DikeyModApp());

    // Verify that the app loads and displays the title.
    // We expect at least one widget with 'Sultan Mescidi' (AppBar title, etc.)
    expect(find.text('Sultan Mescidi'), findsWidgets);
  });
}