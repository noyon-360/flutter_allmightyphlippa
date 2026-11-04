import 'package:flutter/material.dart';
import 'package:flutter_almightyflippa/core/common/widgets/tv_focus_wrapper.dart';
import 'package:get/get.dart';
import '../../playlist/models/server_request_model.dart';
import '../screens/search_screen.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

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
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: context.palette.textPrimary),
              SizedBox(width: 8),
              Text(
                'Search',
                style: TextStyle(color: context.palette.hint, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
