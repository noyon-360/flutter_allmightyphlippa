import 'package:flutter/material.dart';
import '/core/common/widgets/app_scaffold.dart';
import '/core/common/widgets/button_widgets.dart';
import '/core/constants/assest_const.dart' hide Icons;
import 'package:flutx_core/flutx_core.dart';
import 'package:get/get.dart';

import '/core/common/widgets/app_logo.dart';
import '/core/constants/app_colors.dart';
import '/core/extensions/input_decoration_extensions.dart';
import '../controllers/playlist_controller.dart';

class AddPlaylistScreen extends StatelessWidget {
  final bool isEdit;
  const AddPlaylistScreen({super.key, this.isEdit = false});

  @override
  Widget build(BuildContext context) {
    final playlistCtrl = Get.put(PlaylistController());

    return AppScaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600, minWidth: 300),
                child: Form(
                  key: playlistCtrl.playlistFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Gap(h: 60),
                      Center(
                        child: AppLogo(
                          height: 134,
                          width: 134,
                          borderRadius: 22.69,
                          images: AssetsConstants.images.logo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Gap.h40,
                      Text(
                        "Enter Your Playlist Details",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primaryWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Gap.h12,
                      Obx(
                        () => playlistCtrl.playlistErrorMessage.value.isNotEmpty
                            ? Center(
                                child: Text(
                                  playlistCtrl.playlistErrorMessage.value,
                                  style: TextStyle(color: AppColors.red),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Gap.h12,
                      TextFormField(
                        controller: playlistCtrl.nameController,
                        focusNode: playlistCtrl.nameFocus,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryWhite,
                        ),
                        decoration: context.primaryInputDecoration.copyWith(
                          hintText: "Name",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Name is required";
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(playlistCtrl.usernameFocus),
                      ),
                      Gap.h16,
                      TextFormField(
                        controller: playlistCtrl.usernameController,
                        focusNode: playlistCtrl.usernameFocus,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryWhite,
                        ),
                        decoration: context.primaryInputDecoration.copyWith(
                          hintText: "Username",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Username is required";
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(playlistCtrl.passwordFocus),
                      ),
                      Gap.h16,
                      TextFormField(
                        controller: playlistCtrl.passwordController,
                        focusNode: playlistCtrl.passwordFocus,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryWhite,
                        ),
                        decoration: context.primaryInputDecoration.copyWith(
                          hintText: "Password",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required";
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => FocusScope.of(
                          context,
                        ).requestFocus(playlistCtrl.urlFocus),
                      ),
                      Gap.h16,
                      TextFormField(
                        controller: playlistCtrl.urlController,
                        focusNode: playlistCtrl.urlFocus,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryWhite,
                        ),
                        decoration: context.primaryInputDecoration.copyWith(
                          hintText: "URL Link",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "URL is required";
                          }
                          // Simple URL validation
                          if (!Uri.parse(value).isAbsolute) {
                            return "Enter a valid URL";
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => playlistCtrl.addPlaylist(),
                      ),
                      const Gap(h: 20),
                      PrimaryButton(
                        text: "Add Playlist",
                        onApiPressed: () async {
                          if (isEdit) {
                            await playlistCtrl.addPlaylistBackList();
                          } else {
                            await playlistCtrl.addPlaylist();
                          }
                        },
                      ),
                      const Gap(h: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
