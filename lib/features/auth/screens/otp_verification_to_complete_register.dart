// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../../../core/common/widgets/app_scaffold.dart';
// import '../../../../core/constants/app_colors.dart';
// import 'set_new_password_screen.dart';

// class OtpVerificationToCompleteRegister extends StatefulWidget {
//   const OtpVerificationToCompleteRegister({super.key, required this.email});
//   final String email;

//   @override
//   State<OtpVerificationToCompleteRegister> createState() =>
//       _OtpVerificationToCompleteRegisterState();
// }

// class _OtpVerificationToCompleteRegisterState
//     extends State<OtpVerificationToCompleteRegister> {
//   late TapGestureRecognizer _resendOtp;

//   final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
//   final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

//   @override
//   void initState() {
//     _resendOtp = TapGestureRecognizer()
//       ..onTap = () {
//         // static resend logic or empty
//       };

//     super.initState();
//   }

//   _submit() {
//     String otp = _controllers.map((c) => c.text).join();
//     Get.to(() => SetNewPasswordScreen(email: widget.email, otp: otp));
//   }

//   @override
//   void dispose() {
//     _resendOtp.dispose();
//     for (var controller in _controllers) {
//       controller.dispose();
//     }
//     for (var node in _focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }

//   String _maskEmail(String email) {
//     if (email.isEmpty || !email.contains('@')) return email;
//     final parts = email.split('@');
//     final local = parts[0];
//     final domain = parts[1];

//     if (local.length <= 2) return email;

//     final prefix = local.substring(0, 2);
//     return '$prefix*********@$domain';
//   }

//   @override
//     Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => FocusScope.of(context).unfocus(),
//       child: AppScaffold(
//         backgroundColor: AppColors.scaffoldBackground, // Dark background
//         body: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   SizedBox(height: 20),
//                   // Back button
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: IconButton(
//                       icon: Icon(Icons.arrow_back_ios, color: AppColors.white, size: 20),
//                       onPressed: () => Get.back(),
//                       padding: EdgeInsets.symmetric(horizontal: 24),
//                       alignment: Alignment.centerLeft,
//                     ),
//                   ),
//                   SizedBox(height: 40),

//                   Text(
//                     'Enter OTP',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.w700,
//                       color: AppColors.white,
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                   Text(
//                     'We have shared a code to your registered email address\n${_maskEmail(widget.email)}',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w400,
//                       color: AppColors.secondaryText,
//                       height: 1.5,
//                     ),
//                   ),
//                   SizedBox(height: 40),

//                   // Custom OTP Fields
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: List.generate(6, (index) {
//                         return Container(
//                           width: 48,
//                           height: 56,
//                           decoration: BoxDecoration(
//                             color: Colors.transparent,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: AppColors.inputBorder),
//                           ),
//                           child: TextField(
//                             controller: _controllers[index],
//                             focusNode: _focusNodes[index],
//                             keyboardType: TextInputType.number,
//                             textAlign: TextAlign.center,
//                             maxLength: 1,
//                             style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.white),
//                             cursorColor: AppColors.white,
//                             decoration: InputDecoration(
//                               counterText: '',
//                               border: InputBorder.none,
//                               contentPadding: EdgeInsets.zero,
//                             ),
//                             onChanged: (value) {
//                               if (value.length == 1 && index < 5) {
//                                 _focusNodes[index + 1].requestFocus();
//                               } else if (value.isEmpty && index > 0) {
//                                 _focusNodes[index - 1].requestFocus();
//                               }
//                               if (index == 5 && value.length == 1) {
//                                 FocusScope.of(context).unfocus();
//                               }
//                             },
//                           ),
//                         );
//                       }),
//                     ),
//                   ),

//                   SizedBox(height: 40),

//                   // Verify Button
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 52,
//                       child: ElevatedButton(
//                         onPressed: _submit,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primaryButtonColor,
//                           foregroundColor: AppColors.primaryButtonText,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                           elevation: 0,
//                         ),
//                         child: Text(
//                           'Verify',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   SizedBox(height: 24),

//                   // Resend Email Text
//                   Center(
//                     child: RichText(
//                       text: TextSpan(
//                         text: 'Didn\'t see your verification email? ',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w400,
//                           fontSize: 12,
//                           color: AppColors.secondaryText,
//                         ),
//                         children: [
//                           TextSpan(
//                             text: 'Resend email',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: AppColors.white,
//                             ),
//                             recognizer: _resendOtp,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),

//                   SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
