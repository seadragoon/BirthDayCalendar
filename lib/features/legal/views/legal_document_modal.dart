import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:birthday_calendar/features/legal/models/legal_texts.dart';
import 'package:birthday_calendar/features/legal/widgets/contact_dialog.dart';
import 'package:birthday_calendar/shared/constants/app_constants.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

/// 利用規約 / プライバシーポリシー閲覧モーダル
class LegalDocumentModal extends StatelessWidget {
  final LegalDocumentType documentType;

  const LegalDocumentModal({
    super.key,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTerms = documentType == LegalDocumentType.termsOfService;
    final title = isTerms ? '利用規約' : 'プライバシーポリシー';
    final date = isTerms ? AppConstants.termsOfServiceLastUpdated : AppConstants.privacyPolicyLastUpdated;
    final sections = isTerms ? LegalTexts.getTermsOfService() : LegalTexts.getPrivacyPolicy();

    return BaseModal(
      title: title,
      customActions: [
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: '全文をコピー',
          onPressed: () async {
            final fullText = LegalTexts.getFullPlainText(documentType);
            await Clipboard.setData(ClipboardData(text: fullText));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$titleをクリップボードにコピーしました'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.update_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '最終改定日: $date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            _buildSectionCard(context, section),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          Center(
            child: Text(
              AppConstants.copyright,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ContactDialog(),
              );
            },
            icon: const Icon(Icons.mail_outline),
            label: const Text('ご不明な点はお問い合わせください'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, LegalSection section) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section.body,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
