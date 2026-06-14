/// The four states of a 2-bit saturating-counter branch predictor. Extracted
/// from the simulator widget so the transition logic can be unit-tested
/// directly. The two "Taken" states predict taken; the two "Not Taken" states
/// predict not taken.
enum Predictor2BitState {
  strongTaken('Strong\nTaken', true),
  weakTaken('Weak\nTaken', true),
  weakNotTaken('Weak\nNot Taken', false),
  strongNotTaken('Strong\nNot Taken', false);

  const Predictor2BitState(this.label, this.predictsTaken);
  final String label;
  final bool predictsTaken;

  /// One step of the saturating counter: a taken outcome moves toward
  /// strongTaken, a not-taken outcome toward strongNotTaken. The counter only
  /// ever moves one step, and saturates at the two ends.
  Predictor2BitState next(bool taken) => switch (this) {
        Predictor2BitState.strongTaken =>
          taken ? Predictor2BitState.strongTaken : Predictor2BitState.weakTaken,
        Predictor2BitState.weakTaken =>
          taken ? Predictor2BitState.strongTaken : Predictor2BitState.weakNotTaken,
        Predictor2BitState.weakNotTaken =>
          taken ? Predictor2BitState.weakTaken : Predictor2BitState.strongNotTaken,
        Predictor2BitState.strongNotTaken => taken
            ? Predictor2BitState.weakNotTaken
            : Predictor2BitState.strongNotTaken,
      };
}
