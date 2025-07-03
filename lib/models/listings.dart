class Listing {
  final String id;
  final String title;
  final int price;
  final String location;
  final String sellerId;
  final String imageUrl;
  final String description;

  Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.sellerId,
    required this.imageUrl,
    required this.description,
  });

  factory Listing.fromFirestore(Map<String, dynamic> data, String docId) {
    return Listing(
      id: docId,
      title: data['title'],
      price: data['price'],
      location: data['location'],
      sellerId: data['sellerId'],
      imageUrl: data['imageUrl'],
      description: data['description'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'location': location,
      'sellerId': sellerId,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}
