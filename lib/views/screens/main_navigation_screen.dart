import 'package:flutter/material.dart';
import '../../models/appointment.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_screen.dart';
import 'cotizador_screen.dart';
import 'control_screen.dart';
import 'stock_screen.dart';
import 'perfil_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  final VoidCallback onLogout;

  const MainNavigationScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<int> _navigationHistory = [0];

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _navigationHistory.add(index);
        _currentIndex = index;
      });
    }
  }

  void _openNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notificaciones',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '3 nuevas',
                    style: TextStyle(
                      color: AppColors.mint,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                icon: Icons.calendar_today,
                iconColor: AppColors.leafGreen,
                title: 'Próxima cita en 30 minutos',
                subtitle: 'Instalación de pasto en Casa Rivera (Fracc. Altabrisa, Mérida)',
                time: 'Hace 5m',
                onTap: () {
                  Navigator.pop(context);
                  _onTabSelected(0);
                  HomeScreen.showAppointmentDetailsModal(
                    context,
                    Appointment.sampleAppointments().first,
                  );
                },
              ),
              Divider(color: AppColors.borderSubtle),
              _buildNotificationItem(
                icon: Icons.receipt_long,
                iconColor: AppColors.cyan,
                title: 'Cotización aceptada',
                subtitle: 'Mariana Ortega aprobó el presupuesto de mantenimiento en Montebello.',
                time: 'Hace 1h',
                onTap: () {
                  Navigator.pop(context);
                  _showAcceptedQuoteDialog(context);
                },
              ),
              Divider(color: AppColors.borderSubtle),
              _buildNotificationItem(
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.coral,
                title: 'Alerta de Inventario Crítico',
                subtitle: 'Insecticida orgánico tiene solo 2 botellas disponibles.',
                time: 'Hace 3h',
                onTap: () {
                  Navigator.pop(context);
                  _onTabSelected(3);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.coral,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: const Text('Mostrando Stock: Insecticida orgánico con existencias críticas.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await NotificationService.notifyUpcomingAppointment('Casa Rivera (Altabrisa)', '9:30 AM');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.leafGreen,
                          content: Text('Notificación enviada a la barra de estado del teléfono.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.mint),
                  label: const Text(
                    'Lanzar notificación a la barra del teléfono',
                    style: TextStyle(color: AppColors.mint, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showAcceptedQuoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: AppColors.leafGreen, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cotización Aceptada',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.leafBadgeBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.leafGreen.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Folio: #COT-2026-YUC', style: TextStyle(color: AppColors.leafGreenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('APROBADA', style: TextStyle(color: AppColors.leafGreenAccent, fontSize: 11, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Cliente: Mariana Ortega', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const Text('Ubicación: Residencial Montebello, Mérida, Yucatán', style: TextStyle(color: AppColors.leafGreenLight, fontSize: 12)),
                    const SizedBox(height: 6),
                    const Text('Servicio: Poda estética y perfilado de jardín (35 m²)', style: TextStyle(color: AppColors.leafGreenLight, fontSize: 12)),
                    const Divider(color: AppColors.leafGreen, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Monto presupuestado:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('\$1,850.00 MXN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'El cliente confirmó la orden de servicio en Mérida. Se programó inicio de obra para este miércoles a las 12:30 PM.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cerrar', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _onTabSelected(1); // Cotizador
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leafGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ver en Cotizador', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _navigationHistory.length <= 1 && _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_navigationHistory.length > 1) {
          setState(() {
            _navigationHistory.removeLast();
            _currentIndex = _navigationHistory.last;
          });
        } else if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _navigationHistory.clear();
            _navigationHistory.add(0);
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: AppColors.leafGreen.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      HomeScreen(
                        onNavigateToAgenda: () => _onTabSelected(2),
                        onOpenNotifications: _openNotificationsModal,
                      ),
                      CotizadorScreen(
                        onOpenNotifications: _openNotificationsModal,
                      ),
                      ControlScreen(
                        onOpenNotifications: _openNotificationsModal,
                      ),
                      StockScreen(
                        onOpenNotifications: _openNotificationsModal,
                      ),
                      PerfilScreen(
                        isDarkMode: widget.isDarkMode,
                        onToggleTheme: widget.onToggleTheme,
                        onOpenNotifications: _openNotificationsModal,
                        onLogout: widget.onLogout,
                      ),
                    ],
                  ),
                ),
                CustomBottomNavBar(
                  currentIndex: _currentIndex,
                  onTabSelected: _onTabSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
