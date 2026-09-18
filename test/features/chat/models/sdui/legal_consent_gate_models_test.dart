import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/features/chat/models/sdui/legal_consent_gate_models.dart';

void main() {
  group('LegalConsentGateBlockData.fromJson', () {
    test('парсит валидный блок reason=initial с двумя вопросами', () {
      final data = LegalConsentGateBlockData.fromJson({
        'type': 'legal_consent_gate',
        'reason': 'initial',
        'questions': [
          {
            'key': 'legal:medical_data_accepted',
            'label': {'ru': 'Согласие на обработку данных о здоровье', 'en': 'Health data consent'},
          },
          {
            'key': 'legal:model_training_accepted',
            'label': {'ru': 'Согласие на обучение моделей', 'en': 'Model training consent'},
          },
        ],
      });

      expect(data.reason, 'initial');
      expect(data.questions, hasLength(2));
      expect(data.questions[0].key, 'legal:medical_data_accepted');
      expect(data.questions[0].label, 'Согласие на обработку данных о здоровье');
      expect(data.questions[1].key, 'legal:model_training_accepted');
    });

    test('парсит reason=declined', () {
      final data = LegalConsentGateBlockData.fromJson({
        'type': 'legal_consent_gate',
        'reason': 'declined',
        'questions': [
          {'key': 'legal:medical_data_accepted', 'label': 'Health data consent'},
        ],
      });
      expect(data.reason, 'declined');
    });

    test('label как plain string (не объект {ru,en}) — берётся как есть', () {
      final data = LegalConsentGateBlockData.fromJson({
        'reason': 'initial',
        'questions': [
          {'key': 'legal:medical_data_accepted', 'label': 'Plain label text'},
        ],
      });
      expect(data.questions.single.label, 'Plain label text');
    });

    test('label отсутствует вовсе — фолбэк на key', () {
      final data = LegalConsentGateBlockData.fromJson({
        'reason': 'initial',
        'questions': [
          {'key': 'legal:medical_data_accepted'},
        ],
      });
      expect(data.questions.single.label, 'legal:medical_data_accepted');
    });

    test('label — объект без ru/en — фолбэк на key', () {
      final data = LegalConsentGateBlockData.fromJson({
        'reason': 'initial',
        'questions': [
          {
            'key': 'legal:medical_data_accepted',
            'label': {'kk': 'қазақша мәтін'},
          },
        ],
      });
      expect(data.questions.single.label, 'legal:medical_data_accepted');
    });

    test('label — объект без ru, с en — фолбэк на en', () {
      final data = LegalConsentGateBlockData.fromJson({
        'reason': 'initial',
        'questions': [
          {
            'key': 'legal:medical_data_accepted',
            'label': {'en': 'English only label'},
          },
        ],
      });
      expect(data.questions.single.label, 'English only label');
    });

    test('отсутствует reason — FormatException', () {
      expect(
        () => LegalConsentGateBlockData.fromJson({
          'questions': [
            {'key': 'legal:medical_data_accepted', 'label': 'x'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('reason не строка — FormatException', () {
      expect(
        () => LegalConsentGateBlockData.fromJson({
          'reason': 42,
          'questions': [
            {'key': 'legal:medical_data_accepted', 'label': 'x'},
          ],
        }),
        throwsFormatException,
      );
    });

    test('questions отсутствует — FormatException', () {
      expect(
        () => LegalConsentGateBlockData.fromJson({'reason': 'initial'}),
        throwsFormatException,
      );
    });

    test('questions — пустой список — FormatException', () {
      expect(
        () => LegalConsentGateBlockData.fromJson({'reason': 'initial', 'questions': []}),
        throwsFormatException,
      );
    });

    test('вопрос без key — FormatException', () {
      expect(
        () => LegalConsentGateBlockData.fromJson({
          'reason': 'initial',
          'questions': [
            {'label': 'no key here'},
          ],
        }),
        throwsFormatException,
      );
    });
  });
}
