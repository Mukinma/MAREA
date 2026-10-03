import 'package:flutter_test/flutter_test.dart';
import 'package:marea/features/community/models/community_models.dart';
import '../../support/mission_repository_fake.dart';

void main() {
  test('legacy compensation stays unknown and paid cents render MXN', () {
    final row = {
      'id': 'm',
      'author_id': 'a',
      'title': 'Misión',
      'body': 'Una misión',
      'category': 'arte',
      'location': 'Centro',
      'starts_at': '2100-01-01T10:00:00Z',
      'capacity': 1,
      'status': 'open',
      'created_at': '2026-01-01T00:00:00Z',
    };
    expect(Mission.fromJson(row).compensationLabel, 'Compensación no indicada');
    expect(
      Mission.fromJson({
        ...row,
        'compensation_type': 'paid',
        'compensation_amount_cents': 25050,
      }).compensationLabel,
      r'$250.50 MXN por participante',
    );
  });
  test(
    'application requires availability and rejects insecure or excessive samples',
    () {
      MissionApplicationInput input({
        bool available = true,
        List<MissionEvidence> evidence = const [],
      }) => MissionApplicationInput(
        message: 'Me gustaría colaborar',
        availabilityConfirmed: available,
        evidence: evidence,
        operationId: '11111111-1111-4111-8111-111111111111',
      );
      expect(input().validate(), isNull);
      expect(input(available: false).validate(), isNotNull);
      expect(
        input(
          evidence: [
            const MissionEvidence(title: 'Trabajo', url: 'http://example.com'),
          ],
        ).validate(),
        isNotNull,
      );
      expect(
        input(
          evidence: List.generate(
            4,
            (i) => MissionEvidence(
              title: 'Trabajo $i',
              url: 'https://example.com/$i',
            ),
          ),
        ).validate(),
        isNotNull,
      );
      expect(
        input(
          evidence: [
            const MissionEvidence(
              title: 'Trabajo',
              showcaseId: 'ficha',
              url: 'https://example.com',
            ),
          ],
        ).validate(),
        isNotNull,
      );
    },
  );
  test('input rejects invalid compensation and sends exact cents', () {
    final m = missionFixture();
    MissionInput input(String? type, int? amount) => MissionInput(
      title: m.title,
      body: m.body,
      category: m.category,
      location: m.location,
      startsAt: m.startsAt,
      capacity: m.capacity,
      compensationType: type,
      compensationAmountCents: amount,
    );
    expect(input('paid', 0).validate(), isNotNull);
    expect(input('unpaid', 100).validate(), isNotNull);
    expect(input('paid', 25050).toJson()['compensation_amount_cents'], 25050);
    expect(input(null, null).validate(), isNull);
  });
  test('old applications do not claim confirmed availability', () {
    final old = MissionApplication.fromJson({
      'id': 'a',
      'mission_id': 'm',
      'applicant_id': 'u',
      'message': 'Hola',
      'status': 'pending',
      'created_at': '2026-01-01T00:00:00Z',
    });
    expect(old.availabilityConfirmed, isNull);
    expect(old.evidence, isEmpty);
  });
}
