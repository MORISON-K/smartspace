class Property {
  final String id;
  final String title;
  final String description;
  final String location;
  final String category;
  final String price;
  final List<String> images;
  final String pdfUrl;
  final String status;

  Property({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.price,
    required this.images,
    required this.pdfUrl,
    required this.status,
  });

  factory Property.fromFirestore(Map<String, dynamic> data, String id) {
    return Property(
      id: id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      category: data['category'] ?? '',
      price: data['price'] ?? '0',
      images: List<String>.from(data['images'] ?? []),
      pdfUrl: data['pdf'] ?? '',
      status: data['status'] ?? 'Pending',
    );
  }
}
