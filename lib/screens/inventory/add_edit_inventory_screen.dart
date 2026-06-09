import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_models.dart';
import '../../providers/inventory_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class AddEditInventoryScreen extends StatefulWidget {
  final InventoryItem? item; // null = add mode

  const AddEditInventoryScreen({super.key, this.item});

  @override
  State<AddEditInventoryScreen> createState() => _AddEditInventoryScreenState();
}

class _AddEditInventoryScreenState extends State<AddEditInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _costController = TextEditingController();
  final _customUnitController = TextEditingController();

  String _selectedUnit = 'kg';
  bool _isCustomUnit = false;
  XFile? _imageFile;
  Uint8List? _imagePreviewBytes;
  bool _isLoading = false;

  bool get _isEdit => widget.item != null;

  static const List<String> _units = [
    'kg',
    'grams',
    'litre',
    'ml',
    'pieces',
    'packets',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final item = widget.item!;
      _nameController.text = item.name;
      _thresholdController.text = item.lowStockThreshold
          .toStringAsFixed(item.lowStockThreshold % 1 == 0 ? 0 : 1);
      _costController.text = item.costPerUnit != null
          ? item.costPerUnit!.toStringAsFixed(2)
          : '';

      if (_units.contains(item.unit)) {
        _selectedUnit = item.unit;
      } else {
        _selectedUnit = 'Custom';
        _isCustomUnit = true;
        _customUnitController.text = item.unit;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _costController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imagePreviewBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<InventoryProvider>();
    final unit =
        _isCustomUnit ? _customUnitController.text.trim() : _selectedUnit;

    String? error;
    if (_isEdit) {
      error = await provider.updateItem(
        itemId: widget.item!.id,
        name: _nameController.text.trim(),
        unit: unit,
        lowStockThreshold: double.tryParse(_thresholdController.text) ?? 10,
        costPerUnit: _costController.text.isNotEmpty
            ? double.tryParse(_costController.text)
            : null,
        imageFile: _imageFile,
      );
    } else {
      error = await provider.createItem(
        name: _nameController.text.trim(),
        unit: unit,
        currentStock: double.tryParse(_stockController.text) ?? 0,
        lowStockThreshold: double.tryParse(_thresholdController.text) ?? 10,
        costPerUnit: _costController.text.isNotEmpty
            ? double.tryParse(_costController.text)
            : null,
        imageFile: _imageFile,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      SnackBarHelper.showError(context, error);
    } else {
      SnackBarHelper.showSuccess(
        context,
        _isEdit ? '${_nameController.text} updated!' : '${_nameController.text} added!',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Item' : 'Add Inventory Item'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image picker
                _buildImagePicker(),
                const SizedBox(height: AppSpacing.lg),

                // Item name
                AppTextField(
                  label: 'Item Name *',
                  hint: 'e.g. Onion, Cooking Oil',
                  controller: _nameController,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // Unit selector
                const Text('Unit *', style: AppTextStyles.bodyM),
                const SizedBox(height: AppSpacing.sm),
                _buildUnitSelector(),
                if (_isCustomUnit) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'Custom Unit',
                    hint: 'e.g. boxes, cans',
                    controller: _customUnitController,
                    validator: (v) => _isCustomUnit && (v == null || v.trim().isEmpty)
                        ? 'Custom unit is required'
                        : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // Initial stock (add mode only)
                if (!_isEdit) ...[
                  AppTextField(
                    label: 'Current Stock *',
                    hint: '0',
                    controller: _stockController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Stock is required';
                      if (double.tryParse(v) == null || double.parse(v) < 0) {
                        return 'Enter a valid positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Low stock threshold
                AppTextField(
                  label: 'Low Stock Threshold *',
                  hint: '10',
                  controller: _thresholdController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Threshold is required';
                    if (double.tryParse(v) == null || double.parse(v) < 0) {
                      return 'Enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '⚠ We\'ll alert you when stock falls below this amount',
                  style:
                      AppTextStyles.bodyS.copyWith(color: AppColors.warning),
                ),
                const SizedBox(height: AppSpacing.md),

                // Cost per unit (optional)
                AppTextField(
                  label: 'Cost per Unit (optional)',
                  hint: 'e.g. 45.00',
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Save button
                AppButton(
                  label: _isEdit ? 'Update Item' : 'Add to Inventory',
                  onPressed: _save,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  icon: _isEdit ? Icons.check_rounded : Icons.add_rounded,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderLarge,
          border: Border.all(
            color: _imageFile != null ? AppColors.accent : AppColors.border,
            style: _imageFile == null ? BorderStyle.solid : BorderStyle.solid,
            width: _imageFile != null ? 1.5 : 0.5,
          ),
        ),
        child: _imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: AppRadius.borderLarge,
                    child: Image.memory(
                      _imagePreviewBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              )
            : widget.item?.imageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.borderLarge,
                        child: Image.network(
                          widget.item!.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildImagePlaceholder(),
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  )
                : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_rounded,
            color: AppColors.textMuted, size: 40),
        const SizedBox(height: AppSpacing.sm),
        Text('Tap to add photo',
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildUnitSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _units.map((unit) {
        final isSelected = _selectedUnit == unit;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedUnit = unit;
              _isCustomUnit = unit == 'Custom';
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surface,
              borderRadius: AppRadius.borderFull,
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              unit,
              style: AppTextStyles.labelS.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
