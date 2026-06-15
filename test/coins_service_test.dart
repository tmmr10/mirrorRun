import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mirror_run/services/coins_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CoinsService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = CoinsService();
    await service.init();
  });

  group('CoinsService.init', () {
    test('starts at zero with empty prefs', () {
      expect(service.totalCoins, 0);
      expect(service.sessionEarned, 0);
      expect(service.coinsNotifier.value, 0);
    });

    test('restores totalCoins from persisted prefs', () async {
      SharedPreferences.setMockInitialValues({'coins_total': 137});
      final restored = CoinsService();
      await restored.init();
      expect(restored.totalCoins, 137);
      expect(restored.coinsNotifier.value, 137);
      // sessionEarned is per-run and not persisted.
      expect(restored.sessionEarned, 0);
    });
  });

  group('CoinsService.addCoins', () {
    test('adds a positive amount to total and session', () async {
      await service.addCoins(10);
      await service.addCoins(5);
      expect(service.totalCoins, 15);
      expect(service.sessionEarned, 15);
      expect(service.coinsNotifier.value, 15);
    });

    test('ignores zero and negative amounts', () async {
      await service.addCoins(20);
      await service.addCoins(0);
      await service.addCoins(-50);
      expect(service.totalCoins, 20);
      expect(service.sessionEarned, 20);
      expect(service.coinsNotifier.value, 20);
    });

    test('persists total across a fresh init', () async {
      await service.addCoins(42);
      // Allow the unawaited write to flush.
      await Future<void>.delayed(Duration.zero);

      final reloaded = CoinsService();
      await reloaded.init();
      expect(reloaded.totalCoins, 42);
    });
  });

  group('CoinsService.spendCoins', () {
    test('spends when sufficient balance and returns true', () async {
      await service.addCoins(100);
      final ok = await service.spendCoins(30);
      expect(ok, isTrue);
      expect(service.totalCoins, 70);
      expect(service.coinsNotifier.value, 70);
    });

    test('returns false and does not deduct on insufficient balance', () async {
      await service.addCoins(20);
      final ok = await service.spendCoins(50);
      expect(ok, isFalse);
      expect(service.totalCoins, 20);
      expect(service.coinsNotifier.value, 20);
    });

    test('spending exactly the balance succeeds and reaches zero', () async {
      await service.addCoins(25);
      final ok = await service.spendCoins(25);
      expect(ok, isTrue);
      expect(service.totalCoins, 0);
    });

    test('zero or negative spend returns true without changing balance', () async {
      await service.addCoins(40);
      expect(await service.spendCoins(0), isTrue);
      expect(await service.spendCoins(-10), isTrue);
      expect(service.totalCoins, 40);
      expect(service.coinsNotifier.value, 40);
    });

    test('spending does not touch sessionEarned', () async {
      await service.addCoins(60);
      expect(service.sessionEarned, 60);
      await service.spendCoins(40);
      // sessionEarned only tracks what was earned this run, not spending.
      expect(service.sessionEarned, 60);
      expect(service.totalCoins, 20);
    });

    test('persists reduced total across a fresh init', () async {
      await service.addCoins(100);
      await service.spendCoins(35);

      final reloaded = CoinsService();
      await reloaded.init();
      expect(reloaded.totalCoins, 65);
    });
  });

  group('CoinsService.resetSession', () {
    test('resets sessionEarned but keeps totalCoins', () async {
      await service.addCoins(80);
      expect(service.sessionEarned, 80);

      service.resetSession();
      expect(service.sessionEarned, 0);
      expect(service.totalCoins, 80);

      // A new run accumulates fresh session earnings.
      await service.addCoins(15);
      expect(service.sessionEarned, 15);
      expect(service.totalCoins, 95);
    });
  });
}
