import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/home_feed/models/home_feed_models.dart';
import 'package:marea/features/home_feed/models/story.dart';

void main() {
  test('nearby coordinates are required and radius is bounded', () {
    expect(
      const HomeFeedFilter(mode: HomeFeedMode.nearby).validate(),
      isNotNull,
    );
    expect(
      const HomeFeedFilter(
        mode: HomeFeedMode.nearby,
        latitude: 19,
        longitude: -99,
      ).validate(),
      isNull,
    );
    expect(
      const HomeFeedFilter(
        mode: HomeFeedMode.nearby,
        latitude: 91,
        longitude: -99,
      ).validate(),
      isNotNull,
    );
  });
  test('stories require content and reject more than 500 characters', () {
    expect(const StoryInput(id: 'id').validate(), isNotNull);
    expect(const StoryInput(id: 'id', text: 'Hola').validate(), isNull);
    expect(StoryInput(id: 'id', text: 'x' * 501).validate(), isNotNull);
  });
  test('expired stories are unavailable at the exact server deadline', () {
    final expires = DateTime.utc(2030, 1, 2);
    final story = Story(
      id: 'id',
      authorId: 'author',
      text: 'Hola',
      createdAt: expires.subtract(const Duration(hours: 24)),
      expiresAt: expires,
    );
    expect(
      story.isAvailableAt(expires.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(story.isAvailableAt(expires), isFalse);
  });
}
