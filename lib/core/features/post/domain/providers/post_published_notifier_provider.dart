import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_published_notifier_provider.g.dart';

@Riverpod(keepAlive: true)
class PostPublishedNotifier extends _$PostPublishedNotifier {
  @override
  DateTime? build() => null;

  void clearPublishedFlag() {
    state = null;
  }
}
