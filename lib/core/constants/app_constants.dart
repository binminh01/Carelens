/// Hằng số toàn ứng dụng CareLens
class AppConstants {
  AppConstants._();

  static const String appName = 'CareLens';
  static const String appTagline = 'Chăm sóc sức khỏe thông minh';
  static const String appVersion = '1.0.0';
  static const String dbName = 'carelens_db';

  static const String notifChannelId = 'carelens_health_channel';
  static const String notifChannelName = 'Nhắc nhở sức khỏe';
  static const String notifChannelDesc = 'Thông báo nhắc nhở uống thuốc và kiểm tra sức khỏe';

  // Gemini model
  static const String geminiModel = 'gemini-3.6-flash';

  /// Danh sách các API Key dự phòng từ Google AI Studio (Phải bắt đầu bằng AIzaSy...)
  static List<String> get geminiApiKeys => [
    dotenv.env['GEMINI_KEY_1'] ?? '',
    dotenv.env['GEMINI_KEY_2'] ?? '',
    dotenv.env['GEMINI_KEY_3'] ?? '',
    dotenv.env['GEMINI_KEY_4'] ?? '',
    dotenv.env['GEMINI_KEY_5'] ?? '',
  ].where((key) => key.isNotEmpty).toList();

  static const int imageQuality = 85;
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  static const int pageSize = 20;

  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);

  static const double bpSystolicHigh = 140.0;
  static const double bpSystolicLow = 90.0;
  static const double bpDiastolicHigh = 90.0;
  static const double bpDiastolicLow = 60.0;
  static const double heartRateHigh = 100.0;
  static const double heartRateLow = 50.0;
  static const double bloodSugarHigh = 7.8;
  static const double bloodSugarLow = 3.9;
  static const double oxygenLow = 95.0;
  static const double tempHigh = 37.5;
  static const double tempLow = 36.0;
}

class AppKeys {
  AppKeys._();
  static const String themeMode = 'theme_mode';
  static const String onboardingDone = 'onboarding_done';
  static const String userProfile = 'user_profile';
  static const String geminiApiKey = 'gemini_api_key';
  static const String notifEnabled = 'notif_enabled';
  static const String language = 'language';

  /// Giờ ăn – lưu dưới dạng chuỗi "HH:mm"
  static const String breakfastTime = 'breakfast_time';
  static const String lunchTime     = 'lunch_time';
  static const String dinnerTime    = 'dinner_time';

  /// Flag cho biết người dùng đã thiết lập giờ ăn lần đầu hay chưa
  static const String mealTimesSet = 'meal_times_set';
}

class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String scanResult = '/scan/result';
  static const String report = '/report';
  static const String reportDetail = '/report/detail';
  static const String settings = '/settings';
  static const String profile = '/profile';
}