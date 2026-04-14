import 'package:cloudless/core/features/lockout/data/dtos/lockout_activity_stats_dto.dart';
import 'package:cloudless/core/features/lockout/domain/providers/get_lockout_activity_stats_provider.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/activity_bubble_cloud_painter.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Preset activity keys → emoji. Mirrors manual_lockout_dialog.dart.
const _kPresets = {
  'sport': '\u{1F3C3}',
  'music': '\u{1F3B5}',
  'friends': '\u{1F91D}',
  'relax': '\u{1F9D8}',
  'studying': '\u{1F4DA}',
};

/// Broad categories for classifying custom (typed) activities.
/// Each entry maps a category emoji to keywords that belong to it.
/// Checked via case-insensitive substring match against the activity text.
const _kCategoryKeywords = <String, List<String>>{
  // Sport & Fitness
  '\u{1F3C3}': [
    'run',
    'jog',
    'gym',
    'workout',
    'exercise',
    'swim',
    'hike',
    'cycling',
    'bike',
    'basketball',
    'football',
    'soccer',
    'tennis',
    'yoga',
    'pilates',
    'boxing',
    'martial',
    'climb',
    'surf',
    'ski',
    'skate',
    'rowing',
    'golf',
    'volleyball',
    'rugby',
    'cricket',
    'badminton',
    'squash',
    'crossfit',
    'weightlift',
    'stretch',
    'walk',
    'sprint',
    'trail',
    'paddle',
    'hockey',
    'fencing',
    'archery',
    'gymnastics',
    'fitnes',
    'cardio',
    'training',
  ],
  // Music & Arts
  '\u{1F3B5}': [
    'guitar',
    'piano',
    'drum',
    'singing',
    'song',
    'band',
    'concert',
    'violin',
    'cello',
    'flute',
    'ukulele',
    'bass',
    'synth',
    'dj',
    'painting',
    'drawing',
    'sketch',
    'sculpt',
    'pottery',
    'art',
    'photography',
    'photo',
    'film',
    'cinema',
    'theatre',
    'theater',
    'acting',
    'dance',
    'ballet',
    'calligraphy',
    'design',
    'craft',
    'knit',
    'crochet',
    'embroider',
    'sewing',
    'origami',
    'collage',
  ],
  // Social
  '\u{1F91D}': [
    'family',
    'party',
    'dinner',
    'date',
    'hangout',
    'hang out',
    'coffee',
    'lunch',
    'brunch',
    'bbq',
    'picnic',
    'visit',
    'reunion',
    'gathering',
    'karaoke',
    'club',
    'bar',
    'pub',
    'festival',
    'socializ',
    'catch up',
    'drinks',
    'birthday',
    'celebration',
    'wedding',
    'baby shower',
  ],
  // Wellness & Self-care
  '\u{1F9D8}': [
    'meditat',
    'mindful',
    'spa',
    'bath',
    'nap',
    'rest',
    'breath',
    'journal',
    'diary',
    'therapy',
    'massage',
    'sauna',
    'skincare',
    'self-care',
    'selfcare',
    'detox',
    'unplug',
    'unwind',
    'zen',
  ],
  // Learning & Reading
  '\u{1F4DA}': [
    'read',
    'book',
    'study',
    'course',
    'homework',
    'class',
    'tutorial',
    'learn',
    'research',
    'coding',
    'code',
    'program',
    'lecture',
    'seminar',
    'workshop',
    'exam',
    'essay',
    'thesis',
    'language',
    'podcast',
    'ted',
    'education',
    'practice',
    'review',
    'library',
    'writing',
    'write',
  ],
  // Cooking & Food
  '\u{1F373}': [
    'cook',
    'bak',
    'recipe',
    'meal',
    'chef',
    'kitchen',
    'grill',
    'roast',
    'prep',
    'food',
    'brew',
    'ferment',
    'preserv',
    'kombucha',
  ],
  // Nature & Outdoors
  '\u{1F33F}': [
    'garden',
    'nature',
    'park',
    'camp',
    'fish',
    'beach',
    'forest',
    'mountain',
    'bird',
    'plant',
    'flower',
    'tree',
    'farm',
    'outdoor',
    'stargazing',
    'sunset',
    'sunrise',
    'lake',
    'river',
    'ocean',
  ],
  // Gaming & Entertainment
  '\u{1F3AE}': [
    'game',
    'gaming',
    'video game',
    'board game',
    'chess',
    'puzzle',
    'movie',
    'film',
    'tv',
    'netflix',
    'stream',
    'anime',
    'manga',
    'comic',
    'lego',
    'tabletop',
    'd&d',
    'roleplay',
    'console',
  ],
  // Pets & Animals
  '\u{1F43E}': [
    'dog',
    'cat',
    'pet',
    'puppy',
    'kitten',
    'horse',
    'riding',
    'aquarium',
    'terrarium',
    'vet',
    'groom',
    'shelter',
    'animal',
  ],
  // DIY & Projects
  '\u{1F6E0}': [
    'diy',
    'build',
    'woodwork',
    'renovati',
    'fix',
    'repair',
    'assemble',
    'workshop',
    'weld',
    'carpent',
    '3d print',
    'electron',
    'robot',
    'tinker',
    'restore',
    'upholster',
    'handyman',
  ],
  // Volunteering & Community
  '\u{1F49A}': [
    'volunteer',
    'charity',
    'donat',
    'communit',
    'mentor',
    'coach',
    'teach',
    'tutor',
    'cleanup',
    'fundrais',
    'ngo',
    'nonprofit',
  ],
};

