import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../genre/controllers/genre_controller.dart';

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
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlack,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryWhite),
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

              return GestureDetector(
                onTap: () {
                  onCategorySelected(categoryId);
                  Get.back();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.red : AppColors.containerBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.red
                          : AppColors.primaryWhite.withOpacity(0.1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryWhite
                          : AppColors.primaryGray,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
