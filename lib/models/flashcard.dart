import 'json_utils.dart';

/// A two-sided study card.
class Flashcard {
  final String front;
  final String back;
  final String concept;

  const Flashcard({
    required this.front,
    required this.back,
    this.concept = '',
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        front: asStr(json['front']),
        back: asStr(json['back']),
        concept: asStr(json['concept']),
      );
}
