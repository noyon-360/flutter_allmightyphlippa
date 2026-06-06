import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import '../../../core/constants/app_colors.dart';

class TermsConditionScreen extends StatelessWidget {
  const TermsConditionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Terms & Conditions',
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
              'Terms & Conditions',
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
              '1. Acceptance of Terms',
              'By accessing or using LABBY TV, you agree to be bound by these Terms and Conditions and all applicable laws and regulations.',
            ),
            _buildSection(
              '2. Use License',
              'Permission is granted to temporarily download one copy of the materials (information or software) on LABBY TV for personal, non-commercial transitory viewing only.',
            ),
            _buildSection(
              '3. Disclaimer',
              'The materials on LABBY TV are provided on an "as is" basis. LABBY TV makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties.',
            ),
            _buildSection(
              '4. Limitations',
              'In no event shall LABBY TV or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials.',
            ),
            _buildSection(
              '5. Governing Law',
              'These terms and conditions are governed by and construed in accordance with the laws and you irrevocably submit to the exclusive jurisdiction of the courts in that State or location.',
            ),
            Gap.h24,
            const Text(
              'If you do not agree with any of these terms, you are prohibited from using or accessing this site.',
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
