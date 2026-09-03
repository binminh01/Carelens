import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../models/prescription.dart';
import 'notification_service.dart';

/// Dịch vụ quản lý cơ sở dữ liệu Isar Database cho CareLens (hoạt động hoàn toàn Offline)
class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Isar? _isar;

  bool get isInitialized => _isar != null && _isar!.isOpen;

  Isar get isar {
    if (_isar == null || !_isar!.isOpen) {
      throw StateError(
        'Isar chưa được khởi tạo. Vui lòng gọi IsarService.instance.initialize() trước.',
      );
    }
    return _isar!;
  }

  // ─── Khởi tạo Isar DB ──────────────────────────────────────────────────

  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [PrescriptionSchema],
        directory: dir.path,
        name: AppConstants.dbName,
        inspector: kDebugMode,
      );
      developer.log('Isar Database initialized successfully at: ${dir.path}');
    } catch (e, stack) {
      developer.log(
        'Lỗi khi khởi tạo Isar Database: $e',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  // ─── CRUD Đơn thuốc (Prescription) ───────────────────────────────────

  /// Lấy tất cả đơn thuốc
  Future<List<Prescription>> getAllPrescriptions() async {
    if (!isInitialized) return [];
    return await isar.prescriptions.where().sortByCreatedAtDesc().findAll();
  }

  /// Lấy danh sách thuốc của ngày hôm nay
  Future<List<Prescription>> getTodayPrescriptions() async {
    if (!isInitialized) return [];
    return await isar.prescriptions.where().findAll();
  }

  /// Stream theo dõi danh sách thuốc theo thời gian thực (Reactive Stream)
  Stream<List<Prescription>> watchTodayPrescriptions() {
    if (!isInitialized) {
      return Stream.value(<Prescription>[]);
    }
    return isar.prescriptions.where().watch(fireImmediately: true);
  }

  /// Thêm mới hoặc cập nhật đơn thuốc, đồng thời tự động lên lịch thông báo
  Future<int> savePrescription(Prescription prescription) async {
    final id = await isar.writeTxn(() async {
      return await isar.prescriptions.put(prescription);
    });

    prescription.id = id;

    // Tự động lên lịch thông báo nhắc nhở hằng ngày cho đơn thuốc vừa lưu
    try {
      await NotificationService.instance.schedulePrescriptionReminder(prescription);
    } catch (e) {
      developer.log('Lỗi khi tự động lên lịch thông báo cho thuốc ID $id: $e');
    }

    return id;
  }

  /// Chuyển đổi trạng thái đã uống / chưa uống
  Future<bool> toggleIntakeStatus(int id) async {
    return await isar.writeTxn(() async {
      final prescription = await isar.prescriptions.get(id);
      if (prescription != null) {
        prescription.isTaken = !prescription.isTaken;
        await isar.prescriptions.put(prescription);
        return prescription.isTaken;
      }
      return false;
    });
  }

  /// Cập nhật trạng thái đã uống (dùng cho thông báo và hành động trực tiếp)
  Future<bool> setIntakeStatus(int id, bool isTaken) async {
    return await isar.writeTxn(() async {
      final prescription = await isar.prescriptions.get(id);
      if (prescription != null) {
        prescription.isTaken = isTaken;
        await isar.prescriptions.put(prescription);
        return true;
      }
      return false;
    });
  }

  /// Đặt lại trạng thái tất cả thuốc về chưa uống (ví dụ sang ngày mới)
  Future<void> resetAllIntakeStatus() async {
    await isar.writeTxn(() async {
      final list = await isar.prescriptions.where().findAll();
      for (final p in list) {
        p.isTaken = false;
        await isar.prescriptions.put(p);
      }
    });
  }

  /// Xóa một đơn thuốc theo ID và hủy thông báo tương ứng
  Future<bool> deletePrescription(int id) async {
    final deleted = await isar.writeTxn(() async {
      return await isar.prescriptions.delete(id);
    });

    if (deleted) {
      // Hủy thông báo nhắc nhở đã lên lịch
      try {
        await NotificationService.instance.cancelReminder(id);
      } catch (e) {
        developer.log('Lỗi khi hủy thông báo cho thuốc đã xóa ID $id: $e');
      }
    }

    return deleted;
  }

  /// Lên lịch lại toàn bộ thông báo cho tất cả đơn thuốc đang có trong database
  Future<void> rescheduleAllReminders() async {
    final prescriptions = await getAllPrescriptions();
    for (final p in prescriptions) {
      await NotificationService.instance.schedulePrescriptionReminder(p);
    }
    developer.log('Đã lên lịch lại thông báo cho ${prescriptions.length} đơn thuốc.');
  }

  // ─── Dữ liệu mẫu (Seed Data) ─────────────────────────────────────────

  /// Nạp dữ liệu mẫu bất kể database có dữ liệu hay không (do người dùng chủ động kích hoạt)
  Future<void> seedSampleData() async {
    final sampleMedicines = [
      Prescription.create(
        medicineName: 'Amlodipine 5mg',
        dosage: '1 viên sau ăn sáng',
        scheduleTime: '08:00',
        frequency: 'Hằng ngày',
        isTaken: true,
        instructions: 'Kiểm soát huyết áp, uống cùng 1 ly nước ấm.',
      ),
      Prescription.create(
        medicineName: 'Metformin 500mg',
        dosage: '1 viên cùng bữa trưa',
        scheduleTime: '12:00',
        frequency: '2 lần / ngày',
        isTaken: false,
        instructions: 'Hỗ trợ ổn định đường huyết sau bữa ăn.',
      ),
      Prescription.create(
        medicineName: 'Omega 3 & Canxi D3',
        dosage: '2 viên sau ăn tối',
        scheduleTime: '19:30',
        frequency: 'Hằng ngày',
        isTaken: false,
        instructions: 'Bổ sung sức khỏe tim mạch và xương khớp.',
      ),
      Prescription.create(
        medicineName: 'Panadol Extra',
        dosage: '1 viên khi đau đầu',
        scheduleTime: 'Khi cần',
        frequency: 'Cách nhau 6 tiếng',
        isTaken: false,
        instructions: 'Chỉ uống khi bị đau hoặc sốt.',
      ),
    ];

    await isar.writeTxn(() async {
      await isar.prescriptions.putAll(sampleMedicines);
    });

    for (final med in sampleMedicines) {
      if (med.scheduleTime != 'Khi cần') {
        try {
          await NotificationService.instance.schedulePrescriptionReminder(med);
        } catch (_) {}
      }
    }

    developer.log('Force-seeded ${sampleMedicines.length} sample prescriptions into Isar.');
  }

  /// Nạp các liều thuốc mẫu phổ biến của người cao tuổi nếu cơ sở dữ liệu trống
  Future<void> seedSampleDataIfEmpty() async {
    final count = await isar.prescriptions.count();
    if (count == 0) {
      final sampleMedicines = [
        Prescription.create(
          medicineName: 'Amlodipine 5mg',
          dosage: '1 viên sau ăn sáng',
          scheduleTime: '08:00',
          frequency: 'Hằng ngày',
          isTaken: true,
          instructions: 'Kiểm soát huyết áp, uống cùng 1 ly nước ấm.',
        ),
        Prescription.create(
          medicineName: 'Metformin 500mg',
          dosage: '1 viên cùng bữa trưa',
          scheduleTime: '12:00',
          frequency: '2 lần / ngày',
          isTaken: false,
          instructions: 'Hỗ trợ ổn định đường huyết sau bữa ăn.',
        ),
        Prescription.create(
          medicineName: 'Omega 3 & Canxi D3',
          dosage: '2 viên sau ăn tối',
          scheduleTime: '19:30',
          frequency: 'Hằng ngày',
          isTaken: false,
          instructions: 'Bổ sung sức khỏe tim mạch và xương khớp.',
        ),
        Prescription.create(
          medicineName: 'Panadol Extra',
          dosage: '1 viên khi đau đầu',
          scheduleTime: 'Khi cần',
          frequency: 'Cách nhau 6 tiếng',
          isTaken: false,
          instructions: 'Chỉ uống khi bị đau hoặc sốt.',
        ),
      ];

      await isar.writeTxn(() async {
        await isar.prescriptions.putAll(sampleMedicines);
      });

      // Lên lịch nhắc nhở cho các thuốc có giờ cố định
      for (final med in sampleMedicines) {
        if (med.scheduleTime != 'Khi cần') {
          try {
            await NotificationService.instance.schedulePrescriptionReminder(med);
          } catch (_) {}
        }
      }

      developer.log('Seeded ${sampleMedicines.length} sample prescriptions into Isar.');
    }
  }

  /// Đóng cơ sở dữ liệu khi không cần dùng nữa
  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }
}
