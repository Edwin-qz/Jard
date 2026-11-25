import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../widgets/camera_modal.dart';

class PerfilScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  final VoidCallback onOpenNotifications;
  final VoidCallback onLogout;

  const PerfilScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onOpenNotifications,
    required this.onLogout,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _phone = '+52 999 782 1096';
  String _email = 'saul.cruz@jardineros.mx';
  String _city = 'Mérida, Yucatán';
  String _name = 'Saul Cruz';
  String? _profileImagePath = 'assets/images/avatar_saul.jpg';
  Uint8List? _profileImageBytes;

  // Información del negocio personalizable por el usuario
  String _businessName = 'Jardineros Al Rescate S.A.P.I.';
  String _businessDescription =
      'Especialistas en diseño paisajístico, instalación de pasto en rollo, nivelación y mantenimiento integral de áreas verdes residenciales y comerciales en Mérida, Yucatán.';
  String _businessRfc = 'JAL210915AB3';
  String _businessPhone = '999 782 1096';
  String _businessAddress = 'Calle 60 #320 x 35 y 37, Centro / Altabrisa, Mérida, Yucatán';
  String _businessHours = 'Lun - Sáb: 7:00 AM - 6:00 PM';

  Future<void> _takeProfilePhotoWithCamera() async {
    final photo = await CameraModal.show(
      context,
      initialCategory: 'Perfil',
      isFrontCamera: true,
    );
    if (photo != null) {
      setState(() {
        _profileImageBytes = photo.imageBytes;
        _profileImagePath = photo.assetPath;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.leafGreen,
            content: const Text('Foto de perfil actualizada con éxito.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
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
              Text(
                'Foto de Perfil',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.leafBadgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.leafGreen, size: 20),
                ),
                title: Text('Tomar foto con cámara (Selfie)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Abre la cámara frontal para capturar tu foto', style: TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  _takeProfilePhotoWithCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.leafBadgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.cyan, size: 20),
                ),
                title: Text('Elegir de galería', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('Selecciona una imagen guardada', style: TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImagePath = 'assets/images/avatar_saul.jpg';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto de perfil cargada.')),
                  );
                },
              ),
              if (_profileImagePath != null || _profileImageBytes != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.coralBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.coral, size: 20),
                  ),
                  title: const Text('Eliminar foto y usar monograma', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _profileImageBytes = null;
                      _profileImagePath = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Profile Photo Card with Camera Badge
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onTap: () => _showPhotoOptions(context),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2EA043), Color(0xFF1B6B2E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.leafGreen.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _profileImageBytes != null
                              ? Image.memory(
                                  _profileImageBytes!,
                                  fit: BoxFit.cover,
                                )
                              : (_profileImagePath != null
                                  ? Image.asset(
                                      _profileImagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Center(
                                        child: Text(
                                          'SC',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Text(
                                        'SC',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    )),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: InkWell(
                        onTap: () => _showPhotoOptions(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.leafGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Name & Role
              Text(
                _name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Jardinero profesional • $_city',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 22),

              // Contact 2-Column Row
              Row(
                children: [
                  Expanded(
                    child: _buildContactTile(
                      icon: Icons.phone_outlined,
                      label: 'TELÉFONO',
                      value: _phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildContactTile(
                      icon: Icons.mail_outline_rounded,
                      label: 'CORREO',
                      value: _email,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // City Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.mint,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CIUDAD',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _city,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Green Button: Editar mis datos (Acceso directo)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _editProfileInfo(context),
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                  label: const Text(
                    'Editar mis datos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Menu Card: Información del negocio & Notificaciones
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.eco_outlined,
                      title: 'Información del negocio',
                      onTap: () {
                        _showBusinessInfo(context);
                      },
                    ),
                    Container(height: 1, color: AppColors.borderSubtle),
                    _buildMenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notificaciones',
                      onTap: widget.onOpenNotifications,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Dark Mode Toggle Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF162734) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        color: widget.isDarkMode ? AppColors.cyan : AppColors.amber,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modo oscuro',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Reduce el brillo de la interfaz',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: widget.isDarkMode,
                      activeThumbColor: AppColors.mint,
                      activeTrackColor: AppColors.mint.withValues(alpha: 0.3),
                      inactiveThumbColor: AppColors.textMuted,
                      inactiveTrackColor: const Color(0xFFD1D5DB),
                      onChanged: widget.onToggleTheme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surfaceCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        'Cerrar sesión',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        '¿Estás seguro de que deseas salir del sistema?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onLogout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Salir', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFF87171),
                  size: 18,
                ),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Color(0xFFF87171),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Tarjeta Informativa del Negocio (Personalizable por el Jardinero)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _businessName,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.leafGreen),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Editar datos del negocio',
                          onPressed: () => _editBusinessInfo(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _businessDescription,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'RFC: $_businessRfc',
                      style: const TextStyle(color: AppColors.mint, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tel: $_businessPhone • $_businessAddress',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Horario de atención: $_businessHours',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.mint, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.mint, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _editProfileInfo(BuildContext context) {
    final nameCtrl = TextEditingController(text: _name);
    // Extraer solo dígitos del teléfono actual
    final cleanCurrentPhone = _phone.replaceAll(RegExp(r'[^0-9]'), '');
    final phoneCtrl = TextEditingController(text: cleanCurrentPhone.length > 10 ? cleanCurrentPhone.substring(cleanCurrentPhone.length - 10) : cleanCurrentPhone);
    final emailCtrl = TextEditingController(text: _email == 'Sin registrar' ? '' : _email);
    final cityCtrl = TextEditingController(text: _city);

    String? nameError;
    String? phoneError;
    String? emailError;
    String? cityError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Editar mis datos', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo 1: Nombre (Solo letras, nada de números ni símbolos)
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: AppColors.textPrimary),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nombre completo (solo letras)',
                        errorText: nameError,
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.leafGreen),
                      ),
                      onChanged: (_) {
                        if (nameError != null) setDialogState(() => nameError = null);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Campo 2: Teléfono (Solo números, sin letras)
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: AppColors.textPrimary),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Teléfono celular (10 dígitos)',
                        errorText: phoneError,
                        prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.leafGreen),
                      ),
                      onChanged: (_) {
                        if (phoneError != null) setDialogState(() => phoneError = null);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Campo 3: Correo electrónico (Formato de correo estricto)
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        errorText: emailError,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.leafGreen),
                      ),
                      onChanged: (_) {
                        if (emailError != null) setDialogState(() => emailError = null);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Campo 4: Ciudad (Solo letras)
                    TextField(
                      controller: cityCtrl,
                      style: TextStyle(color: AppColors.textPrimary),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Ciudad (solo letras)',
                        errorText: cityError,
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.leafGreen),
                      ),
                      onChanged: (_) {
                        if (cityError != null) setDialogState(() => cityError = null);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final trimmedName = nameCtrl.text.trim();
                    final rawPhone = phoneCtrl.text.trim();
                    final trimmedEmail = emailCtrl.text.trim();
                    final trimmedCity = cityCtrl.text.trim();

                    // Expresiones regulares para validar condiciones
                    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]{2,60}$');
                    final phoneRegex = RegExp(r'^[0-9]{10}$');
                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    final cityRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]{2,50}$');

                    bool hasErrors = false;

                    // CONDICIÓN 1: Nombre (solo letras, nada de números ni símbolos)
                    if (nameRegex.hasMatch(trimmedName)) {
                      nameError = null;
                    } else {
                      // ELSE: No cumple la condición del nombre
                      nameError = 'Solo se permiten letras en el nombre (sin números ni símbolos).';
                      hasErrors = true;
                    }

                    // CONDICIÓN 2: Celular (solo números, 10 dígitos obligatorios)
                    if (phoneRegex.hasMatch(rawPhone)) {
                      phoneError = null;
                    } else {
                      // ELSE: No cumple la condición del número
                      phoneError = 'El celular debe tener 10 dígitos numéricos (sin letras).';
                      hasErrors = true;
                    }

                    // CONDICIÓN 3: Correo electrónico (formato válido obligatorio)
                    if (emailRegex.hasMatch(trimmedEmail)) {
                      emailError = null;
                    } else {
                      // ELSE: No cumple la condición del correo
                      emailError = 'Ingresa un correo electrónico válido (ej. usuario@gmail.com).';
                      hasErrors = true;
                    }

                    // CONDICIÓN 4: Ciudad (solo letras)
                    if (cityRegex.hasMatch(trimmedCity)) {
                      cityError = null;
                    } else {
                      // ELSE: No cumple la condición de la ciudad
                      cityError = 'La ciudad solo debe contener letras.';
                      hasErrors = true;
                    }

                    // Decisión final: Si hubo algún error en el else, refrescar pantalla de diálogo y bloquear guardado
                    if (hasErrors) {
                      setDialogState(() {});
                      return;
                    } else {
                      // IF todas las condiciones se cumplieron exitosamente:
                      setState(() {
                        _name = trimmedName;
                        _phone = '+52 $rawPhone';
                        _email = trimmedEmail;
                        _city = trimmedCity;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppColors.leafGreen,
                          content: Text('Datos validados y actualizados correctamente.'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBusinessInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(22),
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
                  Expanded(
                    child: Text(
                      _businessName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.leafGreen, size: 20),
                    tooltip: 'Editar',
                    onPressed: () {
                      Navigator.pop(context);
                      _editBusinessInfo(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _businessDescription,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Text('RFC: $_businessRfc', style: const TextStyle(color: AppColors.mint, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Teléfono: $_businessPhone', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(height: 4),
              Text('Dirección: $_businessAddress', style: TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
              const SizedBox(height: 4),
              Text('Horario de atención: $_businessHours', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _editBusinessInfo(context);
                  },
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                  label: const Text('Editar información del negocio', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leafGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editBusinessInfo(BuildContext context) {
    final nameCtrl = TextEditingController(text: _businessName);
    final descCtrl = TextEditingController(text: _businessDescription);
    final rfcCtrl = TextEditingController(text: _businessRfc);
    final phoneCtrl = TextEditingController(text: _businessPhone);
    final addressCtrl = TextEditingController(text: _businessAddress);
    final hoursCtrl = TextEditingController(text: _businessHours);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.business_rounded, color: AppColors.leafGreen),
              SizedBox(width: 8),
              Text('Datos del Negocio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Nombre de la Empresa / Negocio'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Descripción de servicios'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: rfcCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'RFC / Registro Fiscal'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Teléfono comercial'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Dirección física en Yucatán'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hoursCtrl,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Horario de atención'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (nameCtrl.text.trim().isNotEmpty) _businessName = nameCtrl.text.trim();
                  if (descCtrl.text.trim().isNotEmpty) _businessDescription = descCtrl.text.trim();
                  if (rfcCtrl.text.trim().isNotEmpty) _businessRfc = rfcCtrl.text.trim();
                  if (phoneCtrl.text.trim().isNotEmpty) _businessPhone = phoneCtrl.text.trim();
                  if (addressCtrl.text.trim().isNotEmpty) _businessAddress = addressCtrl.text.trim();
                  if (hoursCtrl.text.trim().isNotEmpty) _businessHours = hoursCtrl.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.leafGreen,
                    content: Text('Información del negocio guardada con éxito.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leafGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar Negocio', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
