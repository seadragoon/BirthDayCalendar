import 'package:flutter_test/flutter_test.dart';
import 'package:birthday_calendar/features/security/models/security_settings.dart';
import 'package:birthday_calendar/features/security/services/security_service.dart';

void main() {
  group('SecuritySettings Tests', () {
    test('default values are secure and disabled', () {
      const settings = SecuritySettings();
      expect(settings.isPasscodeEnabled, isFalse);
      expect(settings.passcodeHash, isNull);
      expect(settings.passcodeSalt, isNull);
      expect(settings.isBiometricEnabled, isFalse);
      expect(settings.autoLockIntervalSeconds, equals(0));
      expect(settings.hasValidPasscode, isFalse);
    });

    test('hasValidPasscode returns true only when enabled and hash/salt exist', () {
      const settingsValid = SecuritySettings(
        isPasscodeEnabled: true,
        passcodeHash: 'sample_hash',
        passcodeSalt: 'sample_salt',
      );
      expect(settingsValid.hasValidPasscode, isTrue);

      const settingsDisabled = SecuritySettings(
        isPasscodeEnabled: false,
        passcodeHash: 'sample_hash',
        passcodeSalt: 'sample_salt',
      );
      expect(settingsDisabled.hasValidPasscode, isFalse);

      const settingsMissingHash = SecuritySettings(
        isPasscodeEnabled: true,
        passcodeSalt: 'sample_salt',
      );
      expect(settingsMissingHash.hasValidPasscode, isFalse);
    });

    test('copyWith and clearPasscode work properly', () {
      const original = SecuritySettings(
        isPasscodeEnabled: true,
        passcodeHash: 'hash123',
        passcodeSalt: 'salt123',
        isBiometricEnabled: true,
        autoLockIntervalSeconds: 60,
      );

      final updated = original.copyWith(autoLockIntervalSeconds: 300);
      expect(updated.autoLockIntervalSeconds, equals(300));
      expect(updated.isPasscodeEnabled, isTrue);
      expect(updated.passcodeHash, equals('hash123'));

      final cleared = original.copyWith(clearPasscode: true);
      expect(cleared.isPasscodeEnabled, isFalse);
      expect(cleared.passcodeHash, isNull);
      expect(cleared.passcodeSalt, isNull);
      expect(cleared.isBiometricEnabled, isFalse);
      expect(cleared.autoLockIntervalSeconds, equals(60)); // 間隔は維持
    });

    test('serialization and deserialization preserves all fields', () {
      const settings = SecuritySettings(
        isPasscodeEnabled: true,
        passcodeHash: 'hash_abc',
        passcodeSalt: 'salt_xyz',
        isBiometricEnabled: true,
        autoLockIntervalSeconds: 300,
      );

      final json = settings.toJson();
      final restored = SecuritySettings.fromJson(json);

      expect(restored.isPasscodeEnabled, isTrue);
      expect(restored.passcodeHash, equals('hash_abc'));
      expect(restored.passcodeSalt, equals('salt_xyz'));
      expect(restored.isBiometricEnabled, isTrue);
      expect(restored.autoLockIntervalSeconds, equals(300));
    });
  });

  group('SecurityService Tests', () {
    final service = SecurityService.instance;

    test('generateSalt generates unique non-empty salts', () {
      final salt1 = service.generateSalt();
      final salt2 = service.generateSalt();

      expect(salt1.isNotEmpty, isTrue);
      expect(salt2.isNotEmpty, isTrue);
      expect(salt1, isNot(equals(salt2)));
    });

    test('hashPasscode produces deterministic and collision-free hashes', () {
      const pin = '1234';
      final salt = service.generateSalt();

      final hash1 = service.hashPasscode(pin, salt);
      final hash2 = service.hashPasscode(pin, salt);
      expect(hash1, equals(hash2));

      // 別のPIN
      final hashOtherPin = service.hashPasscode('5678', salt);
      expect(hash1, isNot(equals(hashOtherPin)));

      // 別のソルト
      final otherSalt = service.generateSalt();
      final hashOtherSalt = service.hashPasscode(pin, otherSalt);
      expect(hash1, isNot(equals(hashOtherSalt)));
    });

    test('verifyPasscode correctly verifies matching and non-matching PINs', () {
      const correctPin = '7890';
      const wrongPin = '0000';
      final salt = service.generateSalt();
      final hash = service.hashPasscode(correctPin, salt);

      final settings = SecuritySettings(
        isPasscodeEnabled: true,
        passcodeHash: hash,
        passcodeSalt: salt,
      );

      expect(service.verifyPasscode(correctPin, settings), isTrue);
      expect(service.verifyPasscode(wrongPin, settings), isFalse);

      // パスコード無効設定の場合は常にfalse
      final disabledSettings = settings.copyWith(isPasscodeEnabled: false);
      expect(service.verifyPasscode(correctPin, disabledSettings), isFalse);
    });
  });
}

