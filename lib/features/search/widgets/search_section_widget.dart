import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_focus_wrapper.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../playlist/models/server_request_model.dart';
import '../screens/search_screen.dart';

class SearchSectionWidget extends StatelessWidget {
  final ServerType type;
  const SearchSectionWidget({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TvFocusWrapper(
        onTap: () {
          Get.to(() => SearchScreen(type: type));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.containerBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.iconColor),
              SizedBox(width: 8),
              Text(
                'Search',
                style: TextStyle(color: AppColors.hintText, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
