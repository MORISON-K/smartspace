import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  final String id;
  final String title;
  final String description;
  final String location;

  final String category;
  final String sellerPrice;
  final String predictedPrice;
  final List<String> images;
  final String pdfUrl;
  final String status;
  final double latitude;
  final double longitude;
  final String tenure;
  final String mobileNumber;
  final String sellerName;
  final String userId;
  final DateTime createdAt;

  // Prediction data
  final String? originalLocation;
  final double? originalPlotSize;
  final String? originalUse;
  final int? predictedValue;
  final DateTime? predictionTimestamp;
  final bool usedPredictedPrice;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.sellerPrice,
    required this.predictedPrice,
    required this.images,
    required this.pdfUrl,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.tenure,
    required this.mobileNumber,
    required this.sellerName,
    required this.userId,
    required this.createdAt,
    this.originalLocation,
    this.originalPlotSize,
    this.originalUse,
    this.predictedValue,
    this.predictionTimestamp,
    required this.usedPredictedPrice,
  });

  factory Property.fromFirestore(Map<String, dynamic> data, String id) {
    final predictionData = data['prediction_data'] ?? {};

    return Property(
      id: id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      location: data['location'] ?? '',

      category: data['category'] ?? '',
      sellerPrice: data['price'] ?? '0',
      predictedPrice:
          data['prediction_data'] != null &&
                  data['prediction_data']['predicted_value'] != null
              ? data['prediction_data']['predicted_value'].toString()
              : '0',
      images: List<String>.from(data['images'] ?? []),
      pdfUrl: data['pdf'] ?? '',
      status: data['status'] ?? 'Pending',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      tenure: data['tenure'] ?? '',
      mobileNumber: data['mobile_number'] ?? '',
      sellerName: data['sellerName'] ?? '',
      userId: data['user_id'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      originalLocation: predictionData['original_location'],
      originalPlotSize:
          (predictionData['original_plot_size'] as num?)?.toDouble(),
      originalUse: predictionData['original_use'],
      predictedValue:
          predictionData['predicted_value'] is int
              ? predictionData['predicted_value']
              : (predictionData['predicted_value'] is double)
              ? (predictionData['predicted_value'] as double).toInt()
              : null,
      predictionTimestamp:
          (predictionData['prediction_timestamp'] as Timestamp?)?.toDate(),
      usedPredictedPrice: predictionData['used_predicted_price'] ?? false,
    );
  }
}
