import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import 'meal_time_setup_screen.dart';

/// Màn hình Cài đặt của CareLens
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _breakfastTime = '07:00';
  String _lunchTime = '11:30';
  String _dinnerTime = '18:00';

  @override
  void initState() {
    super.initState();
    _loadTimes();
  }

  Future<void> _loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _breakfastTime = prefs.getString(AppKeys.breakfastTime) ?? '07:00';
        _lunchTime = prefs.getString(AppKeys.lunchTime) ?? '11:30';
        _dinnerTime = prefs.getString(AppKeys.dinnerTime) ?? '18:00';
      });
    }
  }

  Future<void> _openMealSetup() async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MealTimeSetupScreen(isFirstLaunch: false),
      ),
    );
    await _loadTimes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.paddingXL),
          children: [
            // ─── Cấu hình giờ ăn section ────────────────────────────────
            const _SectionHeader(
              title: 'Cấu hình giờ ăn',
              icon: Icons.restaurant_rounded,
            ),
            const SizedBox(height: AppSizes.paddingM),

            Container(
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border: Border.all(color: AppColors.navyMid, width: 1.5),
              ),
              child: Column(
                children: [
                  _MealTimeRow(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    label: 'Bữa sáng',
                    time: _breakfastTime,
                  ),
                  const Divider(
                    color: AppColors.navyMid,
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    endIndent: 20,
                  ),
                  _MealTimeRow(
                    icon: Icons.wb_cloudy_rounded,
                    iconColor: const Color(0xFF60A5FA),
                    label: 'Bữa trưa',
                    time: _lunchTime,
                  ),
                  const Divider(
                    color: AppColors.navyMid,
                    height: 1,
                    thickness: 1,
                    indent: 72,
                    endIndent: 20,
                  ),
                  _MealTimeRow(
                    icon: Icons.nights_stay_rounded,
                    iconColor: const Color(0xFFA78BFA),
                    label: 'Bữa tối',
                    time: _dinnerTime,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingM),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openMealSetup,
                icon: const Icon(Icons.edit_rounded,
                    color: AppColors.accentGreen, size: 22),
                label: const Text(
                  'Chỉnh sửa giờ ăn',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentGreen,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentGreen, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingXXL),

            // ─── Thông báo & Báo thức nhắc thuốc ─────────────────────────
            const _SectionHeader(
              title: 'Thông báo & Báo thức nhắc thuốc',
              icon: Icons.notifications_active_rounded,
            ),
            const SizedBox(height: AppSizes.paddingM),

            Container(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border: Border.all(color: AppColors.navyMid, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kiểm tra tính năng nhắc thuốc',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Nhấn nút bên dưới, sau 3 giây hệ thống sẽ gửi 1 thông báo thử nghiệm kèm chuông và rung.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingL),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleTestNotification,
                      icon: const Icon(
                        Icons.alarm_on_rounded,
                        color: AppColors.white,
                        size: 24,
                      ),
                      label: const Text(
                        'Kiểm tra chuông thông báo ngay',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusLarge),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingM),

            // ─── Card Hướng dẫn máy HONOR / MagicOS / Xiaomi / Huawei ────
            _HonorSetupGuideCard(),

            const SizedBox(height: AppSizes.paddingXXL),

            // ─── Thông tin ứng dụng ─────────────────────────────────────
            const _SectionHeader(
              title: 'Thông tin ứng dụng',
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: AppSizes.paddingM),
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border: Border.all(color: AppColors.navyMid, width: 1.5),
              ),
              child: const Column(
                children: [
                  _InfoRow(label: 'Ứng dụng', value: AppConstants.appName),
                  SizedBox(height: 12),
                  _InfoRow(label: 'Phiên bản', value: AppConstants.appVersion),
                  SizedBox(height: 12),
                  _InfoRow(label: 'Slogan', value: AppConstants.appTagline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTestNotification() async {
    HapticFeedback.mediumImpact();
    await NotificationService.instance.sendTestNotification(delaySeconds: 3);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đã phát lệnh! Thông báo thử nghiệm sẽ xuất hiện sau 3 giây.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accentGreenDark,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
        ),
      );
    }
  }
}

class _HonorSetupGuideCard extends StatefulWidget {
  @override
  State<_HonorSetupGuideCard> createState() => _HonorSetupGuideCardState();
}

class _HonorSetupGuideCardState extends State<_HonorSetupGuideCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.smartphone_rounded,
                      color: AppColors.accentGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hướng dẫn máy HONOR / MagicOS',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bật quyền chạy ngầm để không bỏ lỡ giờ thuốc',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.accentGreenLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(color: AppColors.navyMid, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Để đảm bảo chuông báo thức reo đúng giờ khi tắt màn hình trên máy HONOR (MagicOS) hoặc Huawei / Xiaomi:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12),
                  _GuideStep(
                    step: '1',
                    title: 'Khởi chạy ứng dụng (App launch)',
                    desc:
                        'Vào Cài đặt máy > Ứng dụng > Khởi chạy ứng dụng > Tìm CareLens > Chọn "Quản lý thủ công" (Bật cả 3: Tự khởi chạy, Khởi chạy phụ, Chạy ngầm).',
                  ),
                  SizedBox(height: 10),
                  _GuideStep(
                    step: '2',
                    title: 'Tối ưu hóa Pin',
                    desc:
                        'Vào Cài đặt > Pin > Tối ưu hóa pin > Tìm CareLens > Chọn "Không cho phép / Không tối ưu hóa".',
                  ),
                  SizedBox(height: 10),
                  _GuideStep(
                    step: '3',
                    title: 'Bật Biểu ngữ & Màn hình khóa',
                    desc:
                        'Vào Cài đặt > Thông báo > CareLens > Bật mục "Biểu ngữ" và "Màn hình khóa", Bật Âm thanh & Rung.',
                  ),
                  SizedBox(height: 10),
                  _GuideStep(
                    step: '4',
                    title: 'Quyền Báo thức & Lời nhắc',
                    desc:
                        'Vào Cài đặt > Ứng dụng > Quyền đặc biệt > "Báo thức & lời nhắc" > Cho phép CareLens.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String step;
  final String title;
  final String desc;

  const _GuideStep({
    required this.step,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.accentGreen,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.deepNavy,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentGreen, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MealTimeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String time;

  const _MealTimeRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingL, vertical: AppSizes.paddingM),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSizes.paddingM),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.accentGreenLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
