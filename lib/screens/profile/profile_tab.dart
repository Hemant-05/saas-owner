import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isEditing = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  File? _newLogo;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final restaurant = context.read<AuthProvider>().restaurant;
    _nameCtrl = TextEditingController(text: restaurant?.name ?? '');
    _phoneCtrl = TextEditingController(text: restaurant?.phone ?? '');
    _addressCtrl = TextEditingController(text: restaurant?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _newLogo = File(picked.path));
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      logo: _newLogo,
    );
    setState(() {
      _isSaving = false;
      if (success) _isEditing = false;
    });
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: Color(0xFF06D6A0),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Update failed'),
          backgroundColor: const Color(0xFFFF4757),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4757)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final restaurant = auth.restaurant;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (!_isEditing)
                    GestureDetector(
                      onTap: () => setState(() => _isEditing = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded, color: Color(0xFFFF6B35), size: 16),
                            SizedBox(width: 6),
                            Text('Edit',
                                style: TextStyle(
                                    color: Color(0xFFFF6B35),
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // Avatar
              GestureDetector(
                onTap: _isEditing ? _pickLogo : null,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF6B35), width: 3),
                      ),
                      child: ClipOval(
                        child: _newLogo != null
                            ? Image.file(_newLogo!, fit: BoxFit.cover)
                            : (restaurant?.logoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: restaurant!.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _avatarPlaceholder(restaurant),
                                  )
                                : _avatarPlaceholder(restaurant)),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (!_isEditing) ...[
                Text(
                  restaurant?.name ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  restaurant?.email ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              // Info / Edit form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: _isEditing
                    ? Column(
                        children: [
                          _editField('Restaurant Name', _nameCtrl, Icons.store_rounded),
                          const SizedBox(height: 14),
                          _editField('Phone', _phoneCtrl, Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 14),
                          _editField('Address', _addressCtrl, Icons.location_on_outlined,
                              maxLines: 2),
                        ],
                      )
                    : Column(
                        children: [
                          _profileRow(Icons.store_rounded, 'Restaurant', restaurant?.name ?? ''),
                          const Divider(color: Colors.white10, height: 20),
                          _profileRow(Icons.email_outlined, 'Email', restaurant?.email ?? ''),
                          const Divider(color: Colors.white10, height: 20),
                          _profileRow(Icons.phone_outlined, 'Phone', restaurant?.phone ?? ''),
                          if (restaurant?.address != null &&
                              restaurant!.address!.isNotEmpty) ...[
                            const Divider(color: Colors.white10, height: 20),
                            _profileRow(
                                Icons.location_on_outlined, 'Address', restaurant.address!),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _isEditing = false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: BorderSide(color: Colors.white.withOpacity(0.15)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Save',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF4757),
                      side: const BorderSide(color: Color(0xFFFF4757)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(restaurant) => Container(
        color: const Color(0xFFFF6B35).withOpacity(0.15),
        child: Center(
          child: Text(
            (restaurant?.name ?? 'R').substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFFF6B35),
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

  Widget _profileRow(IconData icon, String label, String value) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF6B35), size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      );

  Widget _editField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white38, size: 18),
          filled: true,
          fillColor: Colors.white.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
          ),
        ),
      );
}
