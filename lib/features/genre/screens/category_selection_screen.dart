import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/constants/app_colors.dart';
import '../../genre/controllers/genre_controller.dart';
import 'package:flutter_almightyflippa/core/config/app_palette.dart';

class CategorySelectionScreen extends StatelessWidget {
  final String title;
  final String genreTag;
  final RxString selectedCategoryId;
  final Function(String) onCategorySelected;

  const CategorySelectionScreen({
    super.key,
    required this.title,
    required this.genreTag,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final genreCtrl = Get.find<GenreController>(tag: genreTag);

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: context.palette.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: genreCtrl.genres.length + 1,
          itemBuilder: (context, index) {
            final isAll = index == 0;
            final genre = isAll ? null : genreCtrl.genres[index - 1];
            final categoryId = isAll ? '' : genre!.categoryId;
            final categoryName = isAll ? 'All' : genre!.categoryName;

            return Obx(() {
              final isSelected = selectedCategoryId.value == categoryId;

              return TvFocusWrapper(
                onTap: () {
                  onCategorySelected(categoryId);
                  Get.back();
                },
                // Remote users start on the current category.
                autofocus: isSelected,
                borderRadius: 12,
                focusColor: context.palette.textPrimary,
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.red
                        : context.palette.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.red
                          : context.palette.textPrimary.withOpacity(0.1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: isSelected
                          ? context.palette.textPrimary
                          : context.palette.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}
