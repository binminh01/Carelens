import 'package:flutter_test/flutter_test.dart';
import 'package:carelens/core/utils/app_utils.dart';

void main() {
  group('AppUtils Tests', () {
    test('getGreeting returns valid string according to current hour', () {
      final greeting = AppUtils.getGreeting();
      final hour = DateTime.now().hour;
      if (hour >= 4 && hour < 12) {
        expect(greeting, 'Chào buổi sáng');
      } else if (hour >= 12 && hour < 18) {
        expect(greeting, 'Chào buổi chiều');
      } else {
        expect(greeting, 'Chào buổi tối');
      }
    });

    test('evaluateBloodPressure handles normal, warning, danger correctly', () {
      expect(AppUtils.evaluateBloodPressure(120, 80), HealthStatus.normal);
      expect(AppUtils.evaluateBloodPressure(145, 95), HealthStatus.danger);
      expect(AppUtils.evaluateBloodPressure(85, 55), HealthStatus.warning);
    });

    test('evaluateOxygen handles oxygen thresholds correctly', () {
      expect(AppUtils.evaluateOxygen(98), HealthStatus.normal);
      expect(AppUtils.evaluateOxygen(96), HealthStatus.warning);
      expect(AppUtils.evaluateOxygen(92), HealthStatus.danger);
    });
  });
}
