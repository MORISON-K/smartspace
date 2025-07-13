import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'search_screen.dart'; // Make sure this import matches your project structure

class ListingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> listing;   // Firestore document data
  final String listingId;               // Firestore document ID

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

  @override
  void initState() {
    super.initState();

    _images = (widget.listing['images'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() => _currentPage = newPage);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─────────────────────── Launch Helpers ───────────────────────
  Future<void> _launchCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Cannot make a call.');
    }
  }

  Future<void> _launchWhatsApp(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) {
      _showError('Contact number not available.');
      return;
    }

    final message = Uri.encodeComponent(
      "Hello, I'm interested in your listing on SmartSpace (ID: ${widget.listingId}).",
    );
    final url = Uri.parse('https://wa.me/$cleaned?text=$message');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError('WhatsApp not installed.');
    }
  }

  void _navigateToMap() {
    final lat = widget.listing['latitude'];
    final lng = widget.listing['longitude'];

    if (lat == null || lng == null) {
      _showError('Location coordinates not available.');
      return;
    }

    final target = LatLng(lat, lng);
    final label = widget.listing['location'] ?? 'Listing Location';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          targetLocation: target,
          label: label,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ─────────────────────── UI ───────────────────────
  @override
  Widget build(BuildContext context) {
    final phone = widget.listing['mobile_number']?.toString() ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text('Listing Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───── Image Carousel ─────
            if (_images.isNotEmpty)
              SizedBox(
                height: 260,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ),

            // ───── Page Indicators ─────
            if (_images.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_images.length, (i) {
                      final selected = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.blueGrey
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ),

            // ───── Details Section ─────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.listing['location'] ?? 'Unknown location',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Category: ${widget.listing['category'] ?? '-'}'),
                  Text('Size: ${widget.listing['description'] ?? '-'}'),
                  Text('Price: UGX ${widget.listing['price'] ?? '0'}'),
                  Text('Contact: $phone'),
                  const SizedBox(height: 16),

                  // ───── Action Buttons ─────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _launchCall(phone),
                        icon: const Icon(Icons.call),
                        label: const Text('Call'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _launchWhatsApp(phone),
                        icon: const Icon(Icons.message),
                        label: const Text('WhatsApp'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _navigateToMap,
                        icon: const Icon(Icons.map),
                        label: const Text('Map'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Listing ID: ${widget.listingId}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
