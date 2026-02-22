import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nebula/app/nebula_app.dart';
import 'package:nebula/controllers/app_controller.dart';
import 'package:nebula/services/connectivity_service.dart';

void main() {
  testWidgets('Nebula renders welcome flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = await AppController.bootstrap(
      connectivityService: FakeConnectivityService(initialOnline: true),
    );

    await tester.pumpWidget(NebulaApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Nebula'), findsOneWidget);
    expect(find.text('¡Quiero entrar!'), findsOneWidget);
    expect(find.text('¡Crear mi cuenta!'), findsOneWidget);

    controller.dispose();
  });
}
