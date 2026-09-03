import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/prescription.dart';
import '../utils/app_utils.dart';

/// Dịch vụ tạo và xuất báo cáo PDF đơn thuốc và sức khỏe (Hoạt động hoàn toàn Offline)
class PdfExportService {
  PdfExportService._();
  static final PdfExportService instance = PdfExportService._();

  // ─── Tạo tệp PDF Báo cáo Đơn Thuốc ─────────────────────────────────────

  /// Tạo tài liệu PDF chuyên nghiệp chứa danh sách đơn thuốc và chỉ số
  Future<File> generatePrescriptionPdf({
    required List<Prescription> prescriptions,
    String? patientName,
  }) async {
    final pdf = pw.Document(
      title: 'Báo cáo đơn thuốc CareLens',
      author: 'CareLens Health App',
    );

    final todayStr = AppUtils.formatDate(DateTime.now());
    final nowStr = AppUtils.formatDateTime(DateTime.now());
    final total = prescriptions.length;
    final takenCount = prescriptions.where((p) => p.isTaken).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // ─── Tiêu đề Báo Cáo ─────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.teal700,
                    width: 2,
                  ),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CARELENS - BÁO CÁO ĐƠN THUỐC',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Ứng dụng chăm sóc sức khỏe thông minh cho người cao tuổi',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Ngày lập: $todayStr',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Giờ xuất: $nowStr',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // ─── Thẻ Tóm Tắt Tình Trạng Uống Thuốc ─────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.teal200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildPdfStatItem('Tổng số thuốc', '$total loại thuốc'),
                  _buildPdfStatItem('Đã uống hôm nay', '$takenCount liều'),
                  _buildPdfStatItem(
                    'Chưa uống',
                    '${total - takenCount} liều',
                  ),
                  _buildPdfStatItem(
                    'Tỷ lệ hoàn thành',
                    '${total > 0 ? ((takenCount / total) * 100).toStringAsFixed(0) : 0}%',
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ─── Tiêu đề Danh Sách Thuốc ───────────────────────────
            pw.Text(
              'DANH SÁCH THUỐC VÀ LỊCH UỐNG CHI TIẾT',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),

            pw.SizedBox(height: 8),

            // ─── Bảng Đơn Thuốc ────────────────────────────────────
            if (prescriptions.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Chưa có dữ liệu đơn thuốc nào được ghi nhận.',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: [
                  'STT',
                  'Tên thuốc',
                  'Liều dùng',
                  'Giờ uống',
                  'Tần suất',
                  'Trạng thái',
                  'Lưu ý bác sĩ',
                ],
                data: prescriptions.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final p = entry.value;
                  return [
                    '$index',
                    p.medicineName,
                    p.dosage,
                    p.scheduleTime,
                    p.frequency,
                    p.isTaken ? 'ĐÃ UỐNG' : 'CHƯA UỐNG',
                    p.instructions ?? 'Theo chỉ dẫn bác sĩ',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.teal800,
                ),
                cellStyle: const pw.TextStyle(
                  fontSize: 9,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
              ),

            pw.SizedBox(height: 24),

            // ─── Khuyến cáo Y Tế & Chữ Ký ──────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.amber300),
              ),
              child: pw.Text(
                'LƯU Ý QUAN TRỌNG: Báo cáo này được tổng hợp từ ứng dụng CareLens nhằm mục đích hỗ trợ theo dõi lịch uống thuốc cá nhân. Mọi thay đổi về liều lượng và loại thuốc phải tuân thủ nghiêm ngặt chỉ định của Bác sĩ chuyên khoa.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.brown800,
                ),
              ),
            ),

            pw.SizedBox(height: 30),

            // ─── Phần Ký Tên Bác sĩ / Người Giám Hộ ───────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Người bệnh / Người chăm sóc',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      '(Ký và ghi rõ họ tên)',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Bác sĩ / Dược sĩ phụ trách',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      '(Ký và đóng dấu xác nhận)',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Lưu tệp PDF vào thư mục tạm thời của ứng dụng
    final outputDir = await getTemporaryDirectory();
    final fileName =
        'BaoCao_DonThuoc_CareLens_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    developer.log('Tệp PDF đã được tạo tại: ${file.path}');
    return file;
  }

  // ─── Chia sẻ Báo Cáo PDF qua Zalo, Email, Drive ────────────────────────

  /// Tạo và mở hộp thoại chia sẻ tệp PDF qua các ứng dụng khác
  Future<void> sharePdfReport({
    required BuildContext context,
    required List<Prescription> prescriptions,
  }) async {
    try {
      final file = await generatePrescriptionPdf(
        prescriptions: prescriptions,
      );

      final todayStr = AppUtils.formatDate(DateTime.now());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'Báo cáo đơn thuốc CareLens - Ngày $todayStr',
        subject: 'Báo cáo lịch uống thuốc CareLens ($todayStr)',
      );
    } catch (e) {
      developer.log('Lỗi khi chia sẻ tệp PDF: $e');
      if (context.mounted) {
        AppUtils.showSnackBar(
          context,
          'Không thể chia sẻ báo cáo: $e',
          isError: true,
        );
      }
    }
  }

  // ─── Chia sẻ Định dạng Văn Bản Nhanh (CSV / Text) ─────────────────────

  /// Chia sẻ danh sách đơn thuốc dưới dạng tin nhắn văn bản dễ đọc
  Future<void> shareTextMessage({
    required BuildContext context,
    required List<Prescription> prescriptions,
  }) async {
    try {
      final todayStr = AppUtils.formatDate(DateTime.now());
      final buffer = StringBuffer();
      buffer.writeln('📋 CARELENS - BÁO CÁO ĐƠN THUỐC ($todayStr)');
      buffer.writeln('====================================');
      buffer.writeln('');

      for (int i = 0; i < prescriptions.length; i++) {
        final p = prescriptions[i];
        final status = p.isTaken ? '✅ Đã uống' : '⏰ Chưa uống';
        buffer.writeln('${i + 1}. ${p.medicineName}');
        buffer.writeln('   - Liều dùng: ${p.dosage}');
        buffer.writeln('   - Giờ uống: ${p.scheduleTime} (${p.frequency})');
        buffer.writeln('   - Trạng thái: $status');
        if (p.instructions != null && p.instructions!.isNotEmpty) {
          buffer.writeln('   - Lưu ý: ${p.instructions}');
        }
        buffer.writeln('');
      }

      buffer.writeln('====================================');
      buffer.writeln('Được xuất tự động từ ứng dụng CareLens.');

      await Share.share(
        buffer.toString(),
        subject: 'Báo cáo đơn thuốc CareLens ($todayStr)',
      );
    } catch (e) {
      developer.log('Lỗi khi chia sẻ văn bản: $e');
      if (context.mounted) {
        AppUtils.showSnackBar(
          context,
          'Không thể chia sẻ tin nhắn: $e',
          isError: true,
        );
      }
    }
  }

  // ─── Helper Widget PDF ───────────────────────────────────────────────────

  static pw.Widget _buildPdfStatItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal900,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }
}
