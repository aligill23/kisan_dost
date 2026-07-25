// lib/models/review_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String dealerId;
  final String farmerId;
  final String farmerName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.dealerId,
    required this.farmerId,
    required this.farmerName,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory ReviewModel.fromMap(String id, Map<String, dynamic> data) {
    return ReviewModel(
      reviewId: id,
      dealerId: data['dealerId'] ?? '',
      farmerId: data['farmerId'] ?? '',
      farmerName: data['farmerName'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'dealerId': dealerId,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
