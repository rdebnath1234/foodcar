import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:foodcar/editprofile.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String? _gender;
  String? profileImageUrl;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .get();

    final authPhone = _currentUser.phoneNumber ?? '';

    if (doc.exists) {
      final data = doc.data() ?? {};
      setState(() {
        profileImageUrl = data['profileImage'];
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = authPhone; // always from FirebaseAuth
        _addressController.text = data['address'] ?? '';
        _gender = data['gender'];
      });
    } else {
      _phoneController.text = authPhone;
    }
  }

  Future<void> _pickProfileImage() async {
    final selectedImage = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfile()),
    );

    if (selectedImage != null && mounted) {
      String imageUrl = selectedImage;

      if (Uri.tryParse(selectedImage)?.isAbsolute ?? false) {
        // Already a URL
        imageUrl = selectedImage;
      } else if (File(selectedImage).existsSync()) {
        // Local file -> upload to Firebase Storage
        final file = File(selectedImage);
        final ref = FirebaseStorage.instance
            .ref('profile_images/${_currentUser!.uid}.jpg');
        await ref.putFile(file);
        imageUrl = await ref.getDownloadURL();
      }

      setState(() {
        profileImageUrl = imageUrl;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_currentUser == null) return;

    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .set({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'gender': _gender,
      'profileImage': profileImageUrl,
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _pickProfileImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'User Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 10),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter your email";
                  }
                  if (!value.contains('@')) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Locked phone number
              TextFormField(
                controller: _phoneController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  suffixIcon: Icon(Icons.lock, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 20),

              // Gender Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gender:'),
                  Radio<String>(
                    value: 'Male',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() => _gender = value);
                    },
                  ),
                  const Text('Male'),
                  Radio<String>(
                    value: 'Female',
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() => _gender = value);
                    },
                  ),
                  const Text('Female'),
                ],
              ),
              const SizedBox(height: 20),

              // Save button full width
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
