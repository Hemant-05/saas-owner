import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
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
  late TextEditingController _gstCtrl;
  late TextEditingController _addressCtrl;
  late String _businessType;
  late bool _isAcceptingOrders;
  XFile? _newLogo;
  Uint8List? _newLogoBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final restaurant = context.read<AuthProvider>().restaurant;
    _nameCtrl = TextEditingController(text: restaurant?.name ?? '');
    _phoneCtrl = TextEditingController(text: restaurant?.phone ?? '');
    _gstCtrl = TextEditingController(text: restaurant?.gstNumber ?? '');
    _addressCtrl = TextEditingController(text: restaurant?.address ?? '');
    _businessType = restaurant?.businessType ?? 'cafe_restaurant';
    _isAcceptingOrders = restaurant?.isAcceptingOrders ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _gstCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newLogo = picked;
        _newLogoBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      gstNumber: _gstCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      businessType: _businessType,
      isAcceptingOrders: _isAcceptingOrders,
      logoBytes: _newLogoBytes,
      logoName: _newLogo?.name,
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
    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context, rootNavigator: true);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: AppColors.textSecondaryLight)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondaryLight)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4757)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await authProvider.logout();
      navigator.pushAndRemoveUntil(
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
      backgroundColor: AppColors.backgroundLight,
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
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  if (!_isEditing)
                    GestureDetector(
                      onTap: () => setState(() => _isEditing = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF6B35).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_rounded,
                                color: Color(0xFFFF6B35), size: 16),
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
                        border: Border.all(
                            color: const Color(0xFFFF6B35), width: 3),
                      ),
                      child: ClipOval(
                        child: _newLogoBytes != null
                            ? Image.memory(_newLogoBytes!, fit: BoxFit.cover)
                            : (restaurant?.logoUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: restaurant!.logoUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        _avatarPlaceholder(restaurant),
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
                    color: AppColors.textPrimaryLight,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  restaurant?.email ?? '',
                  style: const TextStyle(
                      color: AppColors.textSecondaryLight, fontSize: 14),
                ),
              ],
              const SizedBox(height: 24),
              // Info / Edit form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: _isEditing
                    ? Column(
                        children: [
                          _editField('Restaurant Name', _nameCtrl,
                              Icons.store_rounded),
                          const SizedBox(height: 14),
                          _editField('Phone', _phoneCtrl, Icons.phone_outlined,
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 14),
                          _editField('GST Number', _gstCtrl,
                              Icons.receipt_long_outlined),
                          const SizedBox(height: 14),
                          _businessTypeSelector(),
                          const SizedBox(height: 14),
                          _availabilitySwitch(),
                          const SizedBox(height: 14),
                          _editField('Address', _addressCtrl,
                              Icons.location_on_outlined,
                              maxLines: 2),
                        ],
                      )
                    : Column(
                        children: [
                          _profileRow(Icons.store_rounded, 'Restaurant',
                              restaurant?.name ?? ''),
                          const Divider(
                              color: AppColors.borderLight, height: 20),
                          _profileRow(Icons.email_outlined, 'Email',
                              restaurant?.email ?? ''),
                          const Divider(
                              color: AppColors.borderLight, height: 20),
                          _profileRow(Icons.phone_outlined, 'Phone',
                              restaurant?.phone ?? ''),
                          if (restaurant?.gstNumber != null &&
                              restaurant!.gstNumber!.isNotEmpty) ...[
                            const Divider(
                                color: AppColors.borderLight, height: 20),
                            _profileRow(Icons.receipt_long_outlined, 'GST',
                                restaurant.gstNumber!),
                          ],
                          const Divider(
                              color: AppColors.borderLight, height: 20),
                          _profileRow(
                            restaurant?.isAcceptingOrders == true
                                ? Icons.wifi_rounded
                                : Icons.wifi_off_rounded,
                            'Orders',
                            restaurant?.isAcceptingOrders == true
                                ? 'Online and accepting orders'
                                : 'Offline',
                          ),
                          const Divider(
                              color: AppColors.borderLight, height: 20),
                          _profileRow(
                            restaurant?.isFoodTruck == true
                                ? Icons.local_shipping_rounded
                                : Icons.storefront_rounded,
                            'Mode',
                            restaurant?.isFoodTruck == true
                                ? 'Food truck'
                                : 'Restaurant',
                          ),
                          if (restaurant?.address != null &&
                              restaurant!.address!.isNotEmpty) ...[
                            const Divider(
                                color: AppColors.borderLight, height: 20),
                            _profileRow(Icons.location_on_outlined, 'Address',
                                restaurant.address!),
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
                          foregroundColor: AppColors.textSecondaryLight,
                          side: const BorderSide(color: AppColors.borderLight),
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
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
        color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
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
                  style: const TextStyle(
                      color: AppColors.textMutedLight, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimaryLight,
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
        style: const TextStyle(color: AppColors.textPrimaryLight),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
          prefixIcon: Icon(icon, color: AppColors.textSecondaryLight, size: 18),
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
          ),
        ),
      );

  Widget _businessTypeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'cafe_restaurant',
          icon: Icon(Icons.storefront_rounded),
          label: Text('Restaurant'),
        ),
        ButtonSegment(
          value: 'food_truck',
          icon: Icon(Icons.local_shipping_rounded),
          label: Text('Food truck'),
        ),
      ],
      selected: {_businessType},
      onSelectionChanged: (value) {
        setState(() => _businessType = value.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surfaceLight,
        ),
      ),
    );
  }

  Widget _availabilitySwitch() {
    return SwitchListTile(
      value: _isAcceptingOrders,
      onChanged: (value) => setState(() => _isAcceptingOrders = value),
      title: const Text(
        'Accepting orders',
        style: TextStyle(
          color: AppColors.textPrimaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _isAcceptingOrders
            ? 'Customers can place new orders'
            : 'New orders are paused until you go online',
        style: const TextStyle(color: AppColors.textSecondaryLight),
      ),
      secondary: Icon(
        _isAcceptingOrders ? Icons.wifi_rounded : Icons.wifi_off_rounded,
        color: _isAcceptingOrders ? AppColors.success : AppColors.warning,
      ),
      activeThumbColor: AppColors.success,
      contentPadding: EdgeInsets.zero,
    );
  }
}
