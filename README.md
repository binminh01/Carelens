# 🌟 CareLens - Trợ lý Sức khỏe Cao tuổi

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white" alt="Flutter Version" />
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white" alt="Dart Version" />
  <img src="https://img.shields.io/badge/Java-17-ED8B00?logo=openjdk&logoColor=white" alt="Java 17" />
  <img src="https://img.shields.io/badge/AI-Google%20Gemini%20Flash-8E75B2?logo=google&logoColor=white" alt="Gemini AI" />
  <img src="https://img.shields.io/badge/Database-Isar%20Offline%20NoSQL-4A90E2" alt="Isar Database" />
  <img src="https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white" alt="GitHub Actions" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
</p>

---

## 📖 1. Giới thiệu tổng quan (Project Overview)

**CareLens - Trợ lý Sức khỏe Cao tuổi** là giải pháp ứng dụng di động toàn diện được thiết kế chuyên biệt dành cho người cao tuổi tại Việt Nam và gia đình người chăm sóc. 

Ứng dụng hướng tới mục tiêu đơn giản hóa tối đa việc quản lý y tế cá nhân:
- 💊 **Quản lý lịch uống thuốc thân thiện**: Trực quan, dễ quan sát, không đòi hỏi thao tác phức tạp.
- 📸 **Quét đơn thuốc thông minh bằng AI (OCR)**: Tự động trích xuất thông tin liều lượng, tên thuốc, lời dặn bác sĩ chỉ qua một bức ảnh chụp hoặc tải từ thư viện.
- ⏰ **Nhắc nhở & Báo thức Offline chuẩn xác**: Thông báo báo thức kèm chuông và rung vượt chế độ im lặng, hoạt động độc lập không cần kết nối mạng.
- 📄 **Xuất báo cáo lịch sử y tế (PDF/CSV)**: Tổng hợp lịch sử tuân thủ uống thuốc để chia sẻ nhanh cho bác sĩ hoặc con cháu qua Zalo, Email.

---

## ⚡ 2. Các Tính Năng Cốt Lõi (Key Features)

### 🧠 2.1. Quét Đơn Thuốc AI Bằng Google Gemini (`google_generative_ai`)
- Tích hợp mô hình thị giác AI đa phương thức (**Gemini Flash**) đọc và hiểu cả đơn thuốc in lẫn viết tay bằng tiếng Việt có dấu.
- Tự động bóc tách thành các thực thể: Tên thuốc, hàm lượng, liều dùng mỗi lần, khung giờ uống (sáng, trưa, tối) tương ứng với giờ ăn cá nhân hóa của người dùng.
- Cơ chế tự động luân chuyển (rotate) đa API Key dự phòng, ngăn ngừa gián đoạn do vượt hạn mức (quota limit).
- Hỗ trợ chụp trực tiếp từ Camera lẫn chọn ảnh từ Thư viện (Gallery) với cơ chế phân quyền tương thích từ Android 6 đến Android 14+ (`READ_MEDIA_VISUAL_USER_SELECTED`).

### 👵 2.2. Giao diện Thân thiện cho Người Lớn Tuổi (Senior-Friendly UI/UX)
- **Độ tương phản cao (High-Contrast Theme)**: Nền tối Deep Navy kết hợp màu nhấn Xanh ngọc (`#10B981`) và Cam cảnh báo (`#F59E0B`), chống lóa mỏi mắt và gia tăng nhận diện thị giác.
- **Typography kích thước lớn**: Cỡ chữ tiêu đề từ `22sp - 28sp`, nội dung tối thiểu `>= 16sp`, đáp ứng tiêu chuẩn tiếp cận khả năng đọc cho người mắt kém.
- **Thiết kế chống bấm nhầm (Anti-Accidental Touch)**: Phím bấm kích thước lớn (chiều cao `56px - 72px`), vùng chạm rộng rãi, tích hợp phản hồi rung xúc giác (`HapticFeedback`) xác nhận mỗi thao tác.

### 💾 2.3. Kiến trúc Hoạt Động Ngoại Tuyến (Offline-First Architecture)
- **Cơ sở dữ liệu cục bộ Isar NoSQL**: Tốc độ truy vấn mili-giây, lưu trữ hồ sơ thuốc, lịch sử uống thuốc an toàn 100% trên bộ nhớ thiết bị.
- **Báo thức thông báo chính xác (`flutter_local_notifications` v22+ & Timezone)**:
  - Sử dụng kênh thông báo Alarm ưu tiên tối đa (`Importance.max`, `AudioAttributesUsage.alarm`).
  - Hỗ trợ màn hình khóa (`fullScreenIntent`) và khôi phục lịch báo thức sau khi khởi động lại điện thoại (`RECEIVE_BOOT_COMPLETED`).
  - Đồng bộ tự động theo múi giờ địa phương (`Asia/Ho_Chi_Minh`).

