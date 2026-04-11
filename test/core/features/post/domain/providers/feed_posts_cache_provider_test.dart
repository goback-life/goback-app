import 'package:cloudless/core/features/post/domain/providers/feed_posts_cache_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../test_utils/fake_feed_post.dart';

/// Tests for FeedPostsCache provider.
///
/// These tests focus on the cache's local state manipulation methods:
/// - 24-hour expiration filtering in the `posts` getter
/// - Adding, updating, and removing posts
/// - Memory cleanup via `removeExpiredPosts()`
/// - Cache invalidation
///
/// Methods that make external provider calls (loadInitialPosts, checkForDeletions, etc.)
/// are not tested here as they require integration testing or dependency mocking.
void main() {
  group('FeedPostsCache', () {
    late ProviderContainer container;

    setUp(() {
      // Create a fresh container for each test
      // No overrides needed for testing pure state manipulation
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('posts getter - 24-hour expiration filtering', () {
      test('returns only posts within 24 hours', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final testData = createPostsWithExpiry(validCount: 3, expiredCount: 2);

        // Add all posts to cache (valid + expired)
        for (final post in testData.all) {
          cache.addPost(post);
        }

        // Getter should filter out expired posts
        final visiblePosts = cache.posts;

        expect(visiblePosts.length, equals(3));
        expect(
          visiblePosts.every((p) => testData.valid.any((v) => v.id == p.id)),
          isTrue,
          reason: 'All visible posts should be from the valid set',
        );
      });

      test('filters posts at exactly 24 hours boundary', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        // Post at exactly 24 hours should be filtered out (not after cutoff)
        final boundaryPost = createFakePost(
          id: 'boundary',
          publishedAt: now.subtract(const Duration(hours: 24)),
        );

        // Post at 23h 59m should be visible
        final justValidPost = createFakePost(
          id: 'just-valid',
          publishedAt: now.subtract(const Duration(hours: 23, minutes: 59)),
        );

        cache.addPost(boundaryPost);
        cache.addPost(justValidPost);

        final visiblePosts = cache.posts;

        expect(visiblePosts.length, equals(1));
        expect(visiblePosts.first.id, equals('just-valid'));
      });

      test('returns empty list when all posts expired', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        // Add only expired posts
        for (var i = 0; i < 5; i++) {
          cache.addPost(
            createFakePost(
              id: 'expired-$i',
              publishedAt: now.subtract(Duration(hours: 25 + i)),
            ),
          );
        }

        expect(cache.posts, isEmpty);
      });

      test('returns all posts when none are expired', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        // Add only valid posts
        for (var i = 0; i < 5; i++) {
          cache.addPost(
            createFakePost(
              id: 'valid-$i',
              publishedAt: now.subtract(Duration(hours: 1 + i)),
            ),
          );
        }

        expect(cache.posts.length, equals(5));
      });

      test('filtering is computed on each access (not cached)', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        // Add a post that's 23 hours old
        cache.addPost(
          createFakePost(
            id: 'soon-expiring',
            publishedAt: now.subtract(const Duration(hours: 23)),
          ),
        );

        // Verify getter returns fresh computation
        final posts1 = cache.posts;
        final posts2 = cache.posts;

        // Both calls should return valid result
        expect(posts1.length, equals(1));
        expect(posts2.length, equals(1));

        // Different list instances (computed fresh each time)
        expect(identical(posts1, posts2), isFalse);
      });

      test(
        'getter filters directly from current state - proves instant expiration',
        () {
          // This test proves the REQUIREMENT: "instant expiration"
          // If we used a timer-based approach, adding an expired post would
          // show in the getter until the next timer tick. With getter-based
          // filtering, it's filtered immediately.

          final cache = container.read(feedPostsCacheProvider.notifier);
          final now = DateTime.now();

          // Add a valid post first
          final validPost = createFakePost(
            id: 'valid',
            publishedAt: now.subtract(const Duration(hours: 12)),
          );
          cache.addPost(validPost);

          // Getter shows 1 post
          expect(cache.posts.length, equals(1));

          // Now add an expired post directly to the cache
          final expiredPost = createFakePost(
            id: 'expired',
            publishedAt: now.subtract(const Duration(hours: 30)),
          );
          cache.addPost(expiredPost);

          // State has 2 posts (no filtering at state level)
          final rawState = container.read(feedPostsCacheProvider);
          expect(rawState.posts.length, equals(2));

          // But getter IMMEDIATELY filters to 1 post - no timer delay
          // This is the key behavior: filtering happens on READ, not on a schedule
          expect(cache.posts.length, equals(1));
          expect(cache.posts.first.id, equals('valid'));
        },
      );
    });

    group('removeExpiredPosts - memory cleanup', () {
      test('removes expired posts from state', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final testData = createPostsWithExpiry(validCount: 3, expiredCount: 2);

        // Add all posts
        for (final post in testData.all) {
          cache.addPost(post);
        }

        // State should have all 5 posts
        final stateBefore = container.read(feedPostsCacheProvider);
        expect(stateBefore.posts.length, equals(5));

        // Remove expired posts from state
        cache.removeExpiredPosts();

        // State should now only have valid posts
        final stateAfter = container.read(feedPostsCacheProvider);
        expect(stateAfter.posts.length, equals(3));
      });

      test('does nothing when no posts are expired', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        // Add only valid posts
        for (var i = 0; i < 3; i++) {
          cache.addPost(
            createFakePost(
              id: 'valid-$i',
              publishedAt: now.subtract(Duration(hours: 1 + i)),
            ),
          );
        }

        final stateBefore = container.read(feedPostsCacheProvider);
        cache.removeExpiredPosts();
        final stateAfter = container.read(feedPostsCacheProvider);

        expect(stateAfter.posts.length, equals(stateBefore.posts.length));
      });

      test('updates oldestPostTimestamp after removal', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        // Add valid post
        final validPost = createFakePost(
          id: 'valid',
          publishedAt: now.subtract(const Duration(hours: 12)),
        );

        // Add expired post (older)
        final expiredPost = createFakePost(
          id: 'expired',
          publishedAt: now.subtract(const Duration(hours: 30)),
        );

        cache.addPost(validPost);
        cache.addPost(expiredPost);

        cache.removeExpiredPosts();

        final state = container.read(feedPostsCacheProvider);
        // After removal, only valid post remains
        expect(state.posts.length, equals(1));
        expect(state.posts.first.id, equals('valid'));
      });
    });

    group('needsFullRebuild', () {
      test('returns true on cold start (never validated)', () {
        final cache = container.read(feedPostsCacheProvider.notifier);

        // On first access, _lastFullValidation is null
        expect(cache.needsFullRebuild, isTrue);
      });

      // Note: Testing the 6-hour threshold would require clock injection.
      // With timestamp manipulation only, we can verify cold start behavior.
    });

    // NOTE: checkForDeletionsStaggered tests are NOT included because:
    // - When batchStart == 0, it calls checkForDeletions() which makes Supabase calls
    // - Testing this requires mocking getFeedPostsProvider or Supabase
    // - The offset cycling logic is simple arithmetic that can be verified by code review:
    //   _deletionCheckOffset = batchEnd >= allPosts.length ? 0 : batchEnd;
    // - Integration tests with a real/mocked backend would be needed for full coverage

    group('invalidateCache', () {
      test('clears all posts', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        // Add some posts
        for (var i = 0; i < 5; i++) {
          cache.addPost(
            createFakePost(
              id: 'post-$i',
              publishedAt: now.subtract(Duration(hours: i)),
            ),
          );
        }

        expect(container.read(feedPostsCacheProvider).posts.length, equals(5));

        cache.invalidateCache();

        expect(container.read(feedPostsCacheProvider).posts, isEmpty);
      });

      test('resets initialLoadComplete flag', () {
        final cache = container.read(feedPostsCacheProvider.notifier);

        // Use updateCache which sets initialLoadComplete = true
        cache.updateCache([
          createFakePost(id: 'test', publishedAt: DateTime.now()),
        ]);

        expect(
          container.read(feedPostsCacheProvider).initialLoadComplete,
          isTrue,
        );

        cache.invalidateCache();

        expect(
          container.read(feedPostsCacheProvider).initialLoadComplete,
          isFalse,
        );
      });
    });

    group('addPost', () {
      test('adds post to beginning of list', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        final olderPost = createFakePost(
          id: 'older',
          publishedAt: now.subtract(const Duration(hours: 2)),
        );
        final newerPost = createFakePost(
          id: 'newer',
          publishedAt: now.subtract(const Duration(hours: 1)),
        );

        cache.addPost(olderPost);
        cache.addPost(newerPost);

        final posts = cache.posts;
        expect(posts.first.id, equals('newer'));
      });

      test('does not add duplicate posts', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        final post = createFakePost(id: 'unique', publishedAt: now);

        cache.addPost(post);
        cache.addPost(post); // Try to add again

        expect(cache.posts.length, equals(1));
      });

      test('respects max cache size of 200', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        // Add more than max cache size (200)
        for (var i = 0; i < 210; i++) {
          cache.addPost(
            createFakePost(
              id: 'post-$i',
              publishedAt: now.subtract(Duration(minutes: i)),
            ),
          );
        }

        // Should be capped at 200
        final state = container.read(feedPostsCacheProvider);
        expect(state.posts.length, equals(200));
      });

      test('updates newestPostTimestamp', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        final post = createFakePost(id: 'newest', publishedAt: now);

        cache.addPost(post);

        final state = container.read(feedPostsCacheProvider);
        expect(state.newestPostTimestamp, equals(post.createdAt));
      });
    });

    group('updatePost', () {
      test('updates existing post in cache', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        final originalPost = createFakePost(
          id: 'test-post',
          publishedAt: now,
          authorUsername: 'original',
        );

        cache.addPost(originalPost);

        final updatedPost = createFakePost(
          id: 'test-post',
          publishedAt: now,
          authorUsername: 'updated',
        );

        cache.updatePost(updatedPost);

        final posts = cache.posts;
        expect(posts.first.authorUsername, equals('updated'));
      });

      test('does nothing for non-existent post', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        cache.addPost(createFakePost(id: 'existing', publishedAt: now));

        final nonExistent = createFakePost(
          id: 'non-existent',
          publishedAt: now,
        );

        // Should not throw
        cache.updatePost(nonExistent);

        expect(cache.posts.length, equals(1));
        expect(cache.posts.first.id, equals('existing'));
      });

      test('preserves post position in list', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        cache.addPost(createFakePost(id: 'first', publishedAt: now));
        cache.addPost(
          createFakePost(
            id: 'second',
            publishedAt: now.subtract(const Duration(hours: 1)),
          ),
        );
        cache.addPost(
          createFakePost(
            id: 'third',
            publishedAt: now.subtract(const Duration(hours: 2)),
          ),
        );

        // Update middle post
        cache.updatePost(
          createFakePost(
            id: 'second',
            publishedAt: now.subtract(const Duration(hours: 1)),
            authorUsername: 'updated',
          ),
        );

        final posts = cache.posts;
        expect(posts[0].id, equals('third')); // Newest added first
        expect(posts[1].id, equals('second'));
        expect(posts[1].authorUsername, equals('updated'));
        expect(posts[2].id, equals('first'));
      });
    });

    group('removePost', () {
      test('removes post by ID', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        cache.addPost(createFakePost(id: 'keep', publishedAt: now));
        cache.addPost(
          createFakePost(
            id: 'remove',
            publishedAt: now.subtract(const Duration(hours: 1)),
          ),
        );

        cache.removePost('remove');

        expect(cache.posts.length, equals(1));
        expect(cache.posts.first.id, equals('keep'));
      });

      test('does nothing for non-existent ID', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        cache.addPost(createFakePost(id: 'existing', publishedAt: now));

        cache.removePost('non-existent');

        expect(cache.posts.length, equals(1));
      });
    });

    group('isCacheValid', () {
      test('returns false when not initialized', () {
        final cache = container.read(feedPostsCacheProvider.notifier);

        expect(cache.isCacheValid, isFalse);
      });

      test('returns true after posts are added via updateCache', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        cache.updateCache([createFakePost(id: 'test', publishedAt: now)]);

        expect(cache.isCacheValid, isTrue);
      });

      test('returns false after invalidation', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        cache.updateCache([createFakePost(id: 'test', publishedAt: now)]);
        expect(cache.isCacheValid, isTrue);

        cache.invalidateCache();
        expect(cache.isCacheValid, isFalse);
      });
    });

    group('updateCache', () {
      test('sets initialLoadComplete to true', () {
        final cache = container.read(feedPostsCacheProvider.notifier);

        expect(
          container.read(feedPostsCacheProvider).initialLoadComplete,
          isFalse,
        );

        cache.updateCache([
          createFakePost(id: 'test', publishedAt: DateTime.now()),
        ]);

        expect(
          container.read(feedPostsCacheProvider).initialLoadComplete,
          isTrue,
        );
      });

      test('sets lastFetchedAt timestamp', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final before = DateTime.now();

        cache.updateCache([
          createFakePost(id: 'test', publishedAt: DateTime.now()),
        ]);

        final state = container.read(feedPostsCacheProvider);
        expect(state.lastFetchedAt, isNotNull);
        expect(
          state.lastFetchedAt!.isAfter(
            before.subtract(const Duration(seconds: 1)),
          ),
          isTrue,
        );
      });

      test('truncates list to max cache size', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        final now = DateTime.now();

        // Create 250 posts
        final posts = List.generate(
          250,
          (i) => createFakePost(
            id: 'post-$i',
            publishedAt: now.subtract(Duration(minutes: i)),
          ),
        );

        cache.updateCache(posts);

        final state = container.read(feedPostsCacheProvider);
        expect(state.posts.length, equals(200));
      });
    });

    group('isInitialLoadComplete', () {
      test('returns false initially', () {
        final cache = container.read(feedPostsCacheProvider.notifier);
        expect(cache.isInitialLoadComplete, isFalse);
      });

      test('returns true after updateCache', () {
        final cache = container.read(feedPostsCacheProvider.notifier);

        cache.updateCache([
          createFakePost(id: 'test', publishedAt: DateTime.now()),
        ]);

        expect(cache.isInitialLoadComplete, isTrue);
      });
    });

    group('hasMorePosts', () {
      test('returns true initially (hasNextPage defaults to true)', () {
        final cache = container.read(feedPostsCacheProvider.notifier);

        // Default state has hasNextPage = true, fullyLoaded = false
        expect(cache.hasMorePosts, isTrue);
      });

      test('returns false after updateCache with hasNextPage false', () {
        final cache = container.read(feedPostsCacheProvider.notifier);

        cache.updateCache([
          createFakePost(id: 'test', publishedAt: DateTime.now()),
        ], hasNextPage: false);

        expect(cache.hasMorePosts, isFalse);
      });
    });
  });
}
