import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:smartspace/admin/screens/property_details_screen.dart';
import 'package:smartspace/admin/models/properties.dart';
import 'package:smartspace/admin/screens/pdf_viewer_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Firestore references
  final CollectionReference listingsCollection = FirebaseFirestore.instance
      .collection('listings');

  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  // Bottom navigation index
  int _currentIndex = 0;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all'; // all, pending, approved, rejected
  String _sortBy = 'newest'; // newest, oldest

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to format currency
  String _formatPrice(String price) {
    final value = double.tryParse(price) ?? 0;
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(value);
  }

  // Helper to format time difference
  String _formatTimeDifference(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper to format timestamp
  String _formatTime(Timestamp timestamp) {
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  // Filter and sort listings based on search criteria
  List<DocumentSnapshot> _filterAndSortListings(
    List<DocumentSnapshot> listings,
  ) {
    List<DocumentSnapshot> filtered = listings;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final description =
                (data['description'] ?? '').toString().toLowerCase();
            final location = (data['location'] ?? '').toString().toLowerCase();
            final price = (data['price'] ?? '').toString().toLowerCase();

            return description.contains(_searchQuery) ||
                location.contains(_searchQuery) ||
                price.contains(_searchQuery);
          }).toList();
    }

    // Filter by status (for listings tab when showing all statuses)
    if (_selectedStatus != 'all' && _currentIndex == 0) {
      filtered =
          filtered.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _selectedStatus;
          }).toList();
    }

    // Sort by time
    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime =
          (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final bTime =
          (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

      return _sortBy == 'newest'
          ? bTime.compareTo(aTime)
          : aTime.compareTo(bTime);
    });

    return filtered;
  }

  // Filter and sort additional documents
  List<DocumentSnapshot> _filterAndSortRequests(
    List<DocumentSnapshot> requests,
  ) {
    List<DocumentSnapshot> filtered = requests;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final userName = (data['name'] ?? '').toString().toLowerCase();
            final documentType =
                (data['pendingDocumentType'] ?? '').toString().toLowerCase();

            return userName.contains(_searchQuery) ||
                documentType.contains(_searchQuery);
          }).toList();
    }

    // Sort by time (prioritize recent document uploads)
    filtered.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      // Get the most recent timestamp between lastRequestTime and documentUploadTime
      final aRequestTime = (aData['lastRequestTime'] as Timestamp?)?.toDate();
      final aDocumentTime =
          (aData['documentUploadTime'] as Timestamp?)?.toDate();

      DateTime aTime;
      if (aRequestTime == null && aDocumentTime == null) {
        aTime = DateTime(2000);
      } else if (aRequestTime == null) {
        aTime = aDocumentTime!;
      } else if (aDocumentTime == null) {
        aTime = aRequestTime;
      } else {
        aTime =
            aRequestTime.isAfter(aDocumentTime) ? aRequestTime : aDocumentTime;
      }

      final bRequestTime = (bData['lastRequestTime'] as Timestamp?)?.toDate();
      final bDocumentTime =
          (bData['documentUploadTime'] as Timestamp?)?.toDate();

      DateTime bTime;
      if (bRequestTime == null && bDocumentTime == null) {
        bTime = DateTime(2000);
      } else if (bRequestTime == null) {
        bTime = bDocumentTime!;
      } else if (bDocumentTime == null) {
        bTime = bRequestTime;
      } else {
        bTime =
            bRequestTime.isAfter(bDocumentTime) ? bRequestTime : bDocumentTime;
      }

      return _sortBy == 'newest'
          ? bTime.compareTo(aTime)
          : aTime.compareTo(bTime);
    });

    return filtered;
  }

  // Build search and filter bar
  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    _currentIndex == 0
                        ? "Search listings by description, location, or price..."
                        : "Search documents by user name or document type...",
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter and sort options
          Row(
            children: [
              // Status filter (only for listings)
              if (_currentIndex == 0) ...[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: const TextStyle(
                        color: Color(0xFFD4AF37), // Gold color
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    dropdownColor: Colors.black87,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37), // Gold color
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending'),
                      ),
                      DropdownMenuItem(
                        value: 'approved',
                        child: Text('Approved'),
                      ),
                      DropdownMenuItem(
                        value: 'rejected',
                        child: Text('Rejected'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Sort options
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                      labelStyle: const TextStyle(
                        color: Color(0xFFD4AF37), // Gold color
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    dropdownColor: Colors.black87,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37), // Gold color
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('Newest First'),
                      ),
                      DropdownMenuItem(
                        value: 'oldest',
                        child: Text('Oldest First'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigate to property details
  void _navigateToPropertyDetails(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Create a Property object from the document data
    final property = Property.fromFirestore(data, doc.id);

    // Navigate to PropertyDetailsScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyDetailsScreen(property: property),
      ),
    ).then((result) {
      // Refresh the list if needed
      if (result == true) {
        setState(() {});
      }
    });
  }

  // Build listings tab (now supports all statuses)
  Widget _buildListingsTab() {
    Query query = listingsCollection;

    // If status filter is not 'all', apply status filter
    if (_selectedStatus != 'all') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("Error loading listings"));
        }

        final allListings = snapshot.data!.docs;
        final filteredListings = _filterAndSortListings(allListings);

        if (filteredListings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.pending_actions,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? "No listings found matching your search"
                      : "No listings found",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                if (_searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    child: const Text("Clear search"),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredListings.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return SectionHeader(
                title:
                    _selectedStatus == 'all'
                        ? "📋 All Listings"
                        : _selectedStatus == 'pending'
                        ? "📝 Pending Listings"
                        : _selectedStatus == 'approved'
                        ? "✅ Approved Listings"
                        : "❌ Rejected Listings",
                count: filteredListings.length,
              );
            }
            final listing = filteredListings[index - 1];
            final data = listing.data() as Map<String, dynamic>;

            return _ListingItem(
              id: listing.id,
              title: data['description'] ?? 'No Description',
              location: data['location'] ?? 'Unknown Location',
              price:
                  data['price'] != null
                      ? _formatPrice(data['price'])
                      : 'Price not set',
              status: data['status'] ?? 'pending',
              createdAt:
                  data['createdAt'] as Timestamp? ?? Timestamp.now(),
              onViewDetails: () => _navigateToPropertyDetails(listing),
            );
          },
        );
      },
    );
  }

  // Build additional documents tab
  Widget _buildUserRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collectionGroup('documentRequests')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text("Error: ${snapshot.error}"),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text("Retry"),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("No data available"));
        }

        final allDocs = snapshot.data!.docs;

        // DEBUG: Log total documents fetched
        print('Total documentRequests fetched: \${allDocs.length}');

        // Temporarily remove filter on sellerDocuments to troubleshoot
        // final requestDocs =
        //     allDocs.where((doc) {
        //       final data = doc.data() as Map<String, dynamic>;
        //       final sellerDocs =
        //           data['sellerDocuments'] as List<dynamic>? ?? [];
        //       return sellerDocs.isNotEmpty;
        //     }).toList();

        final requestDocs =
            allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final sellerDocs =
                  data['sellerDocuments'] as List<dynamic>? ?? [];
              return sellerDocs.isNotEmpty;
            }).toList();

        // DEBUG: Log documents after filtering
        print('DocumentRequests after filtering: \${requestDocs.length}');

        final filteredRequests = _filterAndSortRequests(requestDocs);

        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.file_copy_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? "No documents found matching your search"
                      : "No additional documents uploaded",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                if (_searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    child: const Text("Clear search"),
                  ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SectionHeader(
                title: "📄 Additional Documents",
                count: filteredRequests.length,
              ),
            ),
            SizedBox(
              height: 400,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: filteredRequests.length,
                itemBuilder: (context, index) {
                  final doc = filteredRequests[index];
                  final data = doc.data() as Map<String, dynamic>;

                  // Get parent listing document ID
                  final listingId = doc.reference.parent.parent?.id;

                  if (listingId == null) {
                    return _RequestItem(
                      id: doc.id,
                      user: 'Unknown User',
                      message:
                          data['message'] ?? 'Uploaded additional documents',
                      createdAt:
                          data['timestamp'] as Timestamp? ?? Timestamp.now(),
                      isDocumentUpload: true,
                      documentType: data['documentType'] ?? '',
                      documentUrls: List<String>.from(
                        data['sellerDocuments'] ?? [],
                      ),
                      hasRequests: false,
                    );
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: listingsCollection.doc(listingId).get(),
                    builder: (context, listingSnapshot) {
                      if (listingSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!listingSnapshot.hasData ||
                          !listingSnapshot.data!.exists) {
                        return _RequestItem(
                          id: doc.id,
                          user: 'Unknown User',
                          message:
                              data['message'] ??
                              'Uploaded additional documents',
                          createdAt:
                              data['timestamp'] as Timestamp? ??
                              Timestamp.now(),
                          isDocumentUpload: true,
                          documentType: data['documentType'] ?? '',
                          documentUrls: List<String>.from(
                            data['sellerDocuments'] ?? [],
                          ),
                          hasRequests: false,
                        );
                      }

                      final listingData =
                          listingSnapshot.data!.data() as Map<String, dynamic>?;

                      final userId =
                          listingData?['userId'] ??
                          listingData?['user_id'] ??
                          null;

                      if (userId == null) {
                        return _RequestItem(
                          id: doc.id,
                          user: 'Unknown User',
                          message:
                              data['message'] ??
                              'Uploaded additional documents',
                          createdAt:
                              data['timestamp'] as Timestamp? ??
                              Timestamp.now(),
                          isDocumentUpload: true,
                          documentType: data['documentType'] ?? '',
                          documentUrls: List<String>.from(
                            data['sellerDocuments'] ?? [],
                          ),
                          hasRequests: false,
                        );
                      }

                      return FutureBuilder<DocumentSnapshot>(
                        future: usersCollection.doc(userId).get(),
                        builder: (context, userSnapshot) {
                          String userName = 'Unknown User';
                          if (userSnapshot.connectionState ==
                                  ConnectionState.done &&
                              userSnapshot.hasData &&
                              userSnapshot.data != null &&
                              userSnapshot.data!.exists) {
                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                            if (userData != null && userData['name'] != null) {
                              userName = userData['name'];
                            }
                          }

                          return _RequestItem(
                            id: doc.id,
                            user: userName,
                            message:
                                data['message'] ??
                                'Uploaded additional documents',
                            createdAt:
                                data['timestamp'] as Timestamp? ??
                                Timestamp.now(),
                            isDocumentUpload: true,
                            documentType: data['documentType'] ?? '',
                            documentUrls: List<String>.from(
                              data['sellerDocuments'] ?? [],
                            ),
                            hasRequests: false,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFD4AF37), // Gold color
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome to the SmartSpace Admin Dashboard. Here you can manage property listings, review additional documents,and monitor system activity efficiently.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Search and filter bar
              _buildSearchAndFilterBar(),

              // Content based on selected tab
              _currentIndex == 0
                  ? _buildListingsTab()
                  : _buildUserRequestsTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Reset search when switching tabs
            _searchController.clear();
            _selectedStatus = 'all';
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream:
                  listingsCollection
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                return Stack(
                  children: [
                    const Icon(Icons.list_alt),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Listings',
          ),
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: usersCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Icon(Icons.file_copy);
                }

                // Count documents that have hasNewDocuments = true
                final count =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final hasNewDocuments = data['hasNewDocuments'] == true;
                      return hasNewDocuments;
                    }).length;

                return Stack(
                  children: [
                    const Icon(Icons.file_copy),
                    if (count > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Additional Docs',
          ),
        ],
      ),
    );
  }
}

// --- Custom Widgets ---

class SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Widget? child;

  const SectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (child != null) child!,
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ListingItem extends StatelessWidget {
  final String id;
  final String title;
  final String location;
  final String price;
  final String status;
  final Timestamp createdAt;
  final VoidCallback onViewDetails;

  const _ListingItem({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.status,
    required this.createdAt,
    required this.onViewDetails,
  });

  Color _getStatusColor() {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo =
        (context
                .findAncestorStateOfType<_DashboardScreenState>()
                ?._formatTimeDifference(createdAt) ??
            '');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(location, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("View Details"),
                  ),
                ),
                if (status == 'pending') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        // Approve listing
                        await FirebaseFirestore.instance
                            .collection('listings')
                            .doc(id)
                            .update({'status': 'approved'});
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Approve"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        // Reject listing
                        await FirebaseFirestore.instance
                            .collection('listings')
                            .doc(id)
                            .update({'status': 'rejected'});
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestItem extends StatelessWidget {
  final String id;
  final String user;
  final String message;
  final Timestamp createdAt;
  final bool isDocumentUpload;
  final String documentType;
  final List<String> documentUrls;
  final bool hasRequests;

  const _RequestItem({
    required this.id,
    required this.user,
    required this.message,
    required this.createdAt,
    this.isDocumentUpload = false,
    this.documentType = '',
    this.documentUrls = const [],
    this.hasRequests = false,
  });

  // Add this method to open PDF documents
  void _openDocument(BuildContext context, String url, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PDFViewerScreen(
              pdfUrl: url,
              title: fileName.isNotEmpty ? fileName : 'Additional Document',
            ),
      ),
    );
  }

  // Add this method to show document selection if multiple documents
  void _showDocumentSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Select Document to View'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  documentUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final url = entry.value;
                    final fileName = 'Document ${index + 1}';

                    return ListTile(
                      leading: Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red[600],
                      ),
                      title: Text(fileName),
                      subtitle: Text('Tap to view'),
                      onTap: () {
                        Navigator.pop(context); // Close selection dialog
                        _openDocument(context, url, fileName);
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime =
        (context.findAncestorStateOfType<_DashboardScreenState>()?._formatTime(
              createdAt,
            ) ??
            '');
    final timeAgo =
        (context
                .findAncestorStateOfType<_DashboardScreenState>()
                ?._formatTimeDifference(createdAt) ??
            '');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.upload_file, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NEW DOCS',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  formattedTime,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (documentType.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Document Type: $documentType',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            if (documentUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, color: Colors.green[700], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${documentUrls.length} document(s) uploaded',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (documentUrls.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (documentUrls.length == 1) {
                          // If only one document, open it directly
                          final fileName = documentUrls.first.split('/').last;
                          _openDocument(context, documentUrls.first, fileName);
                        } else {
                          // If multiple documents, show selection dialog
                          _showDocumentSelectionDialog(context);
                        }
                      },
                      icon: const Icon(Icons.visibility),
                      label: Text(
                        documentUrls.length == 1
                            ? "View Document"
                            : "View Documents",
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      // Approve documents
                      final updates = <String, dynamic>{
                        'hasNewDocuments': false,
                        'documentUploadTime': null,
                        'newDocumentUrls': [],
                        'pendingDocumentType': '',
                        'lastDocumentMessage': '',
                      };

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(id)
                          .update(updates);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Documents reviewed and approved'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
