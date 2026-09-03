import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';
import '../models/prescription.dart';
import 'isar_service.dart';

/// Extension to provide .id alias for TimezoneInfo.identifier (flutter_timezone v5+)
extension TimezoneInfoIdExtension on TimezoneInfo {
  String get id => identifier;
}

/// Dịch vụ thông báo và báo thức nhắc nhở uống thuốc cục bộ (Hoạt động hoàn toàn Offline)
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  /// GlobalKey điều hướng toàn cục khi người dùng nhấn vào thông báo
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Khởi tạo NotificationService ──────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 1. Khởi tạo cơ sở dữ liệu múi giờ Timezone từ thiết bị thực tế
      tz.initializeTimeZones();
      try {
        final String currentTimeZone =
            (await FlutterTimezone.getLocalTimezone()).id;
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
        developer.log(
          'Đã thiết lập múi giờ thành công: $currentTimeZone',
          name: 'NotificationService',
        );
      } catch (e) {
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
          developer.log(
            'Không lấy được timezone thiết bị, fallback sang Asia/Ho_Chi_Minh: $e',
            name: 'NotificationService',
          );
        } catch (e2) {
          developer.log(
            'Lỗi thiết lập timezone: $e2',
            name: 'NotificationService',
          );
        }
      }

      // 2. Cấu hình icon thông báo Android và iOS
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // 3. Tạo kênh thông báo ưu tiên cao trên Android (High Importance Alarm Channel)
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Xin quyền gửi thông báo trên Android 13+ (POST_NOTIFICATIONS)
        await androidPlugin.requestNotificationsPermission();
        // Xin quyền báo thức chính xác trên Android 12+ (SCHEDULE_EXACT_ALARM)
        await androidPlugin.requestExactAlarmsPermission();

        // Kênh thông báo chuẩn Báo Thức (Alarm) - Âm lượng lớn, rung mạnh, vượt chế độ im lặng
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            AppConstants.notifChannelId,
            AppConstants.notifChannelName,
            description: AppConstants.notifChannelDesc,
            importance: Importance.max,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
            playSound: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            enableLights: true,
            showBadge: true,
          ),
        );
      }

      _initialized = true;
      developer.log(
        'NotificationService đã khởi tạo thành công với Timezone và Kênh Báo Thức.',
        name: 'NotificationService',
      );
    } catch (e, stack) {
      developer.log(
        'Lỗi khi khởi tạo NotificationService: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // ─── Kiểm tra & Yêu cầu Quyền hạn ────────────────────────────────────

  /// Yêu cầu cấp quyền gửi thông báo & báo thức chính xác
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final notifGranted = await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
      return notifGranted ?? true;
    }
    return true;
  }

  /// Kiểm tra thiết bị có cho phép báo thức chính xác không
  Future<bool> isExactAlarmAllowed() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      return await androidPlugin.canScheduleExactNotifications() ?? false;
    }
    return true;
  }

  // ─── Xử lý khi người dùng chạm vào thông báo hoặc nút hành động ─────────

  Future<void> _onNotificationTap(NotificationResponse response) async {
    developer.log(
      'Người dùng đã tương tác với thông báo: actionId = ${response.actionId}, payload = ${response.payload}',
      name: 'NotificationService._onNotificationTap',
    );

    final payload = response.payload ?? '';

    // Nếu người dùng nhấn nút hành động "Đã uống xong" hoặc chạm vào thông báo nhắc thuốc
    if (response.actionId == 'action_taken' || payload.startsWith('prescription_')) {
      final idStr = payload.replaceFirst('prescription_', '');
      final id = int.tryParse(idStr);
      if (id != null) {
        try {
          // Đánh dấu đã uống thuốc trong Isar DB
          await IsarService.instance.setIntakeStatus(id, true);
        } catch (e) {
          developer.log('Lỗi cập nhật trạng thái đã uống từ thông báo: $e');
        }
      }
    }

    // Mở hoặc đưa màn hình chính (HomeScreen) về tiêu điểm
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  // ─── Lên lịch thông báo lặp lại hằng ngày theo đơn thuốc ──────────────

  /// Lên lịch thông báo lặp lại mỗi ngày cho một đơn thuốc (`Prescription`)
  Future<void> schedulePrescriptionReminder(Prescription prescription) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // 1. Phân tích giờ uống từ scheduleTime (ví dụ: "08:00", "20:30")
      final (hour, minute) = _parseScheduleTime(prescription.scheduleTime);

      // 2. Tính toán mốc thời gian tiếp theo theo múi giờ địa phương
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Nếu giờ đã qua trong ngày hôm nay, lên lịch bắt đầu từ ngày mai
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // 3. Cấu hình chi tiết thông báo Android (Chuẩn Alarm, âm lượng lớn, nút dừng)
      final androidDetails = AndroidNotificationDetails(
        AppConstants.notifChannelId,
        AppConstants.notifChannelName,
        channelDescription: AppConstants.notifChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        ticker: '⏰ Đã đến giờ uống thuốc!',
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        fullScreenIntent: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: const <AndroidNotificationAction>[
          AndroidNotificationAction(
            'action_taken',
            'Đã uống xong',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
        styleInformation: BigTextStyleInformation(
          'Đã đến giờ uống: ${prescription.medicineName}\n'
          'Liều lượng: ${prescription.dosage}\n'
          'Giờ uống: ${prescription.scheduleTime}'
          '${prescription.instructions != null && prescription.instructions!.isNotEmpty ? "\nLưu ý: ${prescription.instructions}" : ""}',
          contentTitle: '⏰ Đã đến giờ uống thuốc!',
          summaryText: 'CareLens Nhắc thuốc',
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // 4. Kiểm tra chế độ báo thức (Exact Alarm Mode)
      AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canExact = await androidPlugin.canScheduleExactNotifications();
        if (canExact == false) {
          developer.log(
            'Thiết bị chưa cấp quyền Exact Alarm, fallback sang inexactAllowWhileIdle',
            name: 'NotificationService',
          );
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }

      // 5. Lên lịch thông báo lặp lại hàng ngày (kèm cơ chế tự động fallback)
      try {
        await _plugin.zonedSchedule(
          id: prescription.id,
          title: '⏰ Đã đến giờ uống thuốc!',
          body:
              'Vui lòng uống ${prescription.medicineName} - Liều lượng: ${prescription.dosage}',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'prescription_${prescription.id}',
        );
      } catch (scheduleError) {
        developer.log(
          'Lỗi khi lên lịch exact alarm, fallback sang inexact: $scheduleError',
          name: 'NotificationService',
        );
        await _plugin.zonedSchedule(
          id: prescription.id,
          title: '⏰ Đã đến giờ uống thuốc!',
          body:
              'Vui lòng uống ${prescription.medicineName} - Liều lượng: ${prescription.dosage}',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'prescription_${prescription.id}',
        );
      }

      developer.log(
        'Đã lên lịch nhắc thuốc "${prescription.medicineName}" (ID: ${prescription.id}) vào lúc ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} hằng ngày.',
        name: 'NotificationService.schedulePrescriptionReminder',
      );
    } catch (e, stack) {
      developer.log(
        'Lỗi khi lên lịch thông báo đơn thuốc: $e',
        name: 'NotificationService.schedulePrescriptionReminder',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // ─── Hủy báo thức nhắc thuốc ──────────────────────────────────────────

  /// Hủy thông báo theo ID đơn thuốc
  Future<void> cancelReminder(int prescriptionId) async {
    try {
      await _plugin.cancel(id: prescriptionId);
      developer.log(
        'Đã hủy thông báo nhắc thuốc ID: $prescriptionId',
        name: 'NotificationService.cancelReminder',
      );
    } catch (e) {
      developer.log('Lỗi khi hủy thông báo ID $prescriptionId: $e');
    }
  }

  /// Hủy tất cả thông báo
  Future<void> cancelAllReminders() async {
    try {
      await _plugin.cancelAll();
      developer.log('Đã hủy tất cả thông báo.');
    } catch (e) {
      developer.log('Lỗi khi hủy toàn bộ thông báo: $e');
    }
  }

  // ─── Gửi thông báo kiểm tra (Test Notification) ───────────────────────

  /// Gửi thông báo kiểm tra sau một khoảng trễ (mặc định 3 giây) để kiểm tra chuông / rung
  Future<void> sendTestNotification({int delaySeconds = 3}) async {
    if (!_initialized) {
      await initialize();
    }

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notifChannelId,
      AppConstants.notifChannelName,
      channelDescription: AppConstants.notifChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ticker: '🔔 Kiểm tra thông báo CareLens',
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_test_dismiss',
          'Đã nhận thông báo',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
      styleInformation: const BigTextStyleInformation(
        'Chuông thông báo và báo thức của CareLens đang hoạt động tốt!\n\nNếu bạn nhìn thấy và nghe chuông thông báo này, các lịch uống thuốc hàng ngày sẽ được nhắc nhở chính xác.',
        contentTitle: '🔔 Kiểm tra thông báo CareLens',
        summaryText: 'Thử nghiệm hệ thống',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (delaySeconds <= 0) {
      await _plugin.show(
        id: 999999,
        title: '🔔 Kiểm tra thông báo CareLens',
        body: 'Hệ thống thông báo CareLens đang hoạt động tốt!',
        notificationDetails: details,
        payload: 'test_notification',
      );
    } else {
      final scheduledDate =
          tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));

      AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final canExact = await androidPlugin.canScheduleExactNotifications();
        if (canExact == false) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }

      try {
        await _plugin.zonedSchedule(
          id: 999999,
          title: '🔔 Kiểm tra thông báo CareLens',
          body: 'Hệ thống thông báo CareLens đang hoạt động tốt!',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: scheduleMode,
          payload: 'test_notification',
        );
      } catch (_) {
        // Fallback gửi thông báo trực tiếp sau delay
        await Future.delayed(Duration(seconds: delaySeconds));
        await _plugin.show(
          id: 999999,
          title: '🔔 Kiểm tra thông báo CareLens',
          body: 'Hệ thống thông báo CareLens đang hoạt động tốt!',
          notificationDetails: details,
          payload: 'test_notification',
        );
      }
    }
  }

  // ─── Gửi thông báo tức thì (Dùng cho kiểm tra & thông báo khẩn) ─────────

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.notifChannelId,
      AppConstants.notifChannelName,
      channelDescription: AppConstants.notifChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      ticker: title,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_taken',
          'Đã uống xong',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  // ─── Trợ giúp phân tích giờ uống (Schedule Time Parser) ────────────────

  /// Trích xuất giờ và phút từ chuỗi giờ (ví dụ: "08:00", "20:30", "8h00", "8:00")
  (int, int) _parseScheduleTime(String timeStr) {
    try {
      final clean = timeStr.trim();
      final colonMatch = RegExp(r'(\d{1,2})[:hH](\d{2})').firstMatch(clean);
      if (colonMatch != null) {
        final hour = int.parse(colonMatch.group(1)!);
        final minute = int.parse(colonMatch.group(2)!);
        return (hour.clamp(0, 23), minute.clamp(0, 59));
      }

      final singleHourMatch = RegExp(r'(\d{1,2})').firstMatch(clean);
      if (singleHourMatch != null) {
        final hour = int.parse(singleHourMatch.group(1)!);
        return (hour.clamp(0, 23), 0);
      }
    } catch (_) {}

    return (8, 0);
  }
}
