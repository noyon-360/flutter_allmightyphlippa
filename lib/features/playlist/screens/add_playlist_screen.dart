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
import '../models/playlist_model.dart';

class AddPlaylistScreen extends StatefulWidget {
  final bool isEdit;

  /// When set, the screen edits this playlist in place (name, URL, username,
  /// password) instead of adding a new one.
  final PlaylistModel? editing;

  const AddPlaylistScreen({super.key, this.isEdit = false, this.editing});

  @override
  State<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends State<AddPlaylistScreen> {
  final PlaylistController playlistCtrl = Get.put(PlaylistController());

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    // The form controllers are shared with the "add" flow, so start from a
    // known state: prefilled when editing, empty otherwise. Deferred a frame
    // because this changes observable state that widgets above are listening
    // to, which isn't allowed mid-build. (No cleanup on dispose: the next
    // screen to open resets the form itself, and the controller may already be
    // torn down by then.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isEditing) {
        playlistCtrl.startEditing(widget.editing!);
      } else {
        playlistCtrl.clearForm();
      }
    });
  }

  Future<void> _submit() {
    if (_isEditing) return playlistCtrl.updatePlaylist();
    return widget.isEdit
        ? playlistCtrl.addPlaylistBackList()
        : playlistCtrl.addPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

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
                        _isEditing
                            ? "Edit Your Playlist"
                            : "Enter Your Playlist Details",
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
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  playlistCtrl.playlistErrorMessage.value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                        // Credentials and URLs must be sent exactly as typed — iOS
                        // autocorrect otherwise rewrites e.g. "newpass" as "new pass".
                        autocorrect: false,
                        enableSuggestions: false,
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
                        // Credentials and URLs must be sent exactly as typed — iOS
                        // autocorrect otherwise rewrites e.g. "newpass" as "new pass".
                        autocorrect: false,
                        enableSuggestions: false,
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
                        // Credentials and URLs must be sent exactly as typed — iOS
                        // autocorrect otherwise rewrites e.g. "newpass" as "new pass".
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: TextInputType.url,
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
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const Gap(h: 20),
                      PrimaryButton(
                        text: _isEditing ? "Save Changes" : "Add Playlist",
                        onApiPressed: () async {
                          if (_isEditing) {
                            await playlistCtrl.updatePlaylist();
                          } else if (isEdit) {
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