/// Default emoji for activities that don't match any category.
const _kDefaultEmoji = '\u{2B50}'; // ⭐

/// Returns the best-matching category emoji for [activityText], or
/// [_kDefaultEmoji] if no keyword matches.
///
/// Uses word-boundary matching: each word in the activity is checked for
/// whether it *starts with* a keyword. This catches inflections
/// ("running" → "run", "swimming" → "swim") while avoiding false
/// substring hits ("party" no longer matches "art").
String _classifyActivity(String activityText) {
  final words = activityText.toLowerCase().split(RegExp(r'[\s\-/]+'));
  for (final entry in _kCategoryKeywords.entries) {
    for (final keyword in entry.value) {
      // Multi-word keywords (e.g. "board game") — check the full text.
      if (keyword.contains(' ')) {
        if (activityText.toLowerCase().contains(keyword)) {
          return entry.key;
        }
        continue;
      }
      // Single-word keywords — match if any word starts with the keyword.
      for (final word in words) {
        if (word.startsWith(keyword)) {
          return entry.key;
        }
      }
    }
  }
  return _kDefaultEmoji;
}

class ActivityBubbleCloud extends HookConsumerWidget {
  const ActivityBubbleCloud({
    required this.userId,
    required this.scale,
    super.key,
  });

  final String userId;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = scale;
    final statsAsync = ref.watch(
      getLockoutActivityStatsProvider(userId: userId),
    );

    final activities = <LockoutActivityStatsDto>[];
    String? errorMsg;
    final isLoading = statsAsync.isLoading;
    statsAsync.whenData((result) {
      result.fold(
        (stats) => activities.addAll(stats),
        (e) => errorMsg = e.toString(),
      );
    });
    statsAsync.whenOrNull(error: (e, _) => errorMsg = e.toString());

    // Build reverse lookup: translated label → preset key
    final labelToKey = <String, String>{};
    for (final key in _kPresets.keys) {
      final label = translator.translate(
        'pages.manual_lockout.dialog.activities.$key',
      );
      labelToKey[label] = key;
    }

    // Convert DTOs to bubbles with emoji resolution:
    // 1. Check preset match  2. Keyword classify  3. Default ⭐
    final bubbles = activities.map((stat) {
      final presetKey = labelToKey[stat.actionText];
      final emoji = presetKey != null
          ? _kPresets[presetKey]!
          : _classifyActivity(stat.actionText);
      return ActivityBubble(
        label: stat.actionText,
        emoji: emoji,
        totalMinutes: stat.totalMinutes,
      );
    }).toList();

    if (isLoading) {
      return Center(
        child: Text(
          'Loading activities…',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 14 * s,
            color: MainColors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    if (errorMsg != null) {
      return Center(
        child: Text(
          'Error: $errorMsg',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 12 * s,
            color: MainColors.white.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (bubbles.isEmpty) {
      return Center(
        child: Text(
          'No activity data yet',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: FontWeight.w500,
            fontSize: 14 * s,
            color: MainColors.white.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: AspectRatio(
        aspectRatio: 1.2,
        child: CustomPaint(
          size: Size.infinite,
          painter: ActivityBubbleCloudPainter(bubbles: bubbles),
        ),
      ),
    );
  }
}
