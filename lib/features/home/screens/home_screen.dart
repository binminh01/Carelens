import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/prescription.dart';
import '../../../core/services/isar_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

/// Màn hình Trang chủ thân thiện cho người cao tuổi (Elderly-Friendly Home Screen)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = AppUtils.getGreeting();
    final todayStr = AppUtils.formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: StreamBuilder<List<Prescription>>(
          stream: IsarService.instance.watchTodayPrescriptions(),
          builder: (context, snapshot) {
            final prescriptions = snapshot.data ?? [];
            final totalCount = prescriptions.length;
            final takenCount = prescriptions.where((p) => p.isTaken).length;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ─── Header & Lời chào kích thước lớn ─────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingXL,
                      AppSizes.paddingL,
                      AppSizes.paddingXL,
                      AppSizes.paddingM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Lời chào + Tiêu đề (full-width, không cạnh tranh không gian với chips) ──
                        Text(
                          greeting,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lịch uống thuốc',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                            color: AppColors.white,
                          ),
                        ),

                        const SizedBox(height: AppSizes.paddingM),

                        // ─── Action Chips – ngay dưới tiêu đề (Chống tràn màn hình nhỏ) ──
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Nút Báo cáo nhanh
                              InkWell(
                                onTap: () => Navigator.pushNamed(context, AppRoutes.report),
                                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.navyLight,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                                    border: Border.all(color: AppColors.navyMid),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.bar_chart_rounded, color: AppColors.accentGreen, size: 22),
                                      SizedBox(width: 4),
                                      Text(
                                        'Báo cáo',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Nút Cài đặt giờ ăn
                              InkWell(
                                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.navyLight,
                                    borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                                    border: Border.all(color: AppColors.navyMid),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.settings_rounded, color: AppColors.accentGreen, size: 22),
                                      SizedBox(width: 4),
                                      Text(
                                        'Cài đặt',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Chip ngày
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.navyLight,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                                  border: Border.all(color: AppColors.navyMid),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: AppColors.accentGreen, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      todayStr,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSizes.paddingL),

                        // ─── Thẻ tiến độ uống thuốc trong ngày ───────────────
                        _DailyProgressCard(
                          total: totalCount,
                          taken: takenCount,
                        ),

                        const SizedBox(height: AppSizes.paddingL),

                        // Tiêu đề danh sách thuốc
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Thuốc cần uống hôm nay',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (prescriptions.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '$takenCount/$totalCount đã uống',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentGreen,
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Danh sách các thẻ thuốc (Prescription Cards) ──────
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGreen,
                      ),
                    ),
                  )
                else if (prescriptions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPrescriptionsView(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingXL,
                      AppSizes.paddingS,
                      AppSizes.paddingXL,
                      120, // Khoảng trống tránh bị FAB che
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = prescriptions[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.paddingM,
                            ),
                            child: Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: AppSizes.paddingL),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                                    SizedBox(height: 4),
                                    Text(
                                      'Xóa',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await _confirmDelete(context, item.medicineName);
                              },
                              onDismissed: (_) => _handleDelete(context, item),
                              child: _PrescriptionCard(
                                prescription: item,
                                onToggle: () => _handleToggle(context, item),
                                onEdit: () => _handleEdit(context, item),
                              ),
                            ),
                          );
                        },
                        childCount: prescriptions.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),

      // ─── Floating Action Button (FAB) Lớn, Nổi bật ─────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXL),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.pushNamed(context, AppRoutes.scan);
          },
          icon: const Icon(
            Icons.camera_alt_rounded,
            size: 32,
            color: AppColors.white,
          ),
          label: const Text(
            'Quét đơn thuốc mới',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: AppColors.white,
            elevation: 8,
            shadowColor: AppColors.accentGreen.withValues(alpha: 0.5),
            minimumSize: const Size.fromHeight(68),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            ),
          ),
        ),
      ),
    );
  }

  /// Xử lý bấm đổi trạng thái đã uống thuốc
  Future<void> _handleToggle(
    BuildContext context,
    Prescription prescription,
  ) async {
    HapticFeedback.lightImpact();
    final newStatus =
        await IsarService.instance.toggleIntakeStatus(prescription.id);

    if (context.mounted) {
      final message = newStatus
          ? 'Đã xác nhận uống: ${prescription.medicineName}'
          : 'Đã hoàn tác: ${prescription.medicineName} (Chưa uống)';

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          backgroundColor:
              newStatus ? AppColors.accentGreenDark : AppColors.warningOrange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      );
    }
  }

  /// Mở Modal chỉnh sửa thông tin đơn thuốc
  Future<void> _handleEdit(
    BuildContext context,
    Prescription prescription,
  ) async {
    HapticFeedback.lightImpact();
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditPrescriptionDialog(prescription: prescription),
    );

    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật: ${prescription.medicineName}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          backgroundColor: AppColors.accentGreenDark,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      );
    }
  }

  /// Xác nhận trước khi xóa (hiển thị hộp thoại nhỏ)
  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
        title: const Text(
          'Xóa thuốc?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa "$name" khỏi danh sách?',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            child: const Text(
              'Xóa',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Xóa đơn thuốc và hiển thị SnackBar xác nhận
  Future<void> _handleDelete(BuildContext context, Prescription prescription) async {
    HapticFeedback.mediumImpact();
    await IsarService.instance.deletePrescription(prescription.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xóa: ${prescription.medicineName}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      );
    }
  }
}

