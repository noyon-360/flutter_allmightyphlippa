import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/common/widgets/pin_pad_dialog.dart';
import '../../../core/common/widgets/tv_focus_wrapper.dart';
import '../../../core/config/app_palette.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/parental_lock_service.dart';
import '../../genre/controllers/genre_controller.dart';
import '../../playlist/models/server_request_model.dart';

/// Profile → Parental lock: set / change / remove the PIN, turn biometrics
/// on or off, and pick which categories are locked.
class ParentalLockScreen extends StatefulWidget {
  const ParentalLockScreen({super.key});

  @override
  State<ParentalLockScreen> createState() => _ParentalLockScreenState();
}

class _ParentalLockScreenState extends State<ParentalLockScreen> {
  final lock = ParentalLockService.to;
  ParentalSection _section = ParentalSection.live;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _serverTypes = {
    ParentalSection.live: ServerType.live,
    ParentalSection.movies: ServerType.movies,
    ParentalSection.series: ServerType.series,
  };

  /// The tab controllers register these, but the user may open this screen
  /// before ever visiting Movies or Series.
  GenreController _genresFor(ParentalSection s) {
    if (Get.isRegistered<GenreController>(tag: s.genreTag)) {
      final ctrl = Get.find<GenreController>(tag: s.genreTag);
      if (ctrl.genres.isEmpty && !ctrl.isLoading.value) {
        ctrl.getGenres(type: _serverTypes[s]!);
      }
      return ctrl;
    }
    return Get.put(GenreController(), tag: s.genreTag)
      ..getGenres(type: _serverTypes[s]!);
  }

  Future<String?> _askNewPin() async {
    final first = await showPinPadDialog(
      title: 'Choose a 4-digit PIN',
      validate: (_) => null,
    );
    if (first == null) return null;
    return showPinPadDialog(
      title: 'Enter the PIN again',
      validate: (pin) => pin == first ? null : "PINs don't match, try again.",
    );
  }

  Future<void> _setOrChangePin() async {
    final pin = await _askNewPin();
    if (pin == null) return;
    await lock.setPin(pin);
    Get.snackbar('Parental lock', 'PIN saved', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _removePin() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: context.palette.surface,
        title: Text(
          'Turn off parental lock?',
          style: TextStyle(color: context.palette.textPrimary),
        ),
        content: Text(
          'Locked categories will open without a PIN. Your choices are kept '
          'if you set a PIN again.',
          style: TextStyle(color: context.palette.textSecondary),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Turn off', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await lock.removePin();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        title: const Text('Parental lock'),
      ),
      body: Obx(() {
        if (!lock.hasPin.value) return _buildIntro(p);
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            _actionRow(p, Icons.pin_outlined, 'Change PIN', _setOrChangePin,
                autofocus: true),
            if (lock.biometricsAvailable.value)
              _actionRow(
                p,
                Icons.fingerprint,
                'Unlock with Face ID / fingerprint',
                () => lock.setBiometricsEnabled(!lock.biometricsEnabled.value),
                trailing: Switch(
                  value: lock.biometricsEnabled.value,
                  activeThumbColor: AppColors.red,
                  onChanged: (v) => lock.setBiometricsEnabled(v),
                ),
              ),
            _actionRow(p, Icons.lock_open, 'Turn off parental lock', _removePin,
                color: AppColors.red),
            const SizedBox(height: 20),
            Text(
              'Locked categories',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Locked categories need the PIN to open and are hidden from '
              '"All", Home and Search.',
              style: TextStyle(color: p.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildSectionTabs(p),
            const SizedBox(height: 12),
            _buildSearchField(p),
            const SizedBox(height: 8),
            _buildCategoryList(p),
          ],
        );
      }),
    );
  }

  Widget _buildIntro(AppPalette p) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: p.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Set a PIN to lock categories you don\'t want children to watch.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 24),
            TvFocusWrapper(
              autofocus: true,
              borderRadius: 25,
              focusColor: p.textPrimary,
              onTap: _setOrChangePin,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Text(
                  'Set PIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionRow(
    AppPalette p,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Widget? trailing,
    Color? color,
    bool autofocus = false,
  }) {
    return TvFocusWrapper(
      autofocus: autofocus,
      focusColor: p.textPrimary,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? p.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: color ?? p.textPrimary, fontSize: 16),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTabs(AppPalette p) {
    return Row(
      children: [
        for (final s in ParentalSection.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TvFocusWrapper(
              borderRadius: 20,
              focusColor: p.textPrimary,
              onTap: () => setState(() => _section = s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: s == _section ? AppColors.red : p.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  s.label,
                  style: TextStyle(
                    color: s == _section ? Colors.white : p.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField(AppPalette p) {
    return TextField(
      controller: _searchCtrl,
      style: TextStyle(color: p.textPrimary),
      textInputAction: TextInputAction.search,
      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search categories (e.g. adult, xxx, horror)',
        hintStyle: TextStyle(color: p.hint),
        prefixIcon: Icon(Icons.search, color: p.textSecondary),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: p.textSecondary),
                onPressed: () => setState(() {
                  _searchCtrl.clear();
                  _query = '';
                }),
              ),
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryList(AppPalette p) {
    final section = _section;
    final genres = _genresFor(section);
    return Obx(() {
      if (genres.isLoading.value && genres.genres.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: AppColors.red)),
        );
      }
      if (genres.genres.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No categories found for this playlist.',
            style: TextStyle(color: p.textSecondary),
          ),
        );
      }
      final matches = _query.isEmpty
          ? genres.genres
          : genres.genres
                .where((g) => g.categoryName.toLowerCase().contains(_query))
                .toList();
      if (matches.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No categories match "${_searchCtrl.text.trim()}".',
            style: TextStyle(color: p.textSecondary),
          ),
        );
      }
      return Column(
        children: [
          for (final g in matches)
            Obx(() {
              final locked = lock.isCategoryLocked(section, g.categoryId);
              return TvFocusWrapper(
                focusColor: p.textPrimary,
                onTap: () =>
                    lock.setCategoryLocked(section, g.categoryId, !locked),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          g.categoryName,
                          style: TextStyle(color: p.textPrimary, fontSize: 15),
                        ),
                      ),
                      Icon(
                        locked ? Icons.lock : Icons.lock_open,
                        color: locked ? AppColors.red : p.textSecondary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      );
    });
  }
}