### 📑 2.4. Xuất Báo Cáo & Lịch Sử Y Tế (PDF / CSV Export)
- Kết xuất báo cáo y tế định dạng PDF chuẩn tiếng Việt với bảng biểu tiến độ tuân thủ điều trị.
- Tích hợp chia sẻ một chạm qua nền tảng mạng xã hội hoặc in trực tiếp cho bác sĩ trong các đợt tái khám định kỳ.

---

## 🛠️ 3. Ngăn Xếp Công Nghệ & Yêu Cầu Tiền Đề (Tech Stack & Prerequisites)

### Công nghệ sử dụng:
- **Framework**: Flutter SDK (Stable Channel, phiên bản `>= 3.13.0`)
- **Ngôn ngữ**: Dart (phiên bản `>= 3.0.0`)
- **JDK Target**: **Java 17 (Temurin / OpenJDK 17)** & Kotlin với JVM Target 17
- **Quản lý trạng thái & DI**: Provider / Service Pattern
- **Lưu trữ dữ liệu**: Isar Database (`isar: ^3.1.0+1`, `isar_flutter_libs`)
- **Xử lý AI**: `google_generative_ai: ^0.4.6`
- **Thông báo & Báo thức**: `flutter_local_notifications: ^22.0.0`, `flutter_timezone: ^5.0.0`, `timezone`
- **Tài liệu & Tiện ích**: `pdf: ^3.11.1`, `image_picker: ^1.1.2`, `camera: ^0.11.0+2`

