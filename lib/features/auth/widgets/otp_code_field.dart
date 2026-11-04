import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class PinCode extends StatelessWidget {
  const PinCode({super.key, required this.otpController});

  final PinInputController otpController;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    return MaterialPinField(
      pinController: otpController,
      length: 4,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      keyboardType: TextInputType.number,
      autoFocus: false,
      obscureText: true,
      theme: MaterialPinTheme(
        textStyle: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        shape: MaterialPinShape.outlined,
        borderRadius: BorderRadius.circular(6),
        cellSize: const Size(54, 56),
        spacing: 8, // Explicit spacing

        borderColor: Colors.transparent,
        focusedBorderColor: Colors.red,
        filledBorderColor: Colors.transparent,

        fillColor: dark ? const Color(0xFF2E2E2E) : context.palette.surface,
        focusedFillColor: dark
            ? const Color(0xFF3D3D3D)
            : context.palette.surfaceHigh,
        filledFillColor: dark ? const Color(0xFF2E2E2E) : context.palette.surface,

        cursorColor: Colors.black,
        entryAnimation: MaterialPinAnimation.fade,
      ),
    );
  }
}
