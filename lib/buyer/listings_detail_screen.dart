import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'fullscreen_imageview.dart';

class ListingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> listing;
  final String listingId;

  const ListingDetailScreen({
    super.key,
    required this.listing,
    required this.listingId,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  late final List<String> _images;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> relatedListings = [];
  bool loadingRelated = true;

  @override
  void initState() {
    super.initState();
    _images =
        (widget.listing['images'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

    _fetchRelatedListings();

    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    });
  }

  Future<void> _fetchRelatedListings() async {
    try {
      final location = widget.listing['location'];
      final category = widget.listing['category'];

      final snapshot =
          await FirebaseFirestore.instance
              .collection('listings')
              .where('location', isEqualTo: location)
              .where('category', isEqualTo: category)
              .get();

      final items =
          snapshot.docs
              .where((doc) => doc.id != widget.listingId)
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

      setState(() {
        relatedListings = items;
        loadingRelated = false;
      });
    } catch (e) {
      _showError('Error loading related listings.');
      setState(() {
        loadingRelated = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _launchCall(String number) async {
    String phoneNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    if (!phoneNumber.startsWith('256')) {
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '256${phoneNumber.substring(1)}';
      } else if (phoneNumber.startsWith('7')) {
        phoneNumber = '256$phoneNumber';
      } else {
        phoneNumber = '256$phoneNumber';
      }
    }

    final uri = Uri.parse("tel:+$phoneNumber");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError("Cannot make a call.");
    }
  }

  void _launchWhatsApp(String number) async {
    String cleanedNumber = number.replaceAll(RegExp(r'[^\d]'), '');

    if (!cleanedNumber.startsWith('256')) {
      if (cleanedNumber.startsWith('0')) {
        cleanedNumber = '256${cleanedNumber.substring(1)}';
      } else if (cleanedNumber.startsWith('7')) {
        cleanedNumber = '256$cleanedNumber';
      } else {
        cleanedNumber = '256$cleanedNumber';
      }
    }

    final message =
        'Hi, I\'m interested in your property listed on SmartSpace.';
    final url = Uri.parse(
      "https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showError("Could not open WhatsApp.");
      }
    } catch (e) {
      _showError("Error opening WhatsApp: ${e.toString()}");
    }
  }

  void _launchMap() async {
    final lat = widget.listing['latitude'];
    final lng = widget.listing['longitude'];

    if (lat != null && lng != null) {
      final url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showError("Could not open Google Maps.");
      }
    } else {
      _showError("Location coordinates not available.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.listing['mobile_number'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.listing['location'] ?? 'Listing Details',
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_images.isNotEmpty)
              Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _images.length,
                      itemBuilder:
                          (context, index) => GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => Scaffold(
                                        body: FullScreenImageView(
                                          imageUrl: _images[index],
                                        ),
                                      ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder:
                                    (c, w, p) =>
                                        p == null
                                            ? w
                                            : const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                errorBuilder:
                                    (c, e, s) => const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                              ),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_images.length, (i) {
                      final selected = i == _currentPage;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: selected ? 14 : 10,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selected ? Colors.black : Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Listing details
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      Icons.location_on,
                      widget.listing['location'] ?? 'Unknown location',
                      isTitle: true,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.category,
                      "Category: ${widget.listing['category'] ?? '-'}",
                    ),
                    _buildDetailRow(
                      Icons.info_outline,
                      "Description: ${widget.listing['description'] ?? '-'}",
                    ),
                    _buildDetailRow(
                      Icons.square_foot,
                      "Size: ${widget.listing['acreage'] ?? '-'}",
                    ),
                    _buildDetailRow(
                      Icons.price_change,
                      "UGX ${widget.listing['price'] ?? '0'}",
                      isPrice: true,
                    ),
                    _buildDetailRow(Icons.phone, "Contact: $phone"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  Icons.call,
                  "Call",
                  () => _launchCall(phone),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  FontAwesomeIcons.whatsapp,
                  "WhatsApp",
                  () => _launchWhatsApp(phone),
                ),
                const SizedBox(width: 8),
                _buildActionButton(Icons.map, "Map", _launchMap),
              ],
            ),
            const SizedBox(height: 32),

            // Related Listings Section
            Text(
              "Related Listings",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (loadingRelated)
              const Center(child: CircularProgressIndicator())
            else if (relatedListings.isEmpty)
              const Text("No related listings found.")
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: relatedListings.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = relatedListings[index];
                    final image = (item['images'] as List?)?.first ?? '';

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ListingDetailScreen(
                                  listing: item,
                                  listingId: item['id'],
                                ),
                          ),
                        );
                      },
                      child: Container(
                        width: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                image,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (c, e, s) => const Icon(Icons.broken_image),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['location'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "UGX ${item['price'] ?? '0'}",
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String text, {
    bool isTitle = false,
    bool isPrice = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isTitle ? 18 : 14,
                fontWeight:
                    isTitle || isPrice ? FontWeight.bold : FontWeight.normal,
                color:
                    isPrice
                        ? const Color.fromARGB(255, 236, 175, 7)
                        : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    Color iconColor = Colors.white,
  }) {
    return Expanded(
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A72),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
