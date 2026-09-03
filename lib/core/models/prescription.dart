import 'package:isar/isar.dart';

part 'prescription.g.dart';

@collection
class Prescription {
  Id id = Isar.autoIncrement;

  /// Tên thuốc (ví dụ: Amlodipine, Panadol, Metformin)
  late String medicineName;

  /// Liều dùng (ví dụ: 1 viên, 2 viên, 500mg)
  late String dosage;

  /// Giờ uống (ví dụ: 08:00, 12:00, 20:00)
  late String scheduleTime;

  /// Tần suất (ví dụ: Hằng ngày, 2 lần/ngày, Khi cần)
  late String frequency;

  /// Trạng thái đã uống thuốc hay chưa
  bool isTaken = false;

  /// Thời gian tạo đơn
  late DateTime createdAt;

  /// Hướng dẫn / Lưu ý thêm (ví dụ: Uống sau khi ăn no)
  String? instructions;

  Prescription({
    this.id = Isar.autoIncrement,
    required this.medicineName,
    required this.dosage,
    required this.scheduleTime,
    required this.frequency,
    this.isTaken = false,
    required this.createdAt,
    this.instructions,
  });

  /// Factory helper for creating new prescriptions with auto-filled createdAt
  factory Prescription.create({
    required String medicineName,
    required String dosage,
    required String scheduleTime,
    required String frequency,
    bool isTaken = false,
    String? instructions,
  }) {
    return Prescription(
      medicineName: medicineName,
      dosage: dosage,
      scheduleTime: scheduleTime,
      frequency: frequency,
      isTaken: isTaken,
      createdAt: DateTime.now(),
      instructions: instructions,
    );
  }
}
