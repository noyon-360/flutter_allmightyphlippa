import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Gap.h8,
            const Text(
              'Last updated: January 27, 2026',
              style: TextStyle(color: AppColors.primaryGray, fontSize: 12),
            ),
            Gap.h24,
            _buildSection(
              '1. Information Collection',
              'We collect information that you provide directly to us when you create an account, use our services, or communicate with us.',
            ),
            _buildSection(
              '2. How We Use Information',
              'We use the information we collect to provide, maintain, and improve our services, develop new ones, and protect LABBY TV and our users.',
            ),
            _buildSection(
              '3. Information Sharing',
              'We do not share your personal information with companies, organizations, or individuals outside of LABBY TV except in the following cases: with your consent, for external processing, or for legal reasons.',
            ),
            _buildSection(
              '4. Data Security',
              'We work hard to protect LABBY TV and our users from unauthorized access to or unauthorized alteration, disclosure, or destruction of information we hold.',
            ),
            _buildSection(
              '5. Your Choices',
              'You have choices regarding the information we collect and how it is used. You can access and update your information through your account settings.',
            ),
            Gap.h24,
            const Text(
              'If you have any questions about this Privacy Policy, please contact us.',
              style: TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            Gap.h32,
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Gap.h8,
        Text(
          content,
          style: const TextStyle(
            color: AppColors.primaryGray,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        Gap.h24,
      ],
    );
  }
}
