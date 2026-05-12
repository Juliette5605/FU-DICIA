// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fu_dicia/main.dart';
import 'package:fu_dicia/config/locale_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Cette ligne est nécessaire pour simuler les plugins natifs (comme SharedPreferences)
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('L\'application démarre et affiche le SplashScreen', (WidgetTester tester) async {
    // On initialise les SharedPreferences avec des valeurs vides pour le test
    SharedPreferences.setMockInitialValues({});
    
    final localeManager = LocaleManager();
    await localeManager.init();

    // On lance l'application
    await tester.pumpWidget(FuDiciaApp(localeManager: localeManager));

    // Vérifications
    expect(find.byType(FuDiciaApp), findsOneWidget);
    
    // On peut aussi vérifier que le SplashScreen est bien présent au démarrage
    // (Puisque c'est le "home" de votre MaterialApp)
    await tester.pump(); // Déclenche le premier frame
    expect(find.text('FU-DICIA'), findsOneWidget);
  });
}