import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

/// Các hàm tiện ích dùng chung trong CareLens
class AppUtils {
  AppUtils._();

  // ─── Định dạng ngày giờ ────────────────────────────────────────────────

  /// Định dạng ngày: dd/MM/yyyy
  static String formatDate(DateTime date) =>
      DateFormat(AppConstants.dateFormat).format(date);

  /// Định dạng ngày giờ: dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime date) =>
      DateFormat(AppConstants.dateTimeFormat).format(date);

  /// Định dạng giờ: HH:mm
  static String formatTime(DateTime date) =>
      DateFormat(AppConstants.timeFormat).format(date);

  /// Lấy lời chào theo thời điểm trong ngày
  /// - 04:00 - 11:59: "Chào buổi sáng"
  /// - 12:00 - 17:59: "Chào buổi chiều"
  /// - 18:00 - 03:59: "Chào buổi tối"
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'Chào buổi sáng';
    } else if (hour >= 12 && hour < 18) {
      return 'Chào buổi chiều';
    } else {
      return 'Chào buổi tối';
    }
  }

  // ─── Kiểm tra sức khỏe ────────────────────────────────────────────────

  /// Đánh giá huyết áp (mmHg)
  static HealthStatus evaluateBloodPressure(
    double systolic,
    double diastolic,
  ) {
    if (systolic >= AppConstants.bpSystolicHigh ||
        diastolic >= AppConstants.bpDiastolicHigh) {
      return HealthStatus.danger;
    }
    if (systolic < AppConstants.bpSystolicLow ||
        diastolic < AppConstants.bpDiastolicLow) {
      return HealthStatus.warning;
    }
    return HealthStatus.normal;
  }

  /// Đánh giá nhịp tim (bpm)
  static HealthStatus evaluateHeartRate(double bpm) {
    if (bpm > AppConstants.heartRateHigh || bpm < AppConstants.heartRateLow) {
      return HealthStatus.danger;
    }
    return HealthStatus.normal;
  }

  /// Đánh giá SpO2 (%)
  static HealthStatus evaluateOxygen(double spo2) {
    if (spo2 < AppConstants.oxygenLow) return HealthStatus.danger;
    if (spo2 < 97) return HealthStatus.warning;
    return HealthStatus.normal;
  }

  // ─── UI Helpers ───────────────────────────────────────────────────────

  /// Hiển thị SnackBar thông báo
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppColors.errorRed : AppColors.accentGreenDark,
      ),
    );
  }

  /// Hiển thị dialog xác nhận
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Trạng thái sức khỏe
enum HealthStatus {
  normal,   // Bình thường
  warning,  // Cần chú ý
  danger,   // Nguy hiểm
}

extension HealthStatusExtension on HealthStatus {
  Color get color {
    switch (this) {
      case HealthStatus.normal:
        return AppColors.successGreen;
      case HealthStatus.warning:
        return AppColors.warningOrange;
      case HealthStatus.danger:
        return AppColors.errorRed;
    }
  }

  String get label {
    switch (this) {
      case HealthStatus.normal:
        return 'Bình thường';
      case HealthStatus.warning:
        return 'Cần chú ý';
      case HealthStatus.danger:
        return 'Cần gặp bác sĩ';
    }
  }

  IconData get icon {
    switch (this) {
      case HealthStatus.normal:
        return Icons.check_circle_rounded;
      case HealthStatus.warning:
        return Icons.warning_amber_rounded;
      case HealthStatus.danger:
        return Icons.emergency_rounded;
    }
  }
}
