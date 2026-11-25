import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import '../models/quote_item.dart';
import '../models/garden_photo.dart';

/// Servicio singleton para conexión directa a PostgreSQL 18
/// Diseñado para arquitectura móvil conectada a servidor local en red Wi-Fi
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  // Configuración de conexión por defecto
  String host = '192.168.1.83';
  int port = 5432;
  String database = 'JardinerosAlRescate';
  String username = 'postgres';
  String password = 'Azarel123';

  Connection? _connection;
  bool _isConnecting = false;

  /// Retorna si hay una conexión activa y abierta
  bool get isConnected => _connection != null && _connection!.isOpen;

  /// Actualiza los parámetros de conexión en tiempo de ejecución si el usuario lo requiere
  void updateConfig({
    String? newHost,
    int? newPort,
    String? newDatabase,
    String? newUsername,
    String? newPassword,
  }) {
    if (newHost != null && newHost.isNotEmpty) host = newHost.trim();
    if (newPort != null && newPort > 0) port = newPort;
    if (newDatabase != null && newDatabase.isNotEmpty) database = newDatabase.trim();
    if (newUsername != null && newUsername.isNotEmpty) username = newUsername.trim();
    if (newPassword != null) password = newPassword;
  }

  /// Establece o reutiliza la conexión con PostgreSQL
  Future<Connection> getConnection() async {
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }

    if (_isConnecting) {
      // Espera si ya hay un intento en curso
      while (_isConnecting) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_connection != null && _connection!.isOpen) {
        return _connection!;
      }
    }

    _isConnecting = true;
    try {
      final endpoint = Endpoint(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
      );

      final conn = await Connection.open(
        endpoint,
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: Duration(seconds: 7),
          queryTimeout: Duration(seconds: 15),
        ),
      );

      _connection = conn;
      debugPrint('✅ [DatabaseService] Conectado exitosamente a PostgreSQL ($host:$port/$database)');
      return conn;
    } catch (e) {
      debugPrint('❌ [DatabaseService] Error al conectar a PostgreSQL: $e');
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  /// Prueba la conexión y retorna información detallada del servidor
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final conn = await getConnection();
      final result = await conn.execute("SELECT version(), current_database(), current_user, NOW();");
      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'success': true,
          'version': row[0].toString(),
          'database': row[1].toString(),
          'user': row[2].toString(),
          'now': row[3].toString(),
          'message': 'Conexión establecida correctamente con PostgreSQL 18',
        };
      }
      return {
        'success': true,
        'message': 'Conexión activa pero sin datos devueltos',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'No se pudo conectar a $host:$port. Revisa la IP, contraseña o reglas de firewall.',
      };
    }
  }

  /// Cierra la conexión actual
  Future<void> close() async {
    if (_connection != null) {
      try {
        await _connection!.close();
      } catch (_) {}
      _connection = null;
    }
  }

  // ===========================================================================
  // OPERACIONES CRUD DE LA APLICACIÓN
  // ===========================================================================

  /// Registra o actualiza un cliente en la base de datos
  Future<String> upsertCliente({
    required String nombreCompleto,
    required String telefono,
    String? correo,
    String? direccion,
    String ciudad = 'Mérida, Yucatán',
    String? notas,
  }) async {
    final conn = await getConnection();
    
    // Primero buscar si el cliente ya existe por teléfono
    final existing = await conn.execute(
      Sql.named('SELECT id FROM clientes WHERE telefono = @tel LIMIT 1'),
      parameters: {'tel': telefono},
    );

    if (existing.isNotEmpty) {
      final clientId = existing.first[0].toString();
      await conn.execute(
        Sql.named('''
          UPDATE clientes 
          SET nombre_completo = @nombre,
              correo = COALESCE(@correo, correo),
              direccion = COALESCE(@dir, direccion),
              ciudad = @ciudad,
              actualizado_en = clock_timestamp()
          WHERE id = @id::uuid
        '''),
        parameters: {
          'id': clientId,
          'nombre': nombreCompleto,
          'correo': correo,
          'dir': direccion,
          'ciudad': ciudad,
        },
      );
      return clientId;
    } else {
      final insertResult = await conn.execute(
        Sql.named('''
          INSERT INTO clientes (nombre_completo, telefono, correo, direccion, ciudad, notas)
          VALUES (@nombre, @tel, @correo, @dir, @ciudad, @notas)
          RETURNING id;
        '''),
        parameters: {
          'nombre': nombreCompleto,
          'tel': telefono,
          'correo': correo,
          'dir': direccion,
          'ciudad': ciudad,
          'notas': notas,
        },
      );
      return insertResult.first[0].toString();
    }
  }

  /// Guarda una cotización completa con cliente, detalles de servicios, fotos y cita programada
  Future<Map<String, dynamic>> guardarCotizacionCompleta({
    required String clientName,
    required String clientPhone,
    required String address,
    required DateTime appointmentDate,
    required List<QuoteServiceItem> services,
    required double totalPrice,
    required double totalSquareMeters,
    List<GardenPhoto>? photos,
    String? folio,
    String notas = '',
  }) async {
    final conn = await getConnection();

    // 1. Guardar o vincular cliente
    final clienteId = await upsertCliente(
      nombreCompleto: clientName,
      telefono: clientPhone,
      direccion: address,
      notas: 'Generado desde App Jardineros al Rescate',
    );

    // 2. Generar folio único si no viene uno
    final folioFinal = folio ?? 'COT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // 3. Insertar Cotización
    final cotizacionResult = await conn.execute(
      Sql.named('''
        INSERT INTO cotizaciones (
          folio, 
          cliente_id, 
          subtotal, 
          iva, 
          total, 
          metros_cuadrados_totales, 
          estado, 
          notas_adicionales
        ) VALUES (
          @folio, 
          @cliente_id::uuid, 
          @subtotal, 
          0.00, 
          @total, 
          @m2, 
          'pendiente'::estado_cotizacion_enum, 
          @notas
        ) RETURNING id;
      '''),
      parameters: {
        'folio': folioFinal,
        'cliente_id': clienteId,
        'subtotal': totalPrice,
        'total': totalPrice,
        'm2': totalSquareMeters,
        'notas': notas,
      },
    );

    final cotizacionId = cotizacionResult.first[0].toString();

    // 4. Insertar detalles de servicios
    for (final s in services) {
      if (s.isSelected) {
        await conn.execute(
          Sql.named('''
            INSERT INTO cotizacion_detalles (
              cotizacion_id,
              nombre_servicio,
              tipo_unidad,
              precio_unitario,
              cantidad,
              subtotal,
              es_personalizado
            ) VALUES (
              @cotizacion_id::uuid,
              @nombre,
              @tipo,
              @precio,
              @cantidad,
              @subtotal,
              @es_pers
            );
          '''),
          parameters: {
            'cotizacion_id': cotizacionId,
            'nombre': s.name,
            'tipo': s.isFixedPrice ? 'precio_fijo' : 'metro_cuadrado',
            'precio': s.unitPrice,
            'cantidad': s.quantity,
            'subtotal': s.subtotal,
            'es_pers': s.id.startsWith('custom_'),
          },
        );
      }
    }

    // 5. Agendar Cita en la base de datos
    await conn.execute(
      Sql.named('''
        INSERT INTO citas (
          cotizacion_id,
          cliente_id,
          fecha_cita,
          hora_cita,
          estado,
          notas
        ) VALUES (
          @cotizacion_id::uuid,
          @cliente_id::uuid,
          @fecha,
          '09:00:00',
          'programada'::estado_cita_enum,
          @notas_cita
        );
      '''),
      parameters: {
        'cotizacion_id': cotizacionId,
        'cliente_id': clienteId,
        'fecha': '${appointmentDate.year.toString().padLeft(4, '0')}-${appointmentDate.month.toString().padLeft(2, '0')}-${appointmentDate.day.toString().padLeft(2, '0')}',
        'notas_cita': 'Cita para trabajo o valoración en $address',
      },
    );

    // 6. Guardar fotos con diagnóstico si existen
    if (photos != null && photos.isNotEmpty) {
      for (final p in photos) {
        final isPlant = p.category.toLowerCase().contains('planta') || 
                        p.category.toLowerCase().contains('jardín') ||
                        p.category.toLowerCase().contains('arbol') ||
                        p.category.toLowerCase().contains('césped');
        await conn.execute(
          Sql.named('''
            INSERT INTO diagnosticos_plantas (
              cotizacion_id,
              url_foto,
              categoria_detectada,
              especie_o_etiqueta,
              nivel_confianza,
              es_planta,
              diagnostico,
              tratamiento_recomendado
            ) VALUES (
              @cotizacion_id::uuid,
              @url,
              @cat,
              @especie,
              @conf,
              @es_planta,
              @diag,
              @trat
            );
          '''),
          parameters: {
            'cotizacion_id': cotizacionId,
            'url': p.assetPath ?? 'local_photo_${p.id}',
            'cat': p.category,
            'especie': p.title,
            'conf': p.aiConfidence ?? 0.95,
            'es_planta': isPlant,
            'diag': p.aiDiagnosisStatus ?? (isPlant ? 'Foto registrada en terreno' : 'Elemento no vegetal'),
            'trat': p.aiTreatment ?? (isPlant ? 'Revisión y mantenimiento en visita presencial' : 'Ninguno'),
          },
        );
      }
    }

    return {
      'success': true,
      'folio': folioFinal,
      'cotizacionId': cotizacionId,
      'clienteId': clienteId,
    };
  }

  /// Obtiene las cotizaciones guardadas con datos del cliente
  Future<List<Map<String, dynamic>>> obtenerCotizaciones() async {
    final conn = await getConnection();
    final result = await conn.execute('''
      SELECT 
        c.id, 
        c.folio, 
        cl.nombre_completo AS cliente, 
        cl.telefono, 
        c.total, 
        c.metros_cuadrados_totales, 
        c.estado, 
        c.creado_en
      FROM cotizaciones c
      INNER JOIN clientes cl ON c.cliente_id = cl.id
      ORDER BY c.creado_en DESC
      LIMIT 50;
    ''');

    return result.map((row) {
      return {
        'id': row[0].toString(),
        'folio': row[1].toString(),
        'cliente': row[2].toString(),
        'telefono': row[3].toString(),
        'total': (row[4] as num).toDouble(),
        'm2': (row[5] as num).toDouble(),
        'estado': row[6].toString(),
        'creado_en': row[7].toString(),
      };
    }).toList();
  }

  /// Obtiene los clientes registrados
  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    final conn = await getConnection();
    final result = await conn.execute('''
      SELECT id, nombre_completo, telefono, correo, direccion, ciudad, creado_en
      FROM clientes
      ORDER BY creado_en DESC
      LIMIT 100;
    ''');

    return result.map((row) {
      return {
        'id': row[0].toString(),
        'nombre': row[1].toString(),
        'telefono': row[2].toString(),
        'correo': row[3]?.toString() ?? '',
        'direccion': row[4]?.toString() ?? '',
        'ciudad': row[5]?.toString() ?? '',
        'creado_en': row[6].toString(),
      };
    }).toList();
  }

  /// Obtiene los movimientos financieros y servicios en proceso o realizados
  Future<List<Map<String, dynamic>>> obtenerMovimientosFinancieros() async {
    final conn = await getConnection();
    final result = await conn.execute('''
      SELECT 
        m.id,
        c.nombre_completo AS cliente,
        m.tipo_servicio,
        m.monto,
        m.estado_pago,
        m.metodo_pago,
        m.fecha_movimiento,
        m.notas
      FROM movimientos_financieros m
      INNER JOIN clientes c ON m.cliente_id = c.id
      ORDER BY m.fecha_movimiento DESC, m.creado_en DESC
      LIMIT 100;
    ''');

    return result.map((row) {
      return {
        'id': row[0].toString(),
        'cliente': row[1].toString(),
        'tipo_servicio': row[2].toString(),
        'monto': (row[3] as num).toDouble(),
        'estado_pago': row[4].toString(),
        'metodo_pago': row[5].toString(),
        'fecha': row[6].toString(),
        'notas': row[7]?.toString() ?? '',
      };
    }).toList();
  }

  /// Actualiza el estado de cobro de un servicio en la base de datos
  Future<void> actualizarEstadoPagoMovimiento({
    required String movimientoId,
    required String nuevoEstado,
    String? nuevoMetodo,
    String? notas,
  }) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('''
        UPDATE movimientos_financieros
        SET estado_pago = @estado::estado_pago_enum,
            metodo_pago = COALESCE(@metodo::metodo_pago_enum, metodo_pago),
            notas = COALESCE(@notas, notas),
            fecha_pago = CASE WHEN @estado = 'pagado' THEN clock_timestamp() ELSE fecha_pago END,
            actualizado_en = clock_timestamp()
        WHERE id = @id::uuid;
      '''),
      parameters: {
        'id': movimientoId,
        'estado': nuevoEstado.toLowerCase(),
        'metodo': nuevoMetodo?.toLowerCase().replaceAll(' ', '_'),
        'notas': notas,
      },
    );
  }
}
