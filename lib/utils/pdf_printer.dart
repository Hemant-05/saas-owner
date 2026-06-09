import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

class PdfPrinterUtil {
  /// Generate and print a receipt for an order
  static Future<void> printReceipt(Order order, {String? restaurantName, String? restaurantPhone, String? restaurantGstNumber}) async {
    final pdf = pw.Document();

    // 80mm thermal receipt width is typically around 58mm to 80mm.
    // 80mm is about 3.14 inches.
    // At 72 DPI, 3.14 inches is ~226 points width.
    // Roll paper length is essentially infinite, but we let the PDF package handle it.
    const pageFormat = PdfPageFormat.roll80;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return _buildReceiptContent(order, restaurantName ?? 'QR Cafe', restaurantPhone, restaurantGstNumber);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${order.orderNumber}',
    );
  }

  static pw.Widget _buildReceiptContent(Order order, String restaurantName, String? restaurantPhone, String? restaurantGstNumber) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final String dateString = order.placedAt != null 
        ? dateFormat.format(DateTime.parse(order.placedAt!).toLocal()) 
        : dateFormat.format(DateTime.now());

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            restaurantName,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ),
        if (restaurantPhone != null && restaurantPhone.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text('Ph: $restaurantPhone', style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
        if (restaurantGstNumber != null && restaurantGstNumber.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Center(
            child: pw.Text('GST: $restaurantGstNumber', style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'TAX RECEIPT',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        pw.SizedBox(height: 5),

        // Order Info
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Order No:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(order.orderNumber, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Table:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('${order.tableNumber} - ${order.tableName}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(dateString, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        
        pw.SizedBox(height: 5),
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        pw.SizedBox(height: 5),

        // Items Header
        pw.Row(
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Text('Item', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text('Qty', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            ),
            pw.Expanded(
              flex: 3,
              child: pw.Text('Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        pw.SizedBox(height: 5),

        // Items List
        ...order.items.map((item) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.name, style: const pw.TextStyle(fontSize: 10)),
                      if (item.customization.isNotEmpty)
                        pw.Text(
                          item.customization, 
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    item.subtotal.toStringAsFixed(2), 
                    style: const pw.TextStyle(fontSize: 10), 
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),

        pw.SizedBox(height: 5),
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        pw.SizedBox(height: 5),

        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(order.subtotal.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Tax (${order.taxPercent}%):', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(order.taxAmount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(order.totalAmount.toStringAsFixed(2), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        
        pw.SizedBox(height: 5),
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        pw.SizedBox(height: 5),

        // Payment Info
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Payment:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              order.paymentMethod.replaceAll('_', ' ').toUpperCase(),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Status:', style: const pw.TextStyle(fontSize: 10)),
            pw.Text(
              order.paymentStatus.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            'Thank you for your visit!',
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }
}
