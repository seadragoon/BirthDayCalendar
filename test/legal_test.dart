import 'package:flutter_test/flutter_test.dart';
import 'package:birthday_calendar/features/legal/models/legal_texts.dart';
import 'package:birthday_calendar/features/legal/services/contact_service.dart';

void main() {
  group('LegalTexts Tests', () {
    test('Terms of Service contains required articles and valid plain text', () {
      final terms = LegalTexts.getTermsOfService();
      expect(terms.isNotEmpty, isTrue);
      expect(terms.any((s) => s.title.contains('第1条')), isTrue);
      expect(terms.any((s) => s.title.contains('バックアップ')), isTrue);
      expect(terms.any((s) => s.title.contains('免責事項')), isTrue);

      final fullText = LegalTexts.getFullPlainText(LegalDocumentType.termsOfService);
      expect(fullText.contains('利用規約'), isTrue);
      expect(fullText.contains('第1条'), isTrue);
    });

    test('Privacy Policy contains required sections and valid plain text', () {
      final privacy = LegalTexts.getPrivacyPolicy();
      expect(privacy.isNotEmpty, isTrue);
      expect(privacy.any((s) => s.title.contains('基本方針')), isTrue);
      expect(privacy.any((s) => s.title.contains('権限')), isTrue);
      expect(privacy.any((s) => s.title.contains('バックアップ')), isTrue);

      final fullText = LegalTexts.getFullPlainText(LegalDocumentType.privacyPolicy);
      expect(fullText.contains('プライバシーポリシー'), isTrue);
      expect(fullText.contains('READ_CONTACTS'), isTrue);
    });
  });

  group('ContactService Tests', () {
    test('generateEmailBodyTemplate includes app name and version', () {
      final template = ContactService.generateEmailBodyTemplate();
      expect(template.contains('BirthDay Calendar'), isTrue);
      expect(template.contains('OS:'), isTrue);
      expect(template.contains('お問い合わせ'), isTrue);
    });
  });
}
