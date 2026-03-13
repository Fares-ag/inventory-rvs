import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider_firebase.dart' as firebase_auth;

class UserFormScreen extends StatefulWidget {
  final User? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _fullNameController;
  UserRole _selectedRole = UserRole.viewer;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _fullNameController = TextEditingController(text: widget.user?.fullName ?? '');
    _selectedRole = widget.user?.role ?? UserRole.viewer;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = User(
      id: widget.user?.id,
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      passwordHash: _passwordController.text.isEmpty
          ? widget.user!.passwordHash
          : _passwordController.text, // In production, hash this
      role: _selectedRole,
      fullName: _fullNameController.text.trim().isEmpty
          ? null
          : _fullNameController.text.trim(),
      createdAt: widget.user?.createdAt,
    );

    final authProvider = Provider.of<firebase_auth.AuthProvider>(context, listen: false);
    final success = widget.user == null
        ? await authProvider.createUser(user)
        : await authProvider.updateUser(user);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.user == null ? 'User created' : 'User updated'),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username *',
                  border: OutlineInputBorder(),
                ),
                enabled: widget.user == null,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: widget.user == null ? 'Password *' : 'New Password (leave empty to keep current)',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (widget.user == null && (value == null || value.isEmpty)) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role *',
                  border: OutlineInputBorder(),
                ),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save User'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


