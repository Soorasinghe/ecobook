// lib/services/pdf_invoice_service.dart
import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart' show NetworkImage;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfInvoiceService {
  Future<Uint8List> generateInvoice(
    Map<String, dynamic> orderDetails,
    String? paymentDetails,
  ) async {
    final pdf = pw.Document();
    final businessName = "Your Business Name"; // You can fetch this later
    final orderId = orderDetails['id'].substring(0, 8).toUpperCase();
    final orderDate = DateFormat(
      'MMM dd, yyyy',
    ).format(DateTime.parse(orderDetails['order_date']));
    final customerName = orderDetails['customer_name'];
    final items = (orderDetails['items'] as List);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    businessName,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),

              // Invoice Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Billed to:'),
                      pw.Text(
                        customerName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice #: $orderId'),
                      pw.Text('Date: $orderDate'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Table Header
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1.5)),
                ),
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Item Description',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Qty',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Price',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Rows (List of items)
              for (var item in items)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(item['product_name']),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${item['quantity']}',
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          item['price_at_purchase'],
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          (double.parse(item['price_at_purchase']) *
                                  (item['quantity'] as int))
                              .toStringAsFixed(2),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              pw.Divider(),

              // Total
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Grand Total: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  pw.Text(
                    'LKR ${orderDetails['total_amount']}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // QR Code Section
              if (paymentDetails != null && paymentDetails.isNotEmpty)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: paymentDetails,
                      width: 80,
                      height: 80,
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text('Scan to Pay'),
                  ],
                ),

              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Thank you for your business!')),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  void printInvoice(
    Map<String, dynamic> orderDetails,
    String? paymentDetails,
  ) async {
    final pdfBytes = await generateInvoice(orderDetails, paymentDetails);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  Future<void> generateAndShareInvoice(
    Map<String, dynamic> orderDetails,
    String? paymentDetails,
  ) async {
    final pdfBytes = await generateInvoice(orderDetails, paymentDetails);

    final xFile = XFile.fromData(
      pdfBytes,
      name: 'Invoice_${orderDetails['id'].substring(0, 8)}.pdf',
      mimeType: 'application/pdf',
    );

    await Share.shareXFiles([
      xFile,
    ], text: 'Here is your invoice from Your Business Name');
  }

  // V-- THIS FUNCTION HAS BEEN UPDATED FOR ROBUSTNESS --V
  Future<void> generateAndShareCatalog(
    List<dynamic> products,
    String businessName,
  ) async {
    final pdf = pw.Document();

    // Create a list to hold the fetched image bytes, allowing for nulls if an image fails
    final List<Uint8List?> images = [];
    for (var p in products) {
      final imageUrl = p['image_url'] as String?;
      // Only try to fetch if the URL is not null and not empty
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Fetch image bytes from the network
          final imageBytes = await networkImage(imageUrl);
          images.add(imageBytes as Uint8List?);
        } catch (e) {
          print('Could not fetch image for product ${p['name']}: $e');
          images.add(null); // Add null if fetching fails
        }
      } else {
        images.add(null); // Add null if there is no URL
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Column(
          children: [
            pw.Text(
              businessName,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24),
            ),
            pw.Text(
              'Product Catalog',
              style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey),
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Center(
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: PdfColors.grey),
          ),
        ),
        build: (pw.Context context) {
          return [
            pw.GridView(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75, // Adjust this to change item shape
              children: List.generate(products.length, (index) {
                final product = products[index];
                final image = images[index];
                return pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        // Image container
                        height: 150,
                        width: double.infinity,
                        child: image != null
                            ? pw.Image(pw.MemoryImage(image))
                            : pw.Center(
                                child: pw.Text(
                                  'No Image',
                                  style: const pw.TextStyle(
                                    color: PdfColors.grey,
                                  ),
                                ),
                              ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        product['name'],
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        maxLines: 2,
                        overflow: pw.TextOverflow.clip,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'LKR ${product['price']}',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.teal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();

    final xFile = XFile.fromData(
      pdfBytes,
      name: 'Catalog_${businessName.replaceAll(' ', '_')}.pdf',
      mimeType: 'application/pdf',
    );
    await Share.shareXFiles([xFile], text: 'Here is our new product catalog!');
  }
}
