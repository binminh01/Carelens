import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/prescription.dart';
import '../../../core/services/isar_service.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';

/// Màn hình Báo cáo & Xuất dữ liệu Sức khỏe Thân Thiện Người Cao Tuổi
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _filterIndex = 0; // 0 = Tất cả, 1 = Đã uống, 2 = Chưa uống
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayStr = AppUtils.formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Báo cáo sức khỏe',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_rounded,
              color: AppColors.accentGreen,
              size: 28,
            ),
            tooltip: 'Chia sẻ báo cáo',
            onPressed: () => _handleShareText(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Prescription>>(
          stream: IsarService.instance.watchTodayPrescriptions(),
          builder: (context, snapshot) {
            final allPrescriptions = snapshot.data ?? [];
            final total = allPrescriptions.length;
            final takenCount =
                allPrescriptions.where((p) => p.isTaken).length;
            final remainingCount = total - takenCount;
            final adherenceRate =
                total > 0 ? ((takenCount / total) * 100).toInt() : 0;

            // Lọc danh sách theo filter chip
            List<Prescription> filteredList;
            if (_filterIndex == 1) {
              filteredList =
                  allPrescriptions.where((p) => p.isTaken).toList();
            } else if (_filterIndex == 2) {
              filteredList =
                  allPrescriptions.where((p) => !p.isTaken).toList();
            } else {
              filteredList = allPrescriptions;
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingXL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Thẻ Tổng Quan Chỉ Số Tuân Thủ ─────────────
                        _ComplianceHeaderCard(
                          todayStr: todayStr,
                          total: total,
                          taken: takenCount,
                          remaining: remainingCount,
                          rate: adherenceRate,
                        ),

                        const SizedBox(height: AppSizes.paddingXL),

                        // ─── Các Nút Hành Động Nhanh (Xuất PDF & Chia sẻ) ─
                        _QuickActionButtons(
                          isGeneratingPdf: _isGeneratingPdf,
                          onExportPdf: () =>
                              _handleExportPdf(context, allPrescriptions),
                          onShare: () =>
                              _handleShareText(context, allPrescriptions),
                        ),

                        const SizedBox(height: AppSizes.paddingXL),

                        // ─── Bộ Lọc Danh Sách ────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lịch sử đơn thuốc',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              '${filteredList.length} thuốc',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSizes.paddingM),

                        // Filter Chips — horizontal scroll prevents overflow on small screens
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChipItem(
                                label: 'Tất cả ($total)',
                                isSelected: _filterIndex == 0,
                                onSelected: () =>
                                    setState(() => _filterIndex = 0),
                              ),
                              const SizedBox(width: 8),
                              _FilterChipItem(
                                label: 'Đã uống ($takenCount)',
                                isSelected: _filterIndex == 1,
                                selectedColor: AppColors.accentGreenDark,
                                onSelected: () =>
                                    setState(() => _filterIndex = 1),
                              ),
                              const SizedBox(width: 8),
                              _FilterChipItem(
                                label: 'Chưa uống ($remainingCount)',
                                isSelected: _filterIndex == 2,
                                selectedColor: AppColors.warningOrange,
                                onSelected: () =>
                                    setState(() => _filterIndex = 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Danh Sách Thuốc Chi Tiết ─────────────────────────
                if (filteredList.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyFilteredState(filterIndex: _filterIndex),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.paddingXL,
                      0,
                      AppSizes.paddingXL,
                      AppSizes.paddingXXL,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredList[index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.paddingM,
                            ),
                            child: _ReportPrescriptionTile(prescription: item),
                          );
                        },
                        childCount: filteredList.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Xử lý Xuất tệp PDF ────────────────────────────────────────────────

  Future<void> _handleExportPdf(
    BuildContext context,
    List<Prescription> prescriptions,
  ) async {
    if (prescriptions.isEmpty) {
      AppUtils.showSnackBar(
        context,
        'Chưa có đơn thuốc nào để xuất báo cáo.',
        isError: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isGeneratingPdf = true);

    try {
      await PdfExportService.instance.sharePdfReport(
        context: context,
        prescriptions: prescriptions,
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  // ─── Xử lý Chia sẻ Văn Bản / File ────────────────────────────────────

  Future<void> _handleShareText(
    BuildContext context, [
    List<Prescription>? prescriptions,
  ]) async {
    final list =
        prescriptions ?? await IsarService.instance.getAllPrescriptions();

    if (list.isEmpty) {
      if (context.mounted) {
        AppUtils.showSnackBar(
          context,
          'Chưa có đơn thuốc nào để chia sẻ.',
          isError: true,
        );
      }
      return;
    }

    HapticFeedback.lightImpact();
    if (context.mounted) {
      await PdfExportService.instance.shareTextMessage(
        context: context,
        prescriptions: list,
      );
    }
  }
}

// ─── Thẻ Tổng Quan Chỉ Số Tuân Thủ (Compliance Header Card) ───────────────

class _ComplianceHeaderCard extends StatelessWidget {
  final String todayStr;
  final int total;
  final int taken;
  final int remaining;
  final int rate;

  const _ComplianceHeaderCard({
    required this.todayStr,
    required this.total,
    required this.taken,
    required this.remaining,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.paddingXL),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXXL),
        border: Border.all(color: AppColors.navyMid, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.2),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusLarge),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: AppColors.accentGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tổng quan hôm nay',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            todayStr,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rate == 100
                      ? AppColors.accentGreen
                      : (rate >= 50
                          ? AppColors.warningOrange
                          : AppColors.navyMid),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                ),
                child: Text(
                  '$rate% Đạt',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.paddingXL),

          // 3 Cột thống kê số liệu lớn
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                label: 'Tổng số thuốc',
                value: '$total',
                color: AppColors.white,
                icon: Icons.medication_rounded,
              ),
              Container(width: 1, height: 50, color: AppColors.navyMid),
              _StatColumn(
                label: 'Đã uống',
                value: '$taken',
                color: AppColors.accentGreen,
                icon: Icons.check_circle_rounded,
              ),
              Container(width: 1, height: 50, color: AppColors.navyMid),
              _StatColumn(
                label: 'Còn lại',
                value: '$remaining',
                color: remaining > 0
                    ? AppColors.warningOrange
                    : AppColors.midGrey,
                icon: Icons.access_time_filled_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Các Nút Hành Động Nhanh (Xuất PDF & Chia Sẻ) ─────────────────────────

class _QuickActionButtons extends StatelessWidget {
  final bool isGeneratingPdf;
  final VoidCallback onExportPdf;
  final VoidCallback onShare;

  const _QuickActionButtons({
    required this.isGeneratingPdf,
    required this.onExportPdf,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Nút chính: Xuất Báo Cáo PDF (Cao 64px, chữ lớn)
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton.icon(
            onPressed: isGeneratingPdf ? null : onExportPdf,
            icon: isGeneratingPdf
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 28,
                    color: AppColors.white,
                  ),
            label: Text(
              isGeneratingPdf ? 'Đang tạo PDF...' : 'Xuất báo cáo PDF',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSizes.paddingM),

        // Nút phụ: Chia sẻ nhanh qua Zalo, Email, Drive
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onShare,
            icon: const Icon(
              Icons.share_rounded,
              size: 24,
              color: AppColors.accentGreen,
            ),
            label: const Text(
              'Chia sẻ qua Zalo / Tin nhắn',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accentGreen,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: AppColors.accentGreen,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Filter Chip Item ─────────────────────────────────────────────────────

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? selectedColor;
  final VoidCallback onSelected;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    this.selectedColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (selectedColor ?? AppColors.accentGreen)
              : AppColors.navyLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
          border: Border.all(
            color: isSelected
                ? (selectedColor ?? AppColors.accentGreen)
                : AppColors.navyMid,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Thẻ Chi Tiết Thuốc Trong Báo Cáo ────────────────────────────────────

class _ReportPrescriptionTile extends StatelessWidget {
  final Prescription prescription;

  const _ReportPrescriptionTile({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final isTaken = prescription.isTaken;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(
          color: isTaken
              ? AppColors.accentGreen.withValues(alpha: 0.5)
              : AppColors.navyMid,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  prescription.medicineName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isTaken
                      ? AppColors.accentGreen
                      : AppColors.warningOrange,
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusLarge),
                ),
                child: Text(
                  isTaken ? 'ĐÃ UỐNG' : 'CHƯA UỐNG',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              const Icon(
                Icons.alarm_rounded,
                size: 18,
                color: AppColors.accentGreenLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Giờ uống: ${prescription.scheduleTime}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGreenLight,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.medication_liquid_rounded,
                size: 18,
                color: AppColors.midGrey,
              ),
              const SizedBox(width: 6),
              Text(
                prescription.dosage,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          if (prescription.instructions != null &&
              prescription.instructions!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Lưu ý: ${prescription.instructions}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty Filtered State ─────────────────────────────────────────────────

class _EmptyFilteredState extends StatelessWidget {
  final int filterIndex;

  const _EmptyFilteredState({required this.filterIndex});

  @override
  Widget build(BuildContext context) {
    String message = 'Không có đơn thuốc nào';
    if (filterIndex == 1) {
      message = 'Chưa có liều thuốc nào được đánh dấu đã uống.';
    } else if (filterIndex == 2) {
      message = 'Tuyệt vời! Tất cả các liều thuốc hôm nay đã được uống xong.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_turned_in_rounded,
              size: 64,
              color: AppColors.midGrey,
            ),
            const SizedBox(height: AppSizes.paddingL),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
