import 'package:awesome_emoji_picker/awesome_emoji_picker.dart';
import 'package:awesome_emoji_picker/generated/emoji_data.dart';
import 'package:flutter/material.dart';

/// Custom emoji picker
class CustomEmojiPicker extends StatefulWidget {
  const CustomEmojiPicker({required this.onEmojiSelected, super.key});

  final void Function(EmojiModel emoji) onEmojiSelected;

  @override
  State<CustomEmojiPicker> createState() => _CustomEmojiPickerState();
}

class _CustomEmojiPickerState extends State<CustomEmojiPicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EmojiRepository _repository = EmojiRepository();

  // Categorie emoji
  final List<String> _categories = [
    'Smileys & People',
    'Animals & Nature',
    'Food & Drink',
    'Activities',
    'Travel & Places',
    'Objects',
    'Symbols',
    'Flags',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length + 1, // +1 for Recents
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<EmojiModel> _getEmojisForCategory(String category) {
    return kEmojiList.where((emoji) => emoji.group == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    const recentsLabel = 'Recenti';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Category tabs
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: colorScheme.primaryContainer,
            unselectedLabelColor: colorScheme.surfaceContainerHighest,
            dividerColor: colorScheme.surfaceContainerHighest,
            indicatorColor: colorScheme.primaryContainer,
            tabs: [
              Tab(icon: Icon(_getIconForCategory(recentsLabel))),
              ..._categories.map(
                (cat) => Tab(icon: Icon(_getIconForCategory(cat))),
              ),
            ],
          ),
        ),

        // Emoji grid
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Recents
              ListenableBuilder(
                listenable: _repository,
                builder: (context, child) {
                  return _buildEmojiGrid(_repository.recentEmojis);
                },
              ),
              // Categories
              ..._categories.map(
                (cat) => _buildEmojiGrid(_getEmojisForCategory(cat)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiGrid(List<EmojiModel> emojis) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return GestureDetector(
          onTap: () {
            _repository.addToRecent(emoji);
            widget.onEmojiSelected(emoji);
          },
          child: Center(
            child: Text(emoji.char, style: const TextStyle(fontSize: 28)),
          ),
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    // Handle both English and localized versions
    if (category == 'Recents' || category == 'Recenti') {
      return Icons.access_time;
    }

    switch (category) {
      case 'Smileys & People':
        return Icons.emoji_emotions;
      case 'Animals & Nature':
        return Icons.pets;
      case 'Food & Drink':
        return Icons.restaurant;
      case 'Activities':
        return Icons.sports_soccer;
      case 'Travel & Places':
        return Icons.flight;
      case 'Objects':
        return Icons.lightbulb;
      case 'Symbols':
        return Icons.tag;
      case 'Flags':
        return Icons.flag;
      default:
        return Icons.emoji_emotions;
    }
  }
}
