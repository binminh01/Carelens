import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

// --- Data model for a parsed prescription from Gemini --------------------

class ParsedPrescription {
  final String medicineName;
  final String dosage;
  final String scheduleTime;
  final String frequency;
  final String instructions;

  const ParsedPrescription({
    required this.medicineName,
    required this.dosage,
    required this.scheduleTime,
    required this.frequency,
    required this.instructions,
  });

  factory ParsedPrescription.fromJson(Map<String, dynamic> json) {
    return ParsedPrescription(
      medicineName: (json['medicineName'] as String? ?? '').trim(),
      dosage: (json['dosage'] as String? ?? '').trim(),
      scheduleTime: (json['scheduleTime'] as String? ?? '').trim(),
      frequency: (json['frequency'] as String? ?? '').trim(),
      instructions: (json['instructions'] as String? ?? '').trim(),
    );
  }

  factory ParsedPrescription.empty() {
    return const ParsedPrescription(
      medicineName: '',
      dosage: '',
      scheduleTime: '',
      frequency: '',
      instructions: '',
    );
  }

  bool get isEmpty =>
      medicineName.isEmpty &&
      dosage.isEmpty &&
      scheduleTime.isEmpty &&
      frequency.isEmpty;

  Map<String, dynamic> toJson() => {
        'medicineName': medicineName,
        'dosage': dosage,
        'scheduleTime': scheduleTime,
        'frequency': frequency,
        'instructions': instructions,
      };

  ParsedPrescription copyWith({
    String? medicineName,
    String? dosage,
    String? scheduleTime,
    String? frequency,
    String? instructions,
  }) {
    return ParsedPrescription(
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      frequency: frequency ?? this.frequency,
      instructions: instructions ?? this.instructions,
    );
  }
}

