import 'package:flutter/material.dart';

class AdminUser {
  final String name;
  final String email;
  final String role;
  final String status;

  AdminUser({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });
}

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {

  bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}



  void _showAddAdminDialog() {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  String role = 'Editor';
  String status = 'Active';

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Add New Admin'),
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
              items: ['Super Admin', 'Editor', 'Viewer']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => role = value);
              },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            DropdownButtonFormField<String>(
              value: status,
              items: ['Active', 'Disabled']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
          onPressed: () {
  final name = nameController.text.trim();
  final email = emailController.text.trim();

  if (name.isEmpty || email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
    return;
  }

  if (!isValidEmail(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid email address')),
    );
    return;
  }

  setState(() {
    admins.add(AdminUser(
      name: name,
      email: email,
      role: role,
      status: status,
    ));
  });
  Navigator.pop(context);
},

          child: const Text('Add'),
        ),
      ],
    ),
  );
}

  List<AdminUser> admins = [
    AdminUser(
      name: 'Serena Rob',
      email: 'serena@example.com',
      role: 'Super Admin',
      status: 'Active',
    ),
    AdminUser(
      name: 'Dan M.',
      email: 'dan@example.com',
      role: 'Editor',
      status: 'Disabled',
    ),
  ];

  void _showEditDialog(AdminUser admin) {
  final nameController = TextEditingController(text: admin.name);
  final emailController = TextEditingController(text: admin.email);
  String role = admin.role;
  String status = admin.status;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Edit ${admin.name}'),
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
              items: ['Super Admin', 'Editor', 'Viewer']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (value) {
                if (value != null) role = value;
              },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            DropdownButtonFormField<String>(
              value: status,
              items: ['Active', 'Disabled']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
          onPressed: () {
            final name = nameController.text.trim();
            final email = emailController.text.trim();

            if (name.isEmpty || email.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please fill in all fields')),
  );
  return;
}

if (!isValidEmail(email)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Please enter a valid email address')),
  );
  return;
}

              setState(() {
                final index = admins.indexOf(admin);
                admins[index] = AdminUser(
                  name: name,
                  email: email,
                  role: role,
                  status: status,
                );
              });
              Navigator.pop(context);
            
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}


  void _deleteAdmin(AdminUser admin) {
    setState(() {
      admins.remove(admin);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Admins')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: admins.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final admin = admins[index];
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
            title: Text(admin.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(admin.email),
                Text(
                  'Role: ${admin.role}  •  Status: ${admin.status}',
                  style: TextStyle(
                    color: admin.status == 'Active' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(admin),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAdmin(admin),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAdminDialog,

        icon: const Icon(Icons.person_add),
        label: const Text('Add Admin'),
      ),
    );
  }
}
