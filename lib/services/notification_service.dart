import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio de Notificaciones Locales en la Barra de Notificaciones del Teléfono.
/// Despliega notificaciones reales en la bandeja del sistema operativo.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Inicializa el plugin de notificaciones locales y solicita permisos en Android 13+ / iOS
  static Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Manejador al pulsar sobre la notificación en la barra
      },
    );

    // Solicitar permisos en Android 13+
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  /// Despliega una notificación en la barra de estado del teléfono
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'jardineros_channel_id',
      'Jardineros Al Rescate',
      channelDescription:
          'Canal de notificaciones de citas, cotizaciones y alertas de stock de Jardineros Al Rescate',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Notificación de cita próxima
  static Future<void> notifyUpcomingAppointment(String clientName, String time) async {
    await showNotification(
      id: 101,
      title: '🌿 Próxima cita de jardinería',
      body: 'Cita con $clientName programada para las $time. Toca para ver la ruta GPS.',
    );
  }

  /// Notificación de cotización aprobada
  static Future<void> notifyQuoteApproved(String clientName, double amount) async {
    await showNotification(
      id: 102,
      title: '✅ ¡Cotización Aceptada!',
      body: '$clientName ha aprobado el presupuesto por \$${amount.toStringAsFixed(0)} MXN.',
    );
  }

  /// Notificación de alerta de inventario crítico
  static Future<void> notifyCriticalStock(String productName, int quantity) async {
    await showNotification(
      id: 103,
      title: '⚠️ Alerta de Inventario Crítico',
      body: '$productName tiene solo $quantity unidades disponibles. Se recomienda surtir.',
    );
  }
}