### Yêu cầu môi trường phát triển:
1. **Flutter SDK**: Đã cài đặt và cấu hình biến môi trường `PATH`. Kiểm tra bằng lệnh `flutter --version`.
2. **Java 17**: Cài đặt OpenJDK 17 hoặc Microsoft Build of OpenJDK 17. Kiểm tra bằng lệnh `java --version`.
3. **Google Gemini API Key**: Đăng ký miễn phí tại [Google AI Studio](https://aistudio.google.com/).

---

## 💻 4. Hướng dẫn Cài đặt & Chạy trên Môi trường Windows (Local Setup)

Các bước thực hiện chi tiết trên Windows Command Prompt (CMD) hoặc Windows PowerShell:

### Bước 1: Sao chép mã nguồn (Clone Repository)
```powershell
git clone https://github.com/binminh01/Carelens.git
cd Carelens
```

### Bước 2: Cài đặt các gói phụ thuộc (Dependencies)
```powershell
flutter pub get
```

*(Tùy chọn) Nếu bạn thay đổi model cơ sở dữ liệu Isar, hãy chạy lệnh sinh mã:*
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

### Bước 3: Cấu hình Gemini API Key
CareLens hỗ trợ nạp API Key qua tệp biến môi trường `.env` hoặc trực tiếp trong tệp cấu hình:

**Cách 1: Cấu hình qua tệp `.env` ở thư mục gốc dự án (Khuyến nghị):**
Tạo hoặc mở tệp `.env` tại thư mục gốc `Carelens\.env`:
```env
GEMINI_KEY_1=AIzaSyYourPrimaryGeminiApiKeyHere
GEMINI_KEY_2=AIzaSyYourSecondaryGeminiApiKeyHere
GEMINI_KEY_3=
GEMINI_KEY_4=
GEMINI_KEY_5=
```

**Cách 2: Kiểm tra cấu hình trong mã nguồn:**
Tệp `lib/core/constants/app_constants.dart` sẽ tự động đọc danh sách key từ `.env`:
```dart
// lib/core/constants/app_constants.dart
static List<String> get geminiApiKeys => [
      dotenv.env['GEMINI_KEY_1'] ?? '',
      dotenv.env['GEMINI_KEY_2'] ?? '',
      dotenv.env['GEMINI_KEY_3'] ?? '',
      dotenv.env['GEMINI_KEY_4'] ?? '',
      dotenv.env['GEMINI_KEY_5'] ?? '',
    ]
        .where((key) => key.isNotEmpty)
        .cast<String>()
        .toList();
```

### Bước 4: Chạy ứng dụng trên thiết bị / máy ảo
Đảm bảo đã kết nối thiết bị qua cáp USB hoặc Wi-Fi ADB:
```powershell
# Xem danh sách thiết bị nhận diện được
flutter devices

# Khởi chạy ứng dụng (chế độ Debug)
flutter run
```

---

## 📦 5. Đóng Gói Ứng Dụng & Quy Trình Phát Hành Tự Động (Build & Release)

### 5.1. Đóng gói Release APK cục bộ (Local Build trên Windows)
Để tạo bộ cài đặt tối ưu dung lượng nhất cho từng kiến trúc chip điện thoại (ARM64, ARMv7, x86_64), hãy chạy lệnh:

```powershell
flutter build apk --release --split-per-abi
```

Sau khi quá trình biên dịch hoàn tất, các tệp APK xuất xưởng sẽ nằm tại:
```
build\app\outputs\flutter-apk\
├── app-arm64-v8a-release.apk     (Dành cho hầu hết điện thoại Android hiện đại - Khuyên dùng)
├── app-armeabi-v7a-release.apk   (Dành cho các dòng máy Android đời cũ 32-bit)
├── app-x86_64-release.apk        (Dành cho máy ảo hoặc thiết bị chạy chip Intel/AMD)
└── app-release.apk               (Bản cài đặt Universal tích hợp đầy đủ mọi kiến trúc)
```

---

### 5.2. Tự Động Hóa Phát Hành Qua GitHub Actions (CI/CD Release Workflow)
Dự án được tích hợp sẵn luồng CI/CD hoàn chỉnh tại `.github/workflows/release.yml` sử dụng Action chính thức `subosito/flutter-action@v2`:

1. **Khi đẩy mã nguồn lên nhánh `main` (`git push origin main`)**:
   - Tự động chạy kiểm thử, tải dependencies, biên dịch Release APK trên máy ảo Ubuntu.
   - Lưu trữ các tệp APK thành **Workflow Artifacts** trong vòng 90 ngày để đội ngũ QA tải về kiểm thử nhanh.

2. **Khi phát hành phiên bản mới qua Git Tag (`v*`)**:
   - Hệ thống tự động kích hoạt tiến trình tạo **GitHub Release**.
   - Tự động đính kèm toàn bộ 4 tệp APK (`arm64-v8a`, `armeabi-v7a`, `x86_64`, `universal`) vào trang Releases của Repository.

#### Thao tác tạo và đẩy Tag phát hành từ Windows Terminal:
```powershell
# 1. Tạo tag phiên bản mới
git tag v1.0.0

# 2. Đẩy tag lên GitHub để kích hoạt CI/CD
git push origin v1.0.0
```

---

## 📂 6. Cấu Trúc Thư Mục Dự Án (Project Structure)

```
Carelens/
├── .github/
│   └── workflows/
│       └── release.yml              # Quy trình CI/CD tự động build & release GitHub
├── android/                         # Cấu hình Native Android (Java 17, Gradle Kotlin DSL, Manifest)
│   ├── app/
│   │   ├── build.gradle.kts         # Java 17 toolchain, desugar_jdk_libs 2.1.4
│   │   └── src/main/
│   │       └── AndroidManifest.xml  # Toàn quyền Camera, Storage, Media, Alarm, Boot
│   └── build.gradle.kts             # Cấu hình compileOptions JVM 17 toàn bộ subprojects
├── assets/
│   ├── icons/                       # Icon ứng dụng và các nút điều hướng
│   └── images/                      # Hình minh họa giao diện
├── lib/
│   ├── core/                        # Tầng dùng chung (Core layer)
│   │   ├── constants/               # Hằng số, API Keys, Routes (app_constants.dart)
│   │   ├── models/                  # Isar Data Models (prescription.dart, etc.)
│   │   ├── services/                # Services: Gemini OCR, Isar DB, Notifications, PDF
│   │   ├── theme/                   # Hệ thống bảng màu cao độ tương phản (app_theme.dart)
│   │   └── utils/                   # Hàm tiện ích định dạng ngày giờ, âm thanh, rung
│   ├── features/                    # Tầng nghiệp vụ chức năng (Feature-first)
│   │   ├── home/screens/            # Màn hình chính: Danh sách thuốc & tiến độ uống trong ngày
│   │   ├── scan/screens/            # Màn hình quét OCR: Live Camera ngắm định vị & Thư viện ảnh
│   │   ├── settings/screens/        # Cài đặt giờ ăn (Sáng/Trưa/Tối), test chuông báo thức
│   │   └── report/screens/          # Báo cáo sức khỏe & xuất tệp PDF chia sẻ
│   ├── app.dart                     # Cấu hình MaterialApp, Navigation Shell 3 tab
│   └── main.dart                    # Điểm khởi đầu ứng dụng: Nạp .env, Isar, Timezone
├── .env                             # Khai báo các API Key Google Gemini dự phòng
├── pubspec.yaml                     # Khai báo thư viện & tài nguyên của ứng dụng
└── README.md                        # Tài liệu hướng dẫn phát triển và sử dụng
```

---

## 📜 7. Bản Quyền & Giấy Phép (License)

Dự án được phát triển dưới giấy phép mã nguồn mở [MIT License](LICENSE). Mọi cá nhân, tổ chức đều có thể tự do sử dụng, chỉnh sửa và đóng góp cho sự phát triển của các giải pháp công nghệ chăm sóc sức khỏe cộng đồng người cao tuổi.
