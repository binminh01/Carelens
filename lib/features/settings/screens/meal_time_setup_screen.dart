import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// Màn hình thiết lập giờ ăn bắt buộc khi mở lần đầu.
/// Không có nút "Bỏ qua" — người dùng PHẢI xác nhận trước khi vào ứng dụng.
class MealTimeSetupScreen extends StatefulWidget {
  /// Khi [isFirstLaunch] = true, màn hình sẽ thay thế toàn bộ navigation stack.
  /// Khi false (vào từ Cài đặt), nó chỉ pop về màn hình trước.
  final bool isFirstLaunch;

  const MealTimeSetupScreen({super.key, this.isFirstLaunch = true});

  @override
  State<MealTimeSetupScreen> createState() => _MealTimeSetupScreenState();
}

class _MealTimeSetupScreenState extends State<MealTimeSetupScreen>
    with SingleTickerProviderStateMixin {
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 11, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 18, minute: 0);

  bool _isSaving = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadExistingTimes();
  }

  Future<void> _loadExistingTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getString(AppKeys.breakfastTime);
    final l = prefs.getString(AppKeys.lunchTime);
    final d = prefs.getString(AppKeys.dinnerTime);
    if (b != null) _breakfastTime = _parseTime(b);
    if (l != null) _lunchTime = _parseTime(l);
    if (d != null) _dinnerTime = _parseTime(d);
    if (mounted) setState(() {});
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? 7;
      final m = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: h, minute: m);
    }
    return const TimeOfDay(hour: 7, minute: 0);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(
    String label,
    TimeOfDay current,
    ValueChanged<TimeOfDay> onPicked,
  ) async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: 'Chọn $label',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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
    if (picked != null && mounted) {
      setState(() => onPicked(picked));
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppKeys.breakfastTime, _formatTime(_breakfastTime));
    await prefs.setString(AppKeys.lunchTime, _formatTime(_lunchTime));
    await prefs.setString(AppKeys.dinnerTime, _formatTime(_dinnerTime));
    await prefs.setBool(AppKeys.mealTimesSet, true);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (widget.isFirstLaunch) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (_) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isFirstLaunch,
      child: Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.paddingXL,
                AppSizes.paddingXXL,
                AppSizes.paddingXL,
                AppSizes.paddingXXL,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                      border: Border.all(
                        color: AppColors.accentGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.accentGreen,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingL),
                  const Text(
                    'Thiết lập giờ ăn',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'CareLens sẽ dùng giờ ăn của Ông/Bà để tính chính xác thời điểm uống thuốc (trước/sau bữa ăn).',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (widget.isFirstLaunch) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningOrange.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMedium),
                        border: Border.all(
                          color: AppColors.warningOrange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.warningOrangeLight, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bước bắt buộc — vui lòng thiết lập trước khi sử dụng ứng dụng.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                color: AppColors.warningOrangeLight,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.paddingXXL),
                  _MealTimeTile(
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    meal: 'Bữa sáng',
                    time: _formatTime(_breakfastTime),
                    onTap: () => _pickTime(
                      'giờ ăn sáng',
                      _breakfastTime,
                      (t) => _breakfastTime = t,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  _MealTimeTile(
                    icon: Icons.wb_cloudy_rounded,
                    iconColor: const Color(0xFF60A5FA),
                    meal: 'Bữa trưa',
                    time: _formatTime(_lunchTime),
                    onTap: () => _pickTime(
                      'giờ ăn trưa',
                      _lunchTime,
                      (t) => _lunchTime = t,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingM),
                  _MealTimeTile(
                    icon: Icons.nights_stay_rounded,
                    iconColor: const Color(0xFFA78BFA),
                    meal: 'Bữa tối',
                    time: _formatTime(_dinnerTime),
                    onTap: () => _pickTime(
                      'giờ ăn tối',
                      _dinnerTime,
                      (t) => _dinnerTime = t,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingXXL),
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeightLarge,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_rounded,
                              size: 28,
                              color: AppColors.white,
                            ),
                      label: Text(
                        _isSaving
                            ? 'Đang lưu...'
                            : (widget.isFirstLaunch
                                ? 'Xác nhận & Vào ứng dụng'
                                : 'Lưu thay đổi'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen,
                        elevation: 6,
                        shadowColor: AppColors.accentGreen.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                        ),
                      ),
                    ),
                  ),
                  if (!widget.isFirstLaunch) ...[
                    const SizedBox(height: AppSizes.paddingM),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 17,
                            color: AppColors.midGrey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MealTimeTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String meal;
  final String time;
  final VoidCallback onTap;

  const _MealTimeTile({
    required this.icon,
    required this.iconColor,
    required this.meal,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          decoration: BoxDecoration(
            color: AppColors.navyLight,
            borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            border: Border.all(color: AppColors.navyMid, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: AppSizes.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.4),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded,
                        color: AppColors.accentGreen, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Chỉnh',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentGreen,
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
