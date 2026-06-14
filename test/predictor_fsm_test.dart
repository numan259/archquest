import 'package:archquest/visualizations/predictor_fsm.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('2-bit predictor FSM — all 4 states × {taken, not-taken}', () {
    test('Strong Taken', () {
      expect(Predictor2BitState.strongTaken.next(true),
          Predictor2BitState.strongTaken); // saturates
      expect(Predictor2BitState.strongTaken.next(false),
          Predictor2BitState.weakTaken);
    });
    test('Weak Taken', () {
      expect(Predictor2BitState.weakTaken.next(true),
          Predictor2BitState.strongTaken);
      expect(Predictor2BitState.weakTaken.next(false),
          Predictor2BitState.weakNotTaken);
    });
    test('Weak Not Taken', () {
      expect(Predictor2BitState.weakNotTaken.next(true),
          Predictor2BitState.weakTaken);
      expect(Predictor2BitState.weakNotTaken.next(false),
          Predictor2BitState.strongNotTaken);
    });
    test('Strong Not Taken', () {
      expect(Predictor2BitState.strongNotTaken.next(true),
          Predictor2BitState.weakNotTaken);
      expect(Predictor2BitState.strongNotTaken.next(false),
          Predictor2BitState.strongNotTaken); // saturates
    });
  });

  test('prediction direction per state', () {
    expect(Predictor2BitState.strongTaken.predictsTaken, isTrue);
    expect(Predictor2BitState.weakTaken.predictsTaken, isTrue);
    expect(Predictor2BitState.weakNotTaken.predictsTaken, isFalse);
    expect(Predictor2BitState.strongNotTaken.predictsTaken, isFalse);
  });

  test('one wrong outcome only weakens (does not flip) a strong prediction', () {
    // The whole point of 2-bit: a single miss keeps the prediction.
    final s = Predictor2BitState.strongTaken.next(false);
    expect(s.predictsTaken, isTrue); // still predicts taken
    expect(s.next(false).predictsTaken, isFalse); // second miss flips it
  });
}
