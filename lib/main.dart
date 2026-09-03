import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'core/services/gemini_service.dart';
import 'core/services/isar_service.dart';
import 'core/services/notification_service.dart';

/// Điểm khởi đầu của ứng dụng CareLens
Future<void> main() async {
  // Đảm bảo Flutter binding đã được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình giao diện hệ thống – thanh trạng thái trong suốt
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A192F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Chỉ cho phép xoay dọc (tối ưu hóa cho người cao tuổi)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 1. Khởi tạo dịch vụ thông báo cục bộ với Timezone
  await NotificationService.instance.initialize();

  // 2. Khởi tạo cơ sở dữ liệu Isar Offline và nạp dữ liệu mẫu
  await IsarService.instance.initialize();

  // 3. Nạp biến môi trường (.env) — phải trước khi dùng geminiApiKeys
  await dotenv.load(fileName: '.env');

  // 4. Khởi tạo Gemini AI Service (đọc key từ .env)
  GeminiService.instance.initialize();

  // Khởi động ứng dụng trực tiếp
  runApp(
    const CareLensApp(),
  );
}