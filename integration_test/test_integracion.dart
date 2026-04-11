import 'package:appshine/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Prueba de integración para el flujo de alta de un evento social.
///
/// Mecanismo:
/// * Arranca la app real mediante `main()`.
/// * Ejecuta interacciones UI sobre el emulador.
/// * Valida el resultado final en la lista de Home.
///
/// Entradas:
/// * Credenciales existentes inyectadas por `dart-define`:
///   `IT_EMAIL` y `IT_PASSWORD`.
/// * Título generado en tiempo de ejecucion para evitar colisiones.
///
/// Salidas esperadas:
/// * Login correcto.
/// * Apertura del modal de alta.
/// * Guardado del evento social.
/// * Visualizacion del nuevo evento en Home.
/// 
/// Notas: Para ejecutar esta prueba, asegúrate de tener un emulador configurado y corre el comando:
/// `flutter test integration_test/test_integracion.dart --dart-define=IT_EMAIL=tu_usuario --dart-define=IT_PASSWORD=tu_clave --dart-define=IS_TESTING=true`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Caso integral entre: autenticación, creación de evento social y visualización en home.
  testWidgets(
    'Iniciar sesión + Crear Evento social + Aparece en home screen',
    (tester) async {
      Future<void> waitStep([int milliseconds = 1200]) async {
        await tester.pump(Duration(milliseconds: milliseconds));
      }

      /// Helper para encontrar el primer texto visible entre varias opciones, útil para soportar múltiples idiomas.
      Finder? firstVisibleText(List<String> options) {
        for (final text in options) {
          final candidate = find.text(text);
          if (candidate.evaluate().isNotEmpty) return candidate;
        }
        return null;
      }

      /// Helper para hacer tap en el primer texto visible entre varias opciones, con mensaje de error personalizado.
      Future<void> tapFirstVisibleText(
        List<String> options, {
        required String failMessage,
      }) async {
        final finder = firstVisibleText(options);
        if (finder == null) {
          fail(failMessage);
        }
        await tester.tap(finder.first);
      }

      /// Helpers para detectar estados específicos de la UI, útiles para diagnósticos en caso de fallos.
      bool isOnLogin() {
        return find.byType(TextField).evaluate().length >= 2 &&
            (find.text('Entrar').evaluate().isNotEmpty ||
                find.text('Enter').evaluate().isNotEmpty);
      }
      /// En Home admin no hay FAB, y el título es diferente, así que detectamos por ambos para mayor robustez.
      bool isOnAdminHome() {
        return find.text('Admin Dashboard').evaluate().isNotEmpty;
      }

      /// Helper para detectar si el FAB de alta está presente, útil para diagnósticos en caso de fallos.
      bool hasFab() {
        return find.byType(FloatingActionButton).evaluate().isNotEmpty;
      }

      /// Helper para esperar a que el estado post-login se estabilice, con múltiples chequeos intermedios.
      Future<void> waitForPostLoginState() async {
        // Espera activa para dar tiempo a AuthGate + autenticación + consulta de rol en Firestore.
        // Importante: no salir por seguir en login, porque justo después del tap aún no ha terminado el login.
        for (int i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 500));

          // Estado final esperado para este flujo.
          if (hasFab() || isOnAdminHome()) {
            return;
          }

          // Si ya hay usuario autenticado, damos algo más de margen para que Home termine de construir.
          if (FirebaseAuth.instance.currentUser != null) {
            await tester.pump(const Duration(milliseconds: 800));
            if (hasFab() || isOnAdminHome()) {
              return;
            }
          }
        }
      }

      // ----- INICIO DE LA PRUEBA ------
      debugPrint('[IT] Iniciando app');
      app.main();
      await waitStep(2500);

      // Inicio: siempre arrancar en estado no autenticado.
      await FirebaseAuth.instance.signOut();
      await waitStep(1500);
      debugPrint('[IT] Cierre de sesión forzado para comenzar desde login');

      // Credenciales de usuario existente para la prueba de integración.
      // Se inyectan por dart-define para no hardcodear datos reales.
      const email = String.fromEnvironment('IT_EMAIL', defaultValue: '');
      const password = String.fromEnvironment('IT_PASSWORD', defaultValue: '');
      final eventTitle = 'IT Evento Social Test ${DateTime.now().millisecondsSinceEpoch}';

      if (email.isEmpty || password.isEmpty) {
        fail(
          'Faltan credenciales de integración. Ejecuta con '
          '--dart-define=IT_EMAIL=tu_usuario --dart-define=IT_PASSWORD=tu_clave',
        );
      }

      final textFields = find.byType(TextField);
      final loginButton = firstVisibleText(['Entrar', 'Enter']);

      expect(
        textFields,
        findsAtLeastNWidgets(2),
        reason: 'La pantalla de login debe mostrar email y password.',
      );
      expect(
        loginButton != null,
        isTrue,
        reason: 'Se esperaba botón de login (Entrar/Enter) tras signOut forzado.',
      );

      await tester.enterText(textFields.at(0), email);
      await tester.enterText(textFields.at(1), password);
      await tester.tap(loginButton!.first);
      debugPrint('[IT] Login enviado para usuario existente');
      await waitForPostLoginState();
      debugPrint(
        '[IT] Usuario actual tras login: ${FirebaseAuth.instance.currentUser?.email ?? 'null'}',
      );

      debugPrint('[IT] Verificando home y apertura de menu de alta');
      // Home debe estar visible y el FAB disponible para usuario no-admin.
      final addFab = find.byType(FloatingActionButton);
      if (addFab.evaluate().isEmpty) {
        final stillOnLogin = isOnLogin();
        final adminSignals = isOnAdminHome();

        if (stillOnLogin) {
          final currentUser = FirebaseAuth.instance.currentUser?.email ?? 'null';
          fail(
            'No se encontró FAB porque login no completo. Verificar credenciales del usuario existente. '
            'Usuario actual: $currentUser.',
          );
        }
        if (adminSignals) {
          fail(
            'No se encontró FAB porque el usuario es admin (en Home admin no hay FAB). Usa un usuario no-admin.',
          );
        }

        fail(
          'No se encontró FAB tras login. Revisa estado de la pantalla y sincronización.',
        );
      }

      expect(addFab, findsOneWidget);
      await tester.ensureVisible(addFab);
      await waitStep(300);
      await tester.tap(addFab, warnIfMissed: false);
      await waitStep(1200); // Espera para que se abra el modal

      // Seleccionar opcion de evento social en el modal.
      await tapFirstVisibleText(
        ['Evento | Social', 'Event | Social'],
        failMessage: 'No se pudo abrir el modal de alta de momentos.',
      );
      debugPrint('[IT] Opcion de evento social seleccionada');
      await waitStep(3000); // Espera para que se abra la pantalla de agregar evento
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Rellenar titulo.
      final fieldsInForm = find.byType(TextField);
      expect(fieldsInForm, findsWidgets, reason: 'Se esperaban TextFields en la pantalla de agregar evento');
      await tester.enterText(fieldsInForm.first, eventTitle);
      await waitStep(1200); // Espera después de rellenar el título

      // Seleccionar subtipo desde el desplegable (Gaming/Juegos).
      await tester.tap(find.byType(DropdownButton<String>).first);
      await waitStep(1500); // Espera para que se abra el dropdown

      await tapFirstVisibleText(
        ['Juegos', 'Gaming'],
        failMessage: 'No se encontró subtipo Gaming/Juegos en el desplegable.',
      );
      await waitStep(1500); // Espera después de seleccionar subtipo

      debugPrint('[IT] Guardando evento: $eventTitle');
      // Guardar evento y volver a home.
      await tester.tap(find.byIcon(Icons.save).first);
      await waitStep(3000); // Espera para que se guarde y vuelva a Home

      debugPrint('[IT] Validando que el evento aparece en home');
      // Validar que el nuevo evento aparece en la lista de home.
      final eventInHomeList = find.descendant(
        of: find.byType(ListTile),
        matching: find.text(eventTitle),
      );
      expect(eventInHomeList, findsAtLeastNWidgets(1));
      debugPrint('[IT] Validación exitosa, mostrando home durante 3 segundos');
      
      // Mantener visible la pantalla durante 3 segundos reales
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      
      debugPrint('[IT] Prueba finalizada OK');
    },
    // Timeout extendido para dar margen al flujo completo del test
    timeout: const Timeout(Duration(minutes: 2)), 
  );
}