// ─── Thẻ Tiến độ uống thuốc trong ngày (Daily Progress Card) ───────────────

class _DailyProgressCard extends StatelessWidget {
  final int total;
  final int taken;

  const _DailyProgressCard({
    required this.total,
    required this.taken,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (taken / total) : 0.0;
    final isCompleted = total > 0 && taken == total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      decoration: BoxDecoration(
        gradient: isCompleted
            ? AppColors.accentGradient
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
        border: Border.all(
          color: isCompleted
              ? AppColors.accentGreen
              : AppColors.navyMid,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.medication_rounded,
                        color: AppColors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isCompleted ? 'Hoàn thành tuyệt vời!' : 'Tiến độ hôm nay',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$taken/$total',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingL),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.black.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreenLight),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isCompleted
                ? 'Ông/Bà đã uống đủ tất cả các liều thuốc trong ngày!'
                : 'Chạm vào từng thẻ thuốc để đánh dấu khi đã uống xong.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Thẻ Đơn Thuốc Thân Thiện Người Cao Tuổi (Prescription Card) ────────────

class _PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _PrescriptionCard({
    required this.prescription,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isTaken = prescription.isTaken;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        splashColor: (isTaken ? AppColors.warningOrange : AppColors.accentGreen)
            .withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: isTaken
                ? const Color(0xFF0F2D35)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            border: Border.all(
              color: isTaken
                  ? AppColors.accentGreen
                  : AppColors.navyMid,
              width: isTaken ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Hàng tiêu đề: Icon + Tên thuốc + Nút Sửa + Status Badge ────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon thuốc hình tròn lớn
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isTaken
                          ? AppColors.accentGreen.withValues(alpha: 0.2)
                          : AppColors.warningOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTaken
                          ? Icons.check_circle_rounded
                          : Icons.access_time_filled_rounded,
                      color: isTaken
                          ? AppColors.accentGreen
                          : AppColors.warningOrange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Tên thuốc & Giờ uống (Không cắt ngắn chuỗi, hiển thị đầy đủ)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription.medicineName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: isTaken
                                ? AppColors.textSecondary
                                : AppColors.white,
                            decoration: isTaken
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          softWrap: true,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.alarm_rounded,
                              size: 18,
                              color: AppColors.accentGreenLight,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Giờ uống: ${prescription.scheduleTime}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accentGreenLight,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Cụm Nút Sửa & Trạng thái Badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatusBadge(isTaken: isTaken),
                      const SizedBox(height: 6),
                      // Nút Chỉnh sửa thông tin đơn thuốc
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navyLight,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                            border: Border.all(
                              color: AppColors.accentGreen.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.accentGreen,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Sửa',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  color: AppColors.navyMid,
                  height: 1,
                  thickness: 1,
                ),
              ),

              // ─── Thông tin chi tiết: Liều lượng & Hướng dẫn (Wrap để không bị cắt chữ) ───
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navyLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: AppColors.navyMid),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.medication_liquid_rounded,
                          color: AppColors.accentGreenLight,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Liều: ${prescription.dosage}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navyLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                      border: Border.all(color: AppColors.navyMid),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.repeat_rounded,
                          color: AppColors.midGrey,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          prescription.frequency,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Hướng dẫn nếu có (Hiển thị đầy đủ không cắt chữ)
              if (prescription.instructions != null &&
                  prescription.instructions!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.deepNavy.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        color: AppColors.warningOrangeLight,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          prescription.instructions!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // ─── Nút bấm tương tác chạm lớn ─────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isTaken
                      ? AppColors.navyLight
                      : AppColors.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: isTaken
                        ? AppColors.navyMid
                        : AppColors.accentGreen,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isTaken
                          ? Icons.undo_rounded
                          : Icons.check_circle_outline_rounded,
                      color: isTaken
                          ? AppColors.midGrey
                          : AppColors.accentGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isTaken ? 'Chạm để hoàn tác' : 'Chạm để đánh dấu ĐÃ UỐNG',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isTaken
                              ? AppColors.midGrey
                              : AppColors.accentGreenLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog Chỉnh Sửa Đơn Thuốc (Edit Prescription Dialog) ─────────────────

class _EditPrescriptionDialog extends StatefulWidget {
  final Prescription prescription;
  const _EditPrescriptionDialog({required this.prescription});

  @override
  State<_EditPrescriptionDialog> createState() => _EditPrescriptionDialogState();
}

class _EditPrescriptionDialogState extends State<_EditPrescriptionDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _dosageCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _frequencyCtrl;
  late final TextEditingController _instructionsCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.prescription.medicineName);
    _dosageCtrl = TextEditingController(text: widget.prescription.dosage);
    _timeCtrl = TextEditingController(text: widget.prescription.scheduleTime);
    _frequencyCtrl = TextEditingController(text: widget.prescription.frequency);
    _instructionsCtrl = TextEditingController(text: widget.prescription.instructions ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _timeCtrl.dispose();
    _frequencyCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final cur = _timeCtrl.text.trim();
    int h = 8, m = 0;
    final parts = cur.split(':');
    if (parts.length == 2) {
      h = int.tryParse(parts[0]) ?? 8;
      m = int.tryParse(parts[1]) ?? 0;
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: h, minute: m),
      helpText: 'Chọn giờ uống thuốc',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGreen,
              onPrimary: AppColors.white,
              surface: AppColors.navyLight,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _timeCtrl.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppUtils.showSnackBar(context, 'Vui lòng nhập tên thuốc.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final p = widget.prescription;
      p.medicineName = _nameCtrl.text.trim();
      p.dosage = _dosageCtrl.text.trim().isEmpty ? 'Theo chỉ dẫn' : _dosageCtrl.text.trim();
      p.scheduleTime = _timeCtrl.text.trim().isEmpty ? '08:00' : _timeCtrl.text.trim();
      p.frequency = _frequencyCtrl.text.trim().isEmpty ? 'Hằng ngày' : _frequencyCtrl.text.trim();
      p.instructions = _instructionsCtrl.text.trim().isEmpty ? null : _instructionsCtrl.text.trim();

      await IsarService.instance.savePrescription(p);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppUtils.showSnackBar(context, 'Lỗi cập nhật: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          maxHeight: availableHeight * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppColors.navyLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
          border: Border.all(color: AppColors.accentGreen, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGreen.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingXL,
                AppSizes.paddingL,
                AppSizes.paddingM,
                AppSizes.paddingS,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.accentGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  const Expanded(
                    child: Text(
                      'Chỉnh sửa đơn thuốc',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, color: AppColors.midGrey),
                    iconSize: 26,
                  ),
                ],
              ),
            ),

            // Form inputs with scrolling that respects keyboard
            Flexible(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingXL,
                  vertical: AppSizes.paddingS,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      label: 'Tên thuốc',
                      controller: _nameCtrl,
                      hint: 'Nhập tên thuốc',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    _buildField(
                      label: 'Liều dùng',
                      controller: _dosageCtrl,
                      hint: 'Ví dụ: 1 viên, 5ml',
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            label: 'Giờ uống',
                            controller: _timeCtrl,
                            hint: '08:00',
                            keyboardType: TextInputType.datetime,
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.access_time_rounded,
                                color: AppColors.accentGreen,
                                size: 20,
                              ),
                              onPressed: _pickTime,
                              tooltip: 'Chọn giờ',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.paddingM),
                        Expanded(
                          child: _buildField(
                            label: 'Tần suất',
                            controller: _frequencyCtrl,
                            hint: 'Hằng ngày',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    _buildField(
                      label: 'Lưu ý uống thuốc',
                      controller: _instructionsCtrl,
                      hint: 'Ví dụ: Uống sau khi ăn no',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingXL,
                AppSizes.paddingM,
                AppSizes.paddingXL,
                AppSizes.paddingL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              Icons.save_rounded,
                              size: 24,
                              color: AppColors.white,
                            ),
                      label: Text(
                        _isSaving ? 'Đang lưu...' : 'Lưu thay đổi',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.midGrey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: AppColors.midGrey,
            ),
            filled: true,
            fillColor: AppColors.deepNavy,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingL,
              vertical: AppSizes.paddingM,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              borderSide:
                  const BorderSide(color: AppColors.accentGreen, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Status Badge: Đã uống (Xanh) vs Chưa uống (Cam) ──────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isTaken;

  const _StatusBadge({required this.isTaken});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isTaken ? AppColors.accentGreen : AppColors.warningOrange,
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: (isTaken ? AppColors.accentGreen : AppColors.warningOrange)
                .withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTaken ? Icons.check_rounded : Icons.schedule_rounded,
            color: AppColors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isTaken ? 'Đã uống' : 'Chưa uống',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Giao diện khi chưa có đơn thuốc (Empty State) ─────────────────────────

class _EmptyPrescriptionsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navyMid, width: 2),
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                size: 54,
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),
            const Text(
              'Chưa có đơn thuốc nào',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingM),
            const Text(
              'Nhấn "Quét đơn thuốc mới" bên dưới để chụp đơn thuốc hoặc nạp lại danh sách mẫu.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingXL),
            OutlinedButton.icon(
              onPressed: () async {
                await IsarService.instance.seedSampleData();
              },
              icon: const Icon(Icons.refresh_rounded, size: 22),
              label: const Text(
                'Tải lại thuốc mẫu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
