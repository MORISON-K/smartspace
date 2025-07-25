import 'package:flutter/material.dart';
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

    final formattedNumber = '+$phoneNumber';
    final uri = Uri.parse("tel:$formattedNumber");

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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_images.isNotEmpty)
                SizedBox(
                  height: 260,
                  child: Stack(
                    children: [
                      PageView.builder(
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
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_images.length, (i) {
                            final selected = i == _currentPage;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: selected ? 12 : 12,
                              height: 8,
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : Colors.white60,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // ───── Listing Details Card ─────
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 45,
                    vertical: 16,
                  ),

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
                      const SizedBox(height: 20),
                      Text(
                        'Category: ${widget.listing['category'] ?? '-'}',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 236, 175, 7),
                        ),
                      ),
                      Text(
                        'Description: ${widget.listing['description'] ?? '-'}',
                      ),

                      Text(
                        'Price: UGX ${widget.listing['price'] ?? '0'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 236, 175, 7),
                        ),
                      ),
                      Text('Contact: $phone'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ───── Action Buttons ─────
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () => _launchCall(phone),
                    icon: const Icon(Icons.call),
                    label: const Text("Call"),
                  ),
                  FilledButton.icon(
                    onPressed: () => _launchWhatsApp(phone),
                    icon: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.white,
                    ),
                    label: const Text("WhatsApp"),
                  ),

                  FilledButton.icon(
                    onPressed: _launchMap,
                    icon: const Icon(Icons.map),
                    label: const Text("Map"),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
