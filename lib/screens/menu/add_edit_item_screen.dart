import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import '../../providers/menu_provider.dart';
import '../../models/models.dart';

const List<String> kCategories = [
  'Beverages',
  'Starters',
  'Main Course',
  'Desserts',
  'Snacks',
  'Breads',
  'Soups & Salads',
  'Custom',
];

/// Standalone screen (used on mobile via Navigator.push)
class AddEditItemScreen extends StatelessWidget {
  final MenuItem? item;
  const AddEditItemScreen({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          item != null ? 'Edit Item' : 'Add Menu Item',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.06)),
        ),
      ),
      body: AddEditItemPanel(
        item: item,
        onSaved: () => Navigator.pop(context),
        onDeleted: () => Navigator.pop(context),
      ),
    );
  }
}

/// Embeddable panel (used in the desktop split panel)
class AddEditItemPanel extends StatefulWidget {
  final MenuItem? item;
  final VoidCallback? onSaved;
  final VoidCallback? onDeleted;

  const AddEditItemPanel({
    super.key,
    this.item,
    this.onSaved,
    this.onDeleted,
  });

  @override
  State<AddEditItemPanel> createState() => _AddEditItemPanelState();
}

class _AddEditItemPanelState extends State<AddEditItemPanel> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _customCategoryCtrl;
  String _selectedCategory = kCategories.first;
  bool _isVeg = true;
  bool _isAvailable = true;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(AddEditItemPanel old) {
    super.didUpdateWidget(old);
    if (old.item?.id != widget.item?.id) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _descCtrl = TextEditingController(text: item?.description ?? '');
    _priceCtrl = TextEditingController(text: item?.price.toString() ?? '');
    _customCategoryCtrl = TextEditingController();
    _imageBytes = null;
    _imageName = null;
    if (item != null) {
      _selectedCategory = kCategories.contains(item.category) ? item.category : 'Custom';
      if (_selectedCategory == 'Custom') {
        _customCategoryCtrl.text = item.category;
      }
      _isVeg = item.isVeg;
      _isAvailable = item.isAvailable;
    } else {
      _selectedCategory = kCategories.first;
      _isVeg = true;
      _isAvailable = true;
    }
  }

  void _disposeControllers() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _customCategoryCtrl.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
      });
    }
  }

  String get _finalCategory =>
      _selectedCategory == 'Custom'
          ? _customCategoryCtrl.text.trim()
          : _selectedCategory;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_finalCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final menuProv = context.read<MenuProvider>();
    bool success;

    if (isEditing) {
      success = await menuProv.updateItem(
        widget.item!.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim()),
        category: _finalCategory,
        isVeg: _isVeg,
        isAvailable: _isAvailable,
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
    } else {
      final result = await menuProv.addItem(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        price: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        category: _finalCategory,
        isVeg: _isVeg,
        isAvailable: _isAvailable,
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      success = result != null;
    }

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Item updated!' : 'Item added!'),
          backgroundColor: const Color(0xFF06D6A0),
        ),
      );
      widget.onSaved?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(menuProv.errorMessage ?? 'Failed to save item'),
          backgroundColor: const Color(0xFFFF4757),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Delete Item',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${widget.item!.name}" from the menu?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4757)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<MenuProvider>().deleteItem(widget.item!.id);
      if (mounted) widget.onDeleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : (widget.item?.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.item!.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _imgPlaceholder(),
                            )
                          : _imgPlaceholder()),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _label('Item Name'),
            _textField(_nameCtrl, 'e.g., Masala Chai',
                validator: (v) => v!.isEmpty ? 'Name is required' : null),
            const SizedBox(height: 14),
            _label('Description'),
            _textField(_descCtrl, 'Brief description...', maxLines: 2),
            const SizedBox(height: 14),
            _label('Price (₹)'),
            _textField(
              _priceCtrl,
              'e.g., 120',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v!.isEmpty) return 'Price is required';
                if (double.tryParse(v) == null || double.parse(v) < 0) {
                  return 'Enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _label('Category'),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: const Color(0xFF1A1A2E),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Select category'),
              items: kCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            if (_selectedCategory == 'Custom') ...[
              const SizedBox(height: 10),
              _textField(_customCategoryCtrl, 'Enter custom category name'),
            ],
            const SizedBox(height: 18),
            _toggleRow('Vegetarian', _isVeg, const Color(0xFF06D6A0),
                (val) => setState(() => _isVeg = val)),
            const SizedBox(height: 10),
            _toggleRow('Available on Menu', _isAvailable, const Color(0xFFFF6B35),
                (val) => setState(() => _isAvailable = val)),
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        isEditing ? 'Save Changes' : 'Add to Menu',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Delete Item'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF4757),
                    side: const BorderSide(color: Color(0xFFFF4757)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_rounded,
              size: 36, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text('Tap to add photo',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
        ],
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _textField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(hint),
        validator: validator,
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFFF4757), width: 1.5),
        ),
      );

  Widget _toggleRow(
          String label, bool value, Color color, ValueChanged<bool> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: value ? color : Colors.white24,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
              activeTrackColor: color.withOpacity(0.3),
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: Colors.white12,
            ),
          ],
        ),
      );
}
