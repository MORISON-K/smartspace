import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String name;
  final String email;
  final String role;
  final String status;

  User({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });
}

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedRole;
  String? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String role = 'User';
    String status = 'Active';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Add New User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    items:
                        ['User', 'Seller', 'Admin']
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => role = value);
                    },
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    items:
                        ['Active', 'Disabled']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => status = value);
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();

                  if (name.isNotEmpty && isValidEmail(email)) {
                    await FirebaseFirestore.instance.collection('users').add({
                      'name': name,
                      'email': email,
                      'role': role,
                      'status': status,
                    });

                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid name and email'),
                      ),
                    );
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditUserDialog(String docId, User user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    String role = user.role;
    String status = user.status;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Edit ${user.name}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    items:
                        ['User', 'Seller', 'Admin']
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) role = value;
                    },
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    items:
                        ['Active', 'Disabled']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) status = value;
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();

                  if (name.isNotEmpty && isValidEmail(email)) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(docId)
                        .update({
                          'name': name,
                          'email': email,
                          'role': role,
                          'status': status,
                        });

                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid name and email'),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _deleteUser(String docId) {
    FirebaseFirestore.instance.collection('users').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    hint: const Text('Filter by Role'),
                    items:
                        ['User', 'Seller', 'Admin']
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                      });
                    },
                  ),
                ),
                DropdownButton<String>(
                  value: _selectedStatus,
                  hint: const Text('Filter by Status'),
                  items:
                      ['Active', 'Disabled']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedRole = null;
                      _selectedStatus = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Filters',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found."));
                }

                final docs = snapshot.data!.docs;
                final filteredDocs =
                    docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name']?.toLowerCase() ?? '';
                      final email = data['email']?.toLowerCase() ?? '';
                      final role = data['role']?.toLowerCase() ?? '';
                      final status = data['status']?.toLowerCase() ?? '';

                      final matchesSearchQuery =
                          name.contains(_searchQuery) ||
                          email.contains(_searchQuery);
                      final matchesRole =
                          _selectedRole == null ||
                          role == _selectedRole!.toLowerCase();
                      final matchesStatus =
                          _selectedStatus == null ||
                          status == _selectedStatus!.toLowerCase();

                      return matchesSearchQuery && matchesRole && matchesStatus;
                    }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,

                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final user = User(
                      name: data['name'] ?? '',
                      email: data['email'] ?? '',
                      role: data['role'] ?? '',
                      status: data['status'] ?? '',
                    );

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.email),
                          Text(
                            'Role: ${user.role}  •  Status: ${user.status}',
                            style: TextStyle(
                              color:
                                  user.status == 'Active'
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditUserDialog(doc.id, user),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteUser(doc.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }
}
