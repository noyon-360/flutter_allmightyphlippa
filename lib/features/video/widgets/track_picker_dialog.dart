import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';

import '../../../core/constants/app_colors.dart';

/// Human-readable names for the tracks a stream reports. Streams label them
/// inconsistently (language code, free-text title, or nothing), so fall back
/// through title -> language -> a numbered placeholder.
String audioTrackLabel(AudioTrack track) {
  if (track == AudioTrack.auto()) return 'Auto';
  if (track == AudioTrack.no()) return 'None';
  return _describe(track.language, track.title, track.id, 'Audio');
}

String subtitleTrackLabel(SubtitleTrack track) {
  if (track == SubtitleTrack.no()) return 'Off';
  if (track == SubtitleTrack.auto()) return 'Auto';
  return _describe(track.language, track.title, track.id, 'Captions');
}

String _describe(String? language, String? title, String id, String noun) {
  final name = _languageName(language);
  final hasTitle = title != null && title.isNotEmpty;
  // Show both when they add information ("Closed Captions (English)").
  if (name != null && hasTitle && title.toLowerCase() != name.toLowerCase()) {
    return '$title ($name)';
  }
  if (name != null) return name;
  if (hasTitle) return title;
  return '$noun $id';
}

/// Common ISO 639 codes (2- and 3-letter) as they appear on IPTV streams;
/// anything else falls back to the code itself, upper-cased.
String? _languageName(String? code) {
  if (code == null || code.isEmpty) return null;
  const names = {
    'en': 'English',
    'eng': 'English',
    'es': 'Spanish',
    'spa': 'Spanish',
    'fr': 'French',
    'fra': 'French',
    'fre': 'French',
    'de': 'German',
    'deu': 'German',
    'ger': 'German',
    'it': 'Italian',
    'ita': 'Italian',
    'pt': 'Portuguese',
    'por': 'Portuguese',
    'ru': 'Russian',
    'rus': 'Russian',
    'ar': 'Arabic',
    'ara': 'Arabic',
    'hi': 'Hindi',
    'hin': 'Hindi',
    'bn': 'Bengali',
    'ben': 'Bengali',
    'ja': 'Japanese',
    'jpn': 'Japanese',
    'ko': 'Korean',
    'kor': 'Korean',
    'zh': 'Chinese',
    'zho': 'Chinese',
    'chi': 'Chinese',
    'tr': 'Turkish',
    'tur': 'Turkish',
    'nl': 'Dutch',
    'nld': 'Dutch',
    'dut': 'Dutch',
    'pl': 'Polish',
    'pol': 'Polish',
    'sv': 'Swedish',
    'swe': 'Swedish',
    'el': 'Greek',
    'ell': 'Greek',
    'gre': 'Greek',
    'he': 'Hebrew',
    'heb': 'Hebrew',
    'th': 'Thai',
    'tha': 'Thai',
    'vi': 'Vietnamese',
    'vie': 'Vietnamese',
    'fa': 'Persian',
    'fas': 'Persian',
    'per': 'Persian',
    'ur': 'Urdu',
    'urd': 'Urdu',
    'und': 'Unknown',
  };
  return names[code.toLowerCase()] ?? code.toUpperCase();
}

/// Modal list for choosing a track (audio or subtitle), with the current one
/// marked. [tracks] and [isSelected] are read inside an `Obx`, so the list
/// stays live if the stream reports more tracks after the dialog opens.
Future<void> showTrackPickerDialog<T>({
  required BuildContext context,
  required String title,
  required String emptyText,
  required RxList<T> tracks,
  required bool Function(T track) isSelected,
  required String Function(T track) labelFor,
  required void Function(T track) onSelect,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    pageBuilder: (dialogContext, _, _) {
      return SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(dialogContext).size.width * 0.7,
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
              ),
              decoration: BoxDecoration(
                color: AppColors.containerBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Obx(() {
                      if (tracks.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            emptyText,
                            style: const TextStyle(
                              color: AppColors.primaryGray,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: tracks.length,
                        itemBuilder: (_, index) {
                          final track = tracks[index];
                          final selected = isSelected(track);
                          return InkWell(
                            onTap: () {
                              onSelect(track);
                              Navigator.pop(dialogContext);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      labelFor(track),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                    child: selected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: AppColors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
