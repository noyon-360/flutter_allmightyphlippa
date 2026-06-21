import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_colors.dart';
import '../../services/airplay_service.dart';
import '../../services/cast_service.dart';
import 'tv_focus_wrapper.dart';

class CastAirPlayButtons extends StatelessWidget {
  final String? Function() currentUrl;
  final String Function()? title;
  final String? Function()? imageUrl;
  final EdgeInsetsGeometry iconPadding;

  const CastAirPlayButtons({
    super.key,
    required this.currentUrl,
    this.title,
    this.imageUrl,
    this.iconPadding = const EdgeInsets.all(8.0),
  });

  CastService get _cast => Get.find<CastService>();
  AirPlayService get _airplay => AirPlayService.instance;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => TvFocusWrapper(
            onTap: () => _onCastTapped(context),
            child: Padding(
              padding: iconPadding,
              child: Icon(
                _cast.isCasting.value ? Icons.cast_connected : Icons.cast,
                color: _cast.isCasting.value ? AppColors.red : Colors.white,
              ),
            ),
          ),
        ),
        if (Platform.isIOS)
          TvFocusWrapper(
            onTap: () => _airplay.showAirPlayPicker(),
            child: Padding(
              padding: iconPadding,
              child: const Icon(Icons.airplay, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Future<void> _onCastTapped(BuildContext context) async {
    if (_cast.isCasting.value) {
      await _cast.stopCasting();
      return;
    }
    await _showDevicePicker(context);
  }

  Future<void> _showDevicePicker(BuildContext context) async {
    _cast.startScan();

    if (!context.mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cast',
      pageBuilder: (ctx, _, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(ctx).size.width * 0.8,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.6,
              ),
              decoration: BoxDecoration(
                color: AppColors.containerBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D3D3D),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cast, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Cast to device",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TvFocusWrapper(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Obx(() {
                      if (_cast.isScanning.value &&
                          _cast.availableDevices.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  color: AppColors.red,
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Searching for devices...",
                                style: TextStyle(color: AppColors.primaryGray),
                              ),
                            ],
                          ),
                        );
                      }

                      if (_cast.availableDevices.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cast,
                                color: AppColors.primaryGray,
                                size: 36,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "No Chromecast devices found nearby. "
                                "Make sure your device is on the same WiFi network.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.primaryGray,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TvFocusWrapper(
                                onTap: () => _cast.startScan(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Text(
                                    "Retry",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _cast.availableDevices.length,
                        itemBuilder: (context, index) {
                          final device = _cast.availableDevices[index];
                          return TvFocusWrapper(
                            onTap: () => _connectAndCast(ctx, device),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tv,
                                      color: Colors.white, size: 22),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      device.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Obx(() {
                                    if (_cast.isConnecting.value &&
                                        _cast.connectedDevice.value == device) {
                                      return const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: AppColors.red,
                                          strokeWidth: 2,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _connectAndCast(BuildContext ctx, CastDevice device) async {
    final url = currentUrl();
    if (url == null || url.isEmpty) {
      Get.snackbar('Cast', 'No video is currently playing.');
      return;
    }

    try {
      await _cast.connectToDevice(
        device,
        url: url,
        title: title?.call() ?? '',
        imageUrl: imageUrl?.call(),
      );
      if (ctx.mounted) Navigator.pop(ctx);
    } catch (_) {
      if (ctx.mounted) Navigator.pop(ctx);
      Get.snackbar('Cast', 'Failed to connect to ${device.name}.');
    }
  }
}
