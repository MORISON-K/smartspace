import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    _images =
        (widget.listing['images'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage) {
        setState(() {
          _currentPage = newPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─────────── LAUNCH HELPERS ────────────────
  void _launchCall(String number) async {
    final uri = Uri.parse("tel:$number");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showError("Cannot make a call.");
    }
  }
  void _launchWhatsApp(String number) async {
  final cleanedNumber = _formatPhoneNumber(number);
  final message = 'Hi, I\'m interested in your property listed on SmartSpace.';
  final url = Uri.parse("https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}");

  debugPrint(" Cleaned number: $cleanedNumber");
  debugPrint(" WhatsApp URL: $url");

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    _showError("Could not open WhatsApp. Please make sure WhatsApp is installed.");
  }
}

String _formatPhoneNumber(String number) {
  // Strip all non-digit characters
  String digits = number.replaceAll(RegExp(r'[^\d+]'), '');

  // Handle numbers that start with '0' (e.g. 0700...)
  if (digits.startsWith('0')) {
    // Replace leading 0 with country code — customize default country here
    return '256${digits.substring(1)}';
  }

  // If already starts with country code but missing '+', add it
  if (digits.startsWith('256') && !digits.startsWith('+')) {
    return digits;
  }

  // Fallback: Assume number is complete (already international)
  return digits.replaceAll('+', '');
}

  


  

  void _launchMap() async {
    final lat = widget.listing['latitude'];
    final lng = widget.listing['longitude'];

    if (lat != null && lng != null) {
      final googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
      );
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
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

  // ─────────── UI ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final phone = widget.listing['mobile_number'] ?? 'Unknown';

    return Scaffold(
      appBar: AppBar(title: const Text("Listing Details")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_images.isNotEmpty)
              SizedBox(
                height: 260,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  itemBuilder:
                      (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          loadingBuilder:
                              (c, w, p) =>
                                  p == null
                                      ? w
                                      : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                          errorBuilder:
                              (c, e, s) =>
                                  const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                ),
              ),
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
                          color: selected ? Colors.blueGrey : Colors.grey[400],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ),
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

                  // ───── ACTION BUTTONS ─────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _launchCall(phone),
                        icon: const Icon(Icons.call),
                        label: const Text("Call"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _launchWhatsApp(widget.listing['mobile_number'] ?? ''),
                        icon: const Icon(Icons.message),
                        label: const Text("WhatsApp"),
),

                      ElevatedButton.icon(
                        onPressed: _launchMap,
                        icon: const Icon(Icons.map),
                        label: const Text("Map"),
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
