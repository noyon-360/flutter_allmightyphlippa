import 'package:flutter/material.dart';
import '../../../core/common/widgets/tv_key_scroll.dart';
import 'package:flutx_core/flutx_core.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        elevation: 0,
        leading: BackButton(color: context.palette.textPrimary),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: TvKeyScroll(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Privacy Policy',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap.h8,
              Text(
                'Last updated: January 27, 2026',
                style: TextStyle(color: context.palette.textSecondary, fontSize: 12),
              ),
              Gap.h24,
              _buildSection(
                context,
                '1. Information Collection',
                'We collect information that you provide directly to us when you create an account, use our services, or communicate with us.',
              ),
              _buildSection(
                context,
                '2. How We Use Information',
                'We use the information we collect to provide, maintain, and improve our services, develop new ones, and protect LABBY TV and our users.',
              ),
              _buildSection(
                context,
                '3. Information Sharing',
                'We do not share your personal information with companies, organizations, or individuals outside of LABBY TV except in the following cases: with your consent, for external processing, or for legal reasons.',
              ),
              _buildSection(
                context,
                '4. Data Security',
                'We work hard to protect LABBY TV and our users from unauthorized access to or unauthorized alteration, disclosure, or destruction of information we hold.',
              ),
              _buildSection(
                context,
                '5. Your Choices',
                'You have choices regarding the information we collect and how it is used. You can access and update your information through your account settings.',
              ),
              Gap.h24,
              Text(
                'If you have any questions about this Privacy Policy, please contact us.',
                style: TextStyle(
                  color: context.palette.textPrimary,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Gap.h32,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Gap.h8,
        Text(
          content,
          style: TextStyle(
            color: context.palette.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        Gap.h24,
      ],
    );
  }
}