// --- GeminiService -------------------------------------------------------

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  GenerativeModel? _model;
  int _currentKeyIndex = 0;

  bool get isInitialized => _model != null;

  void initialize([String? customApiKey]) {
    if (AppConstants.geminiApiKeys.isEmpty) {
      developer.log('Danh sách geminiApiKeys trống!', name: 'GeminiService');
      return;
    }
    final apiKey = customApiKey ?? AppConstants.geminiApiKeys[_currentKeyIndex];
    _initModelWithKey(apiKey);
  }

  void _initModelWithKey(String apiKey) {
    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        topK: 32,
        topP: 0.95,
        maxOutputTokens: 4096,
        responseMimeType: 'application/json',
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
  }

  bool _switchToNextKey() {
    final keys = AppConstants.geminiApiKeys;
    if (keys.isEmpty || keys.length <= 1) return false;
    _currentKeyIndex = (_currentKeyIndex + 1) % keys.length;
    final nextKey = keys[_currentKeyIndex];
    developer.log(
      'Đã tự động xoay sang API Key vị trí [${_currentKeyIndex + 1}/${keys.length}]',
      name: 'GeminiService',
    );
    _initModelWithKey(nextKey);
    return true;
  }

  Future<T> _executeWithRetry<T>(Future<T> Function() apiCall) async {
    // Lazy init: if not yet initialized (e.g., called before main() finishes),
    // attempt to initialize now so the user never sees NotInitializedError.
    if (_model == null) {
      developer.log(
        'GeminiService: lazy initialize() triggered inside _executeWithRetry.',
        name: 'GeminiService',
      );
      initialize();
    }
    _assertInitialized();

    int attempts = 0;
    final maxAttempts =
        AppConstants.geminiApiKeys.isEmpty ? 1 : AppConstants.geminiApiKeys.length;

    while (attempts < maxAttempts) {
      try {
        return await apiCall();
      } catch (e) {
        attempts++;
        final errorStr = e.toString().toLowerCase();
        developer.log(
          'Lỗi gọi Gemini API (Lần thứ $attempts/$maxAttempts): $e',
          name: 'GeminiService',
        );
        if (errorStr.contains('429') ||
            errorStr.contains('quota') ||
            errorStr.contains('resource_exhausted') ||
            errorStr.contains('limit') ||
            errorStr.contains('401') ||
            errorStr.contains('400') ||
            errorStr.contains('invalid')) {
          if (attempts < maxAttempts && _switchToNextKey()) {
            continue;
          }
        }
        rethrow;
      }
    }
    throw Exception('Tất cả các API Key dự phòng đều không thể kết nối hoặc hết hạn mức!');
  }

  // --- Lấy giờ ăn từ SharedPreferences -----------------------------------

  Future<Map<String, String>> _getMealTimes() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'breakfast': prefs.getString(AppKeys.breakfastTime) ?? '07:00',
      'lunch': prefs.getString(AppKeys.lunchTime) ?? '11:30',
      'dinner': prefs.getString(AppKeys.dinnerTime) ?? '18:00',
    };
  }

  // --- 1. Phân tích Đơn Thuốc (OCR) — trả về List<ParsedPrescription> ----

  Future<List<ParsedPrescription>> analyzePrescriptionImage(
      Uint8List imageBytes) async {
    // Defensive lazy init: ensure the model is ready before any network call.
    if (!isInitialized) {
      developer.log(
        'GeminiService.analyzePrescriptionImage: model not ready, calling initialize().',
        name: 'GeminiService',
      );
      initialize();
    }

    final mealTimes = await _getMealTimes();
    final breakfast = mealTimes['breakfast']!;
    final lunch = mealTimes['lunch']!;
    final dinner = mealTimes['dinner']!;

    return _executeWithRetry(() async {
      final prompt = '''
Bạn là một hệ thống OCR y tế chuyên nghiệp dành cho người cao tuổi Việt Nam.
Nhiệm vụ: đọc và trích xuất TOÀN BỘ thông tin đơn thuốc từ ảnh (in hoặc viết tay) với đầy đủ dấu tiếng Việt chuẩn xác.

GIỜ ĂN HIỆN TẠI CỦA NGƯỜI DÙNG:
- Bữa sáng: $breakfast
- Bữa trưa: $lunch
- Bữa tối: $dinner

QUAN TRỌNG: Chỉ trả về một MẢNG JSON hợp lệ (JSON Array). KHÔNG thêm văn bản phụ, giải thích hay markdown code block ngoài mảng JSON.

Cấu trúc MẢNG JSON:
[
  {
    "medicineName": "Tên thuốc đầy đủ có dấu tiếng Việt (kèm hàm lượng nếu có, ví dụ: Amlodipine 5mg)",
    "dosage": "Liều dùng mỗi lần (ví dụ: 1 viên, 2 viên, 5ml)",
    "scheduleTime": "Giờ uống chính xác dạng HH:mm (ví dụ: $breakfast, $lunch, $dinner)",
    "frequency": "Tần suất và lịch uống (ví dụ: Hằng ngày, 2 lần/ngày, Khi đau)",
    "instructions": "Lưu ý và hướng dẫn cụ thể có dấu tiếng Việt (ví dụ: Uống sau khi ăn no cùng nước ấm)"
  }
]

QUY TẮC TÁCH LIỀU (BẮT BUỘC):
- Nếu một loại thuốc được chỉ định uống nhiều lần trong ngày (ví dụ: "Sáng 1 viên, Tối 1 viên", "Ngày 3 lần", "3 viên / 3 bữa", "Sáng trưa tối"), BẮT BUỘC phải tách thành CÁC PHẦN TỬ RIÊNG BIỆT trong mảng JSON, mỗi phần tử tương ứng với một khung giờ uống cụ thể.
- Không gộp chung nhiều giờ uống vào một phần tử.

QUY TẮC TÍNH GIỜ (dùng giờ ăn của người dùng ở trên):
- "ăn sáng" / "bữa sáng" / "buổi sáng" / "sáng"           -> scheduleTime = "$breakfast"
- "ăn trưa" / "bữa trưa" / "buổi trưa" / "trưa"           -> scheduleTime = "$lunch"
- "ăn tối" / "bữa tối" / "buổi tối" / "tối"               -> scheduleTime = "$dinner"
- "trước ăn sáng X phút"                                  -> scheduleTime = (giờ ăn sáng $breakfast trừ đi X phút, dạng HH:mm)
- "sau ăn sáng X phút"                                    -> scheduleTime = (giờ ăn sáng $breakfast cộng thêm X phút, dạng HH:mm)
- "trước ăn trưa X phút"                                  -> scheduleTime = (giờ ăn trưa $lunch trừ đi X phút, dạng HH:mm)
- "sau ăn trưa X phút"                                    -> scheduleTime = (giờ ăn trưa $lunch cộng thêm X phút, dạng HH:mm)
- "trước ăn tối X phút"                                   -> scheduleTime = (giờ ăn tối $dinner trừ đi X phút, dạng HH:mm)
- "sau ăn tối X phút"                                     -> scheduleTime = (giờ ăn tối $dinner cộng thêm X phút, dạng HH:mm)
- "trước khi ngủ" / "đi ngủ" / "tối muộn"                 -> scheduleTime = "21:00"

Nếu không tìm thấy tên thuốc: medicineName = "Thuốc cần xác nhận (Xem ảnh)", dosage = "1 viên", scheduleTime = "$breakfast", frequency = "Hằng ngày", instructions = "Tham khảo ý kiến bác sĩ hoặc dược sĩ".
''';

      final mimeType = _detectMimeType(imageBytes);
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ]),
      ];

      final response = await _model!.generateContent(content);
      final rawText = response.text ?? '';
      return _parseGeminiPrescriptionJsonArray(rawText);
    });
  }

  String _detectMimeType(Uint8List bytes) {
    if (bytes.length >= 4) {
      if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
        return 'image/png';
      }
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'image/jpeg';
      }
      if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
        return 'image/webp';
      }
    }
    return 'image/jpeg';
  }

  List<ParsedPrescription> _parseGeminiPrescriptionJsonArray(String rawText) {
    try {
      String cleaned = rawText.trim();

      // Strip markdown code fences
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: false), '')
            .replaceAll(RegExp(r'\s*```\s*$', multiLine: false), '')
            .trim();
      }

      // --- Try parsing as JSON array first --------------------------------
      final arrayStart = cleaned.indexOf('[');
      final arrayEnd = cleaned.lastIndexOf(']');
      if (arrayStart != -1 && arrayEnd != -1 && arrayEnd > arrayStart) {
        final arrayStr = cleaned.substring(arrayStart, arrayEnd + 1);
        final decoded = jsonDecode(arrayStr);
        if (decoded is List) {
          final result = decoded
              .whereType<Map<String, dynamic>>()
              .map((j) => ParsedPrescription.fromJson(j))
              .where((p) => !p.isEmpty)
              .toList();
          if (result.isNotEmpty) return result;
        }
      }

      // --- Fallback: try single object ----------------------------------------
      final objStart = cleaned.indexOf('{');
      final objEnd = cleaned.lastIndexOf('}');
      if (objStart != -1 && objEnd != -1 && objEnd > objStart) {
        final objStr = cleaned.substring(objStart, objEnd + 1);
        final Map<String, dynamic> jsonMap = jsonDecode(objStr);
        final p = ParsedPrescription.fromJson(jsonMap);
        if (!p.isEmpty) return [p];
      }

      developer.log('Không parse được JSON từ Gemini: $rawText',
          name: 'GeminiService');
      return [];
    } catch (e) {
      developer.log('Lỗi parse JSON: $e - Nội dung gốc: $rawText',
          name: 'GeminiService');
      return [];
    }
  }

  void _assertInitialized() {
    if (_model == null) {
      throw StateError(
          'GeminiService chưa được khởi tạo. Hãy gọi initialize() trước.');
    }
  }
}
