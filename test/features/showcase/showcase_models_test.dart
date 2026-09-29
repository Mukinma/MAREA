import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/profile/models/profile.dart';
import 'package:marea/features/showcase/models/showcase.dart';

void main() {
  ShowcaseInput input(
    ShowcaseKind kind, {
    ShowcaseStatus status = ShowcaseStatus.published,
    List<String> photos = const [],
    double? price,
    String body = 'Una descripción',
  }) => ShowcaseInput(
    kind: kind,
    title: 'Mi ficha',
    body: body,
    category: 'arte',
    status: status,
    imagePaths: photos,
    price: price,
  );
  test('a published artwork or product needs a photograph', () {
    expect(input(ShowcaseKind.project).validate(), isNotNull);
    expect(input(ShowcaseKind.product).validate(), isNotNull);
    expect(
      input(ShowcaseKind.project, photos: ['owner/photo.png']).validate(),
      isNull,
    );
  });
  test('drafts allow incomplete description and images', () {
    expect(
      input(
        ShowcaseKind.project,
        status: ShowcaseStatus.draft,
        body: '',
      ).validate(),
      isNull,
    );
  });
  test('professional capabilities and prices are enforced', () {
    expect(
      input(ShowcaseKind.service).validate(userType: UserType.general),
      isNotNull,
    );
    expect(
      input(
        ShowcaseKind.service,
        price: 150,
      ).validate(userType: UserType.business),
      isNull,
    );
    expect(
      input(ShowcaseKind.project, photos: ['a'], price: 150).validate(),
      isNotNull,
    );
    expect(
      input(ShowcaseKind.service, price: double.nan).validate(),
      isNotNull,
    );
  });
  test('six unique ordered photographs maximum', () {
    expect(
      input(
        ShowcaseKind.product,
        photos: List.generate(7, (i) => '$i'),
      ).validate(),
      isNotNull,
    );
    expect(
      input(ShowcaseKind.product, photos: ['a', 'a']).validate(),
      isNotNull,
    );
  });
  test('hours reject backwards intervals and unknown days', () {
    expect(ProfilePreferences.hoursError({'mon': '18:00-09:00'}), isNotNull);
    expect(
      ProfilePreferences.hoursError({'mon': '09:00-18:00', 'sun': null}),
      isNull,
    );
    expect(ProfilePreferences.hoursError({'other': null}), isNotNull);
  });
}
