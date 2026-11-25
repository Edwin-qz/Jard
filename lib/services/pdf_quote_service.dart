import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/quote_item.dart';

class PdfQuoteService {
  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

  /// Genera el documento PDF formal con el logo del jardinero, precios por m²,
  /// fecha, servicios, número de cliente y día de confirmación de cita.
  static Future<pw.Document> buildPdfDocument({
    required String clientName,
    required String clientPhone,
    required String address,
    required String appointmentConfirmationDate,
    required String quoteDate,
    required List<QuoteServiceItem> services,
    required double totalPrice,
  }) async {
    final pdf = pw.Document();

    // Cargar la imagen del logo del jardinero desde los assets
    pw.MemoryImage? logoImage;
    try {
      final logoBytes =
          await rootBundle.load('assets/images/logo_pdf_jardinero.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // Fallback si por alguna razón la imagen no carga
      try {
        final logoBytesJpg =
            await rootBundle.load('assets/images/logo_pdf_jardinero.jpg');
        logoImage = pw.MemoryImage(logoBytesJpg.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }
    }

    final selectedServices =
        services.where((s) => s.isSelected && s.quantity > 0).toList();

    final totalSquareMeters = selectedServices
        .where((s) => !s.isFixedPrice)
        .fold<double>(0.0, (sum, item) => sum + item.quantity);

    String formatM2(double value) =>
        value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1);

    // Paleta de colores para el PDF (Elegante verde hoja natural y pizarra)
    const primaryGreen = PdfColor.fromInt(0xFF2EA043); // Verde hoja natural
    const darkForest = PdfColor.fromInt(0xFF1B6B2E); // Verde follaje profundo
    const softGreenBg = PdfColor.fromInt(0xFFF0FDF4);
    const textDark = PdfColor.fromInt(0xFF0F172A);
    const textGray = PdfColor.fromInt(0xFF475569);
    const borderGray = PdfColor.fromInt(0xFFE2E8F0);
    const white = PdfColor.fromInt(0xFFFFFFFF);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ENCABEZADO CON EL LOGO DEL JARDINERO
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: borderGray, width: 1.5),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // LOGO DEL JARDINERO (Solo en el PDF)
                    if (logoImage != null)
                      pw.Container(
                        width: 82,
                        height: 82,
                        margin: const pw.EdgeInsets.only(right: 16),
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: primaryGreen, width: 2),
                        ),
                        child: pw.ClipOval(
                          child: pw.Image(logoImage, fit: pw.BoxFit.cover),
                        ),
                      )
                    else
                      pw.Container(
                        width: 82,
                        height: 82,
                        margin: const pw.EdgeInsets.only(right: 16),
                        decoration: const pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: primaryGreen,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'JAR',
                            style: pw.TextStyle(
                              color: white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),

                    // Títulos del negocio
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'JARDINEROS AL RESCATE',
                            style: pw.TextStyle(
                              color: darkForest,
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Saul Cruz • Servicios Profesionales de Jardinería y Paisajismo',
                            style: pw.TextStyle(
                              color: primaryGreen,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Cotizaciones especializadas por metro cuadrado (m²)',
                            style: const pw.TextStyle(
                              color: textGray,
                              fontSize: 9,
                            ),
                          ),
                          pw.Text(
                            'WhatsApp: +52 999 782 1096 • Mérida, Yucatán • RFC: JAL210915AB3',
                            style: const pw.TextStyle(
                              color: textGray,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Folio y Fecha del Presupuesto
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: pw.BoxDecoration(
                        color: softGreenBg,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: primaryGreen, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'PRESUPUESTO',
                            style: pw.TextStyle(
                              color: darkForest,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Fecha: $quoteDate',
                            style: const pw.TextStyle(
                              color: textDark,
                              fontSize: 9,
                            ),
                          ),
                          pw.Text(
                            'Folio: JAR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            style: pw.TextStyle(
                              color: primaryGreen,
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // RECUADRO DESTACADO: DÍA DE CONFIRMACIÓN DE LA CITA
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFECFDF5),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: const PdfColor.fromInt(0xFF10B981),
                    width: 1.2,
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 8,
                          height: 8,
                          decoration: const pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFF10B981),
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          'DÍA DE CONFIRMACIÓN DE LA CITA:',
                          style: pw.TextStyle(
                            color: darkForest,
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          appointmentConfirmationDate,
                          style: pw.TextStyle(
                            color: const PdfColor.fromInt(0xFF047857),
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        color: white,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                          color: const PdfColor.fromInt(0xFF10B981),
                          width: 0.8,
                        ),
                      ),
                      child: pw.Text(
                        'ESTADO: CITA CONFIRMADA',
                        style: pw.TextStyle(
                          color: darkForest,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // DATOS DEL CLIENTE (Nombre, Teléfono / Número de cliente, Dirección)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF8FAFC),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderGray, width: 1),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Columna 1
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'NOMBRE DEL CLIENTE:',
                            style: const pw.TextStyle(
                              color: textGray,
                              fontSize: 8,
                            ),
                          ),
                          pw.Text(
                            clientName.isEmpty ? 'Cliente General' : clientName,
                            style: pw.TextStyle(
                              color: textDark,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'NÚMERO DE CLIENTE / WHATSAPP:',
                            style: const pw.TextStyle(
                              color: textGray,
                              fontSize: 8,
                            ),
                          ),
                          pw.Text(
                            clientPhone.isEmpty ? 'No especificado' : clientPhone,
                            style: pw.TextStyle(
                              color: primaryGreen,
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Columna 2
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DIRECCIÓN DEL SERVICIO:',
                            style: const pw.TextStyle(
                              color: textGray,
                              fontSize: 8,
                            ),
                          ),
                          pw.Text(
                            address.isEmpty ? 'Dirección a convenir' : address,
                            style: pw.TextStyle(
                              color: textDark,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'TIPO DE COTIZACIÓN:',
                            style: const pw.TextStyle(
                              color: textGray,
                              fontSize: 8,
                            ),
                          ),
                          pw.Text(
                            'Presupuesto por Metro Cuadrado (m²)',
                            style: const pw.TextStyle(
                              color: textDark,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // TABLA DE SERVICIOS POR METRO CUADRADO
              pw.Text(
                'DESGLOSE DE SERVICIOS POR METRO CUADRADO (m²)',
                style: pw.TextStyle(
                  color: darkForest,
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

              // Table
              pw.Table(
                border: pw.TableBorder.all(
                  color: borderGray,
                  width: 1,
                  style: pw.BorderStyle.solid,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.6), // #
                  1: const pw.FlexColumnWidth(3.0), // Servicio
                  2: const pw.FlexColumnWidth(1.2), // m²
                  3: const pw.FlexColumnWidth(1.4), // Precio unitario
                  4: const pw.FlexColumnWidth(1.5), // Subtotal
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: primaryGreen),
                    children: [
                      _buildHeaderCell('#', align: pw.TextAlign.center),
                      _buildHeaderCell('SERVICIO'),
                      _buildHeaderCell('SUPERFICIE', align: pw.TextAlign.center),
                      _buildHeaderCell('PRECIO UNITARIO', align: pw.TextAlign.right),
                      _buildHeaderCell('SUBTOTAL', align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Body
                  ...selectedServices.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    final isEven = entry.key % 2 == 0;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven
                            ? white
                            : const PdfColor.fromInt(0xFFF8FAFC),
                      ),
                      children: [
                        _buildDataCell('$index', align: pw.TextAlign.center),
                        _buildDataCell(item.name, isBold: true),
                        _buildDataCell(
                          item.isFixedPrice ? 'Precio fijo' : '${formatM2(item.quantity)} m²',
                          align: pw.TextAlign.center,
                        ),
                        _buildDataCell(
                          item.isFixedPrice
                              ? '${_currencyFormat.format(item.unitPrice)} (fijo)'
                              : '${_currencyFormat.format(item.unitPrice)} / m²',
                          align: pw.TextAlign.right,
                        ),
                        _buildDataCell(
                          _currencyFormat.format(item.subtotal),
                          align: pw.TextAlign.right,
                          isBold: true,
                          color: darkForest,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 14),

              // RESUMEN DE TOTALES
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Notas y Condiciones
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF8FAFC),
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: borderGray, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'TÉRMINOS & CONDICIONES:',
                            style: pw.TextStyle(
                              color: darkForest,
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '• Cotización calculada sobre ${formatM2(totalSquareMeters)} m² totales de área de trabajo.',
                            style: const pw.TextStyle(color: textGray, fontSize: 7.5),
                          ),
                          pw.Text(
                            '• Cita confirmada sujeta al día y horario programado.',
                            style: const pw.TextStyle(color: textGray, fontSize: 7.5),
                          ),
                          pw.Text(
                            '• Incluye preparación, insumos certificados y retiro de follaje.',
                            style: const pw.TextStyle(color: textGray, fontSize: 7.5),
                          ),
                          pw.Text(
                            '• Precios en Moneda Nacional (MXN). Validez: 15 días naturales.',
                            style: const pw.TextStyle(color: textGray, fontSize: 7.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 16),

                  // Caja de Precio Total
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: softGreenBg,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: primaryGreen, width: 1.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Superficie total:',
                              style: const pw.TextStyle(color: textGray, fontSize: 9),
                            ),
                            pw.Text(
                              '${formatM2(totalSquareMeters)} m²',
                              style: pw.TextStyle(
                                color: textDark,
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Subtotal servicios:',
                              style: const pw.TextStyle(color: textGray, fontSize: 9),
                            ),
                            pw.Text(
                              _currencyFormat.format(totalPrice),
                              style: const pw.TextStyle(color: textDark, fontSize: 9.5),
                            ),
                          ],
                        ),
                        pw.Divider(color: primaryGreen, thickness: 0.8),
                        pw.SizedBox(height: 2),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL A PAGAR:',
                              style: pw.TextStyle(
                                color: darkForest,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              _currencyFormat.format(totalPrice),
                              style: pw.TextStyle(
                                color: darkForest,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // SELLO DE GARANTÍA Y FIRMAS
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 12),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: borderGray, width: 1),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Firma Saul Cruz
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          height: 1,
                          color: textDark,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Saul Cruz',
                          style: pw.TextStyle(
                            color: textDark,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Jardineros Al Rescate',
                          style: const pw.TextStyle(
                            color: textGray,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),

                    // Leyenda de Garantía
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: softGreenBg,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                          color: const PdfColor.fromInt(0xFF10B981),
                          width: 1,
                        ),
                      ),
                      child: pw.Text(
                        '✓ GARANTÍA DE SATISFACCIÓN 100%',
                        style: pw.TextStyle(
                          color: darkForest,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),

                    // Firma Cliente
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          height: 1,
                          color: textDark,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          clientName.isEmpty ? 'Firma del Cliente' : clientName,
                          style: pw.TextStyle(
                            color: textDark,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Aceptación de Presupuesto',
                          style: const pw.TextStyle(
                            color: textGray,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeaderCell(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: const PdfColor.fromInt(0xFFFFFFFF),
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildDataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    PdfColor color = const PdfColor.fromInt(0xFF0F172A),
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Genera y guarda temporalmente el archivo PDF, retornando su File
  static Future<File> savePdfToFile({
    required String clientName,
    required String clientPhone,
    required String address,
    required String appointmentConfirmationDate,
    required String quoteDate,
    required List<QuoteServiceItem> services,
    required double totalPrice,
  }) async {
    final pdf = await buildPdfDocument(
      clientName: clientName,
      clientPhone: clientPhone,
      address: address,
      appointmentConfirmationDate: appointmentConfirmationDate,
      quoteDate: quoteDate,
      services: services,
      totalPrice: totalPrice,
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final cleanClientName =
        clientName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filePath =
        '${tempDir.path}/Cotizacion_JardinerosAlRescate_${cleanClientName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Construye el mensaje formal optimizado para enviar por WhatsApp
  static String buildWhatsAppMessage({
    required String clientName,
    required String clientPhone,
    required String address,
    required String appointmentConfirmationDate,
    required String quoteDate,
    required List<QuoteServiceItem> services,
    required double totalPrice,
    int photosCount = 0,
  }) {
    final selectedServices =
        services.where((s) => s.isSelected && s.quantity > 0).toList();
    final totalM2 = selectedServices
        .where((s) => !s.isFixedPrice)
        .fold<double>(0.0, (sum, item) => sum + item.quantity);
    String formatM2(double value) =>
        value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1);

    final buffer = StringBuffer();
    buffer.writeln('🌿 *JARDINEROS AL RESCATE (Mérida, Yucatán)* 🌿');
    buffer.writeln('¡Hola *$clientName*! Te compartimos tu presupuesto formal:');
    buffer.writeln('');
    buffer.writeln('📅 *Fecha de cotización:* $quoteDate');
    buffer.writeln('🗓️ *Día de confirmación de cita:* $appointmentConfirmationDate');
    buffer.writeln('📱 *Número de cliente:* $clientPhone');
    buffer.writeln('📍 *Ubicación del servicio:* $address');
    if (totalM2 > 0) {
      buffer.writeln('📐 *Superficie evaluada por m²:* ${formatM2(totalM2)} m²');
    }
    if (photosCount > 0) {
      buffer.writeln('📸 *Evidencia fotográfica:* $photosCount fotos del terreno adjuntas');
    }
    buffer.writeln('');
    buffer.writeln('📋 *Desglose de servicios:*');
    for (final s in selectedServices) {
      if (s.isFixedPrice) {
        buffer.writeln('  • *${s.name}*: Precio Fijo = *${_currencyFormat.format(s.subtotal)}*');
      } else {
        buffer.writeln('  • *${s.name}*: ${formatM2(s.quantity)} m² (${_currencyFormat.format(s.unitPrice)}/m²) = *${_currencyFormat.format(s.subtotal)}*');
      }
    }
    buffer.writeln('');
    buffer.writeln('💰 *TOTAL ESTIMADO: ${_currencyFormat.format(totalPrice)} MXN*');
    buffer.writeln('');
    buffer.writeln('📄 *Adjunto encontrarás el documento PDF oficial con nuestro logotipo y confirmación de cita.*');
    buffer.writeln('¡Agradecemos tu confianza! Quedamos a tus órdenes. 🪴👨‍🌾');

    return buffer.toString();
  }

  /// Abre la API directa de WhatsApp (wa.me) con el mensaje de cotización
  static Future<bool> openWhatsAppDirectMessage({
    required String clientPhone,
    required String message,
  }) async {
    // Limpiar caracteres del número telefónico
    String cleanPhone = clientPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 10) {
      // Prefijo México si son 10 dígitos
      cleanPhone = '52$cleanPhone';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final urlString = cleanPhone.isNotEmpty
        ? 'https://wa.me/$cleanPhone?text=$encodedMessage'
        : 'https://api.whatsapp.com/send?text=$encodedMessage';

    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      return false;
    }
  }

  /// Comparte el archivo PDF directamente por WhatsApp o app seleccionada (Share Sheet)
  static Future<void> sharePdfViaWhatsApp({
    required String clientName,
    required String clientPhone,
    required String address,
    required String appointmentConfirmationDate,
    required String quoteDate,
    required List<QuoteServiceItem> services,
    required double totalPrice,
    int photosCount = 0,
  }) async {
    final pdfFile = await savePdfToFile(
      clientName: clientName,
      clientPhone: clientPhone,
      address: address,
      appointmentConfirmationDate: appointmentConfirmationDate,
      quoteDate: quoteDate,
      services: services,
      totalPrice: totalPrice,
    );

    final whatsappText = buildWhatsAppMessage(
      clientName: clientName,
      clientPhone: clientPhone,
      address: address,
      appointmentConfirmationDate: appointmentConfirmationDate,
      quoteDate: quoteDate,
      services: services,
      totalPrice: totalPrice,
      photosCount: photosCount,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            pdfFile.path,
            mimeType: 'application/pdf',
            name:
                'Cotizacion_JardinerosAlRescate_${clientName.replaceAll(' ', '_')}.pdf',
          ),
        ],
        text: whatsappText,
        subject: 'Cotización Oficial Jardineros Al Rescate - $clientName',
      ),
    );
  }

  /// Permite previsualizar e imprimir el PDF generado
  static Future<void> previewPdf({
    required String clientName,
    required String clientPhone,
    required String address,
    required String appointmentConfirmationDate,
    required String quoteDate,
    required List<QuoteServiceItem> services,
    required double totalPrice,
  }) async {
    final pdf = await buildPdfDocument(
      clientName: clientName,
      clientPhone: clientPhone,
      address: address,
      appointmentConfirmationDate: appointmentConfirmationDate,
      quoteDate: quoteDate,
      services: services,
      totalPrice: totalPrice,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Cotizacion_JardinerosAlRescate_${clientName.replaceAll(' ', '_')}.pdf',
    );
  }
}
