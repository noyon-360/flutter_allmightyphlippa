import 'package:flutter/material.dart';
import 'package:flutx_core/flutx_core.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/assest_const.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'About App',
          style: TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Gap.h48,
            Center(
              child: Image.asset(
                AssetsConstants.images.logo,
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
            Gap.h24,
            const Text(
              'LABBY TV',
              style: TextStyle(
                color: AppColors.primaryWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColors.primaryGray, fontSize: 14),
            ),
            Gap.h48,
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'About Us',
                style: TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Gap.h16,
            const Text(
              'Welcome to LABBY TV, your ultimate destination for high-quality video streaming. We provide a vast collection of movies and series for your entertainment.',
              style: TextStyle(
                color: AppColors.primaryGray,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            Gap.h24,
            const Text(
              'Our mission is to deliver a seamless and enjoyable viewing experience to our users worldwide. Thank you for choosing LABBY TV.',
              style: TextStyle(
                color: AppColors.primaryGray,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            Gap.h48,
            const Text(
              '© 2026 LABBY TV. All rights reserved.',
              style: TextStyle(color: AppColors.primaryGray, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
