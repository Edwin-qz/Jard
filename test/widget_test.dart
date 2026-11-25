import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jardineros_al_rescate/main.dart';
import 'package:jardineros_al_rescate/models/garden_photo.dart';
import 'package:jardineros_al_rescate/models/quote_item.dart';
import 'package:jardineros_al_rescate/services/pdf_quote_service.dart';
import 'package:jardineros_al_rescate/theme/app_theme.dart';

void main() {
  testWidgets('App renders login screen and logs in smoke test', (WidgetTester tester) async {
    // Set viewport to a realistic smartphone screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const JardinerosApp());
    expect(find.text('JARDINEROS AL RESCATE'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsWidgets);

    // Tap Quick Demo Login
    final demoLoginFinder = find.text('Acceso Rápido Demo (Saul Cruz)');
    expect(demoLoginFinder, findsOneWidget);
    await tester.tap(demoLoginFinder);
    
    // Allow the 600ms delayed login simulation to complete
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // After login, home screen renders with gardener name Saul Cruz
    expect(find.text('Saul Cruz'), findsWidgets);
  });

  test('Quote services have valid unitLabel (/ m² or Precio fijo) and valid price', () {
    final services = QuoteServiceItem.defaultServices();
    expect(services.isNotEmpty, isTrue);
    for (final service in services) {
      expect(
        service.unitLabel == '/ m²' || service.unitLabel == 'Precio fijo',
        isTrue,
        reason: 'Service ${service.name} must have a valid measurement unit',
      );
      expect(service.unitPrice, greaterThan(0));
    }
  });

  test('WhatsApp message contains all required fields: date, services, client number, appointment day', () {
    final services = QuoteServiceItem.defaultServices();
    final message = PdfQuoteService.buildWhatsAppMessage(
      clientName: 'María González',
      clientPhone: '+52 999 419 2883',
      address: 'Calle 19 #204, Col. Altabrisa, Mérida, Yucatán',
      appointmentConfirmationDate: 'Viernes, 31 de Octubre 2026',
      quoteDate: '28/10/2026',
      services: services,
      totalPrice: 8050.0,
    );

    expect(message, contains('JARDINEROS AL RESCATE'));
    expect(message, contains('28/10/2026')); // Fecha
    expect(message, contains('+52 999 419 2883')); // Número de cliente
    expect(message, contains('Viernes, 31 de Octubre 2026')); // Día de confirmación de la cita
    expect(message, contains('m²')); // Metros cuadrados
    expect(message, contains('PDF oficial con nuestro logotipo')); // PDF con logo
    expect(message, contains('TOTAL ESTIMADO')); // Precio
  });

  test('Dark mode uses a modern lighter gray and leaf green palette', () {
    AppColors.isDarkMode = true;
    expect(AppColors.background, equals(const Color(0xFF323843)),
        reason: 'Scaffold background must be a lighter, crisp slate gray (not opaque/muddy dark)');
    expect(AppColors.surfaceCard, equals(const Color(0xFF3F4653)),
        reason: 'Cards must use lighter slate gray surface');
    expect(AppColors.leafGreen, equals(const Color(0xFF2EA043)),
        reason: 'Buttons must use natural leaf green');
  });

  test('WhatsApp message includes photos count when evidence photos are registered', () {
    final services = QuoteServiceItem.defaultServices();
    final message = PdfQuoteService.buildWhatsAppMessage(
      clientName: 'María González',
      clientPhone: '+52 999 419 2883',
      address: 'Calle 19 #204, Col. Altabrisa, Mérida, Yucatán',
      appointmentConfirmationDate: 'Viernes, 31 de Octubre 2026',
      quoteDate: '28/10/2026',
      services: services,
      totalPrice: 8050.0,
      photosCount: 3,
    );

    expect(message, contains('3 fotos del terreno adjuntas'));
  });

  test('Soporte de metros cuadrados decimales (5.5 m²) y precios unitarios editables', () {
    final service = QuoteServiceItem(
      id: 'test_m2',
      name: 'Instalación de pasto en Mérida',
      unitPrice: 120.0,
      unitLabel: '/ m²',
      icon: Icons.grass,
      isSelected: true,
      quantity: 5.5, // 5.5 metros cuadrados decimales
    );

    expect(service.quantity, equals(5.5));
    expect(service.subtotal, equals(120.0 * 5.5)); // 660.0

    // Modificación de precio editable
    service.unitPrice = 145.50;
    expect(service.unitPrice, equals(145.50));
    expect(service.subtotal, equals(145.50 * 5.5));
  });

  test('Validaciones estrictas IF/ELSE para campos editables (Nombre, Teléfono, Correo)', () {
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]{2,60}$');
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    // 1. CONDICIÓN NOMBRE: Solo letras, nada de números ni símbolos
    expect(nameRegex.hasMatch('Saul Cruz'), isTrue);
    expect(nameRegex.hasMatch('María González López'), isTrue);
    expect(nameRegex.hasMatch('Saul Cruz 123'), isFalse, reason: 'No se permiten números en el nombre');
    expect(nameRegex.hasMatch('Saul_Cruz!'), isFalse, reason: 'No se permiten símbolos en el nombre');

    // 2. CONDICIÓN TELÉFONO: Solo 10 números celular (sin letras)
    expect(phoneRegex.hasMatch('5541928831'), isTrue);
    expect(phoneRegex.hasMatch('554192883'), isFalse, reason: 'Menos de 10 dígitos debe fallar');
    expect(phoneRegex.hasMatch('554192883100'), isFalse, reason: 'Más de 10 dígitos debe fallar');
    expect(phoneRegex.hasMatch('554192883a'), isFalse, reason: 'No se permiten letras en el teléfono');

    // 3. CONDICIÓN CORREO: Formato estricto de email
    expect(emailRegex.hasMatch('saul.cruz@jardineros.com'), isTrue);
    expect(emailRegex.hasMatch('cliente@gmail.com'), isTrue);
    expect(emailRegex.hasMatch('correo_invalido'), isFalse, reason: 'Debe tener @ y dominio');
    expect(emailRegex.hasMatch('correo@'), isFalse, reason: 'Debe tener dominio');
  });

  test('Diagnóstico de plantas con IA y ausencia de imágenes falsas precargadas', () {
    // Las fotos de muestra deben estar vacías (no hay imágenes simuladas precargadas)
    final photos = GardenPhoto.samplePhotos();
    expect(photos.isEmpty, isTrue, reason: 'Se eliminaron las imágenes simuladas precargadas');

    // Modelo de foto soporta estado fitosanitario de IA (Sana vs Enferma)
    final healthyPhoto = GardenPhoto(
      id: 'photo_test_1',
      title: 'Césped San Agustín',
      category: 'Diagnóstico IA',
      timestamp: '14:30',
      isHealthy: true,
      aiDiagnosisStatus: 'Planta Sana • Follaje Óptimo',
      aiConfidence: 0.98,
      aiTreatment: 'Mantener riego habitual',
    );
    expect(healthyPhoto.isHealthy, isTrue);

    final diseasedPhoto = GardenPhoto(
      id: 'photo_test_2',
      title: 'Follaje con Hongo',
      category: 'Diagnóstico IA',
      timestamp: '14:35',
      isHealthy: false,
      aiDiagnosisStatus: 'Planta Enferma • Clorosis / Hongo Foliar',
      aiConfidence: 0.94,
      aiTreatment: 'Aplicar fungicida orgánico',
    );
    expect(diseasedPhoto.isHealthy, isFalse);
  });
}
