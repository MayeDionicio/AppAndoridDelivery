// lib/models/review.dart
class Review {
  final String reviewer;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.reviewer,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
