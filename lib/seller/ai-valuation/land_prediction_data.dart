class LandPredictionData {
  final String tenure;
  final String location;
  final String use;
  final double plotSize;
  final double? predictedValue;

  LandPredictionData({
    required this.tenure,
    required this.location,
    required this.use,
    required this.plotSize,
    this.predictedValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'tenure': tenure,
      'location': location,
      'use': use,
      'plotSize': plotSize,
      'predictedValue': predictedValue,
    };
  }

  factory LandPredictionData.fromMap(Map<String, dynamic> map) {
    return LandPredictionData(
      tenure: map['tenure'] ?? '',
      location: map['location'] ?? '',
      use: map['use'] ?? '',
      plotSize: map['plotSize']?.toDouble() ?? 0.0,
      predictedValue: map['predictedValue']?.toDouble(),
    );
  }
}
