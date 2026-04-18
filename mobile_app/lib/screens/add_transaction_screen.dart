import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category_model.dart';
import '../providers/transaction_provider.dart';
import '../services/api_service.dart';
import '../utils/icon_mapping.dart';
import '../utils/currency_utils.dart';
import '../widgets/authenticated_image.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/amount_display.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

  String _type = 'expense';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  List<Category> _allCategories = [];
  List<Category> _filteredSuggestions = [];
  Category? _selectedCategory;

  Uint8List? _imageBytes;
  String? _imageFilename;
  String? _receiptImageId;

  final FocusNode _categoryFocus = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description;
      _selectedDate = widget.transaction!.date;
      _receiptImageId = widget.transaction!.receiptImageId;
      _categoryController.text = widget.transaction!.customCategory ?? widget.transaction!.category;
    }

    _loadUserCategories();
    _categoryController.addListener(_onCategoryChanged);
    _categoryFocus.addListener(_onFocusChange);
  }

  Future<void> _loadUserCategories() async {
    try {
      final result = await ApiService.getCategories();
      if (result['success'] == true) {
        final List<dynamic> catList = result['categories'] ?? [];
        setState(() {
          _allCategories = catList.map((c) => Category.fromJson(c)).toList();
          _updateFilteredSuggestions();
          
          if (widget.transaction == null && _allCategories.isNotEmpty) {
            final firstCat = _allCategories.firstWhere((c) => c.type == _type, orElse: () => _allCategories.first);
            _categoryController.text = firstCat.name;
            _selectedCategory = firstCat;
          } else if (widget.transaction != null) {
            _selectedCategory = _allCategories.firstWhere(
              (c) => c.name.toLowerCase() == _categoryController.text.toLowerCase(),
              orElse: () => Category(id: 'temp', name: _categoryController.text, icon: 'category', type: _type)
            );
          }
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  void _updateFilteredSuggestions() {
    final query = _categoryController.text.toLowerCase().trim();
    final typeFiltered = _allCategories.where((c) => c.type == _type).toList();
    
    if (query.isEmpty) {
      _filteredSuggestions = typeFiltered;
    } else {
      _filteredSuggestions = typeFiltered
          .where((cat) => cat.name.toLowerCase().contains(query))
          .toList();
    }
  }

  void _onCategoryChanged() {
    setState(() {
      _updateFilteredSuggestions();
      _selectedCategory = _allCategories.firstWhere(
        (c) => c.name.toLowerCase() == _categoryController.text.toLowerCase(),
        orElse: () => Category(id: 'temp', name: _categoryController.text, icon: 'category', type: _type)
      );
    });

    if (_categoryFocus.hasFocus) {
      _showOverlay();
    }
  }

  void _onFocusChange() {
    if (_categoryFocus.hasFocus) {
      _onCategoryChanged();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        _removeOverlay();
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    double width = renderBox?.size.width ?? 300;
    
    return OverlayEntry(
      builder: (context) => Positioned(
        width: width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            shadowColor: Colors.black.withOpacity(0.2),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  ..._filteredSuggestions.map((suggestion) => ListTile(
                    dense: true,
                    leading: Icon(
                      IconMapping.getIconData(suggestion.icon),
                      size: 20,
                      color: AppColors.primaryStart,
                    ),
                    title: Text(suggestion.name),
                    onTap: () {
                      setState(() {
                        _categoryController.text = suggestion.name;
                        _selectedCategory = suggestion;
                        _categoryController.selection = TextSelection.fromPosition(
                          TextPosition(offset: suggestion.name.length),
                        );
                      });
                      _removeOverlay();
                      _categoryFocus.unfocus();
                    },
                  )),
                  if (_categoryController.text.isNotEmpty && 
                      !_allCategories.any((c) => c.name.toLowerCase() == _categoryController.text.toLowerCase()))
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.accent),
                      title: Text('Add "${_categoryController.text}"'),
                      onTap: () {
                        _removeOverlay();
                        _categoryFocus.unfocus();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _categoryFocus.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryStart,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        
        Uint8List compressedBytes;
        try {
          final compressed = await FlutterImageCompress.compressWithList(
            bytes,
            minWidth: 1024,
            minHeight: 1024,
            quality: 70,
          );
          compressedBytes = Uint8List.fromList(compressed);
        } catch (e) {
          compressedBytes = bytes;
        }
        
        setState(() {
          _imageBytes = compressedBytes;
          _imageFilename = file.name;
          _receiptImageId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      
      String? imageId = _receiptImageId;
      if (_imageBytes != null && _imageFilename != null) {
        final uploadResult = await provider.uploadReceipt(_imageBytes!, _imageFilename!);
        if (uploadResult['success'] == true) {
          imageId = uploadResult['fileId'];
        } else {
          throw Exception(uploadResult['message'] ?? 'Upload failed');
        }
      }

      final categoryName = _categoryController.text.trim();
      final isPredefined = _selectedCategory != null && _selectedCategory!.isDefault;

      final transaction = Transaction(
        id: widget.transaction?.id,
        type: _type,
        amount: double.parse(_amountController.text),
        category: categoryName,
        customCategory: isPredefined ? null : categoryName,
        description: _descriptionController.text,
        date: _selectedDate,
        receiptImageId: imageId,
      );

      Map<String, dynamic> result;
      if (widget.transaction != null) {
        result = await provider.updateTransaction(widget.transaction!.id!, transaction.toJson());
      } else {
        result = await provider.createTransaction(transaction);
      }

      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: AppSpacing.s),
                Text(widget.transaction != null ? 'Transaction updated successfully' : 'Transaction added successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: Text(result['message'] ?? 'Error occurred')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: Text('Failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.transaction != null ? 'Edit Transaction' : 'New Transaction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Set Amount",
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              CurrencyUtils.symbol,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _type == 'expense' ? AppColors.expense : AppColors.income,
                              ),
                            ),
                            Flexible(
                              child: IntrinsicWidth(
                                child: TextFormField(
                                  controller: _amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: _type == 'expense' ? AppColors.expense : AppColors.income,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "0.00",
                                    hintStyle: TextStyle(color: Colors.black12, fontSize: 32),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Enter amount';
                                    if (double.tryParse(val) == null) return 'Invalid number';
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 150,
                          height: 2,
                          color: _type == 'expense' ? AppColors.expense.withOpacity(0.3) : AppColors.income.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                    ),
                    child: Row(
                      children: [
                        _buildTypeOption('expense', 'Expense', Icons.arrow_outward),
                        _buildTypeOption('income', 'Income', Icons.arrow_downward),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const Text(
                    "Category",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  CompositedTransformTarget(
                    link: _layerLink,
                    child: TextFormField(
                      controller: _categoryController,
                      focusNode: _categoryFocus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: "What was this for?",
                        prefixIcon: Icon(
                          IconMapping.getIconData(_selectedCategory?.icon ?? 'category'),
                          color: AppColors.primaryStart,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                      ),
                      validator: (val) => (val == null || val.isEmpty) ? 'Select category' : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: "Add details (optional)",
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.s),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickImage(ImageSource.gallery),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.s),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.medium),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _imageBytes != null || _receiptImageId != null ? Icons.check_circle : Icons.camera_alt_outlined,
                                  size: 18,
                                  color: _imageBytes != null || _receiptImageId != null ? AppColors.success : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _imageBytes != null || _receiptImageId != null ? "Receipt Added" : "Add Receipt",
                                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  if (_imageBytes != null || _receiptImageId != null)
                    _buildReceiptPreview(),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: widget.transaction != null ? 'Update Transaction' : 'Save Transaction',
                    onPressed: _saveTransaction,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  SecondaryButton(
                    label: "Cancel",
                    fullWidth: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String type, String label, IconData icon) {
    bool isSelected = _type == type;
    Color activeColor = type == 'expense' ? AppColors.expense : AppColors.income;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _updateFilteredSuggestions();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: isSelected ? AppShadows.small : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? activeColor : AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? activeColor : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Receipt Preview", style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => setState(() { _imageBytes = null; _receiptImageId = null; }),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: _imageBytes != null 
            ? Image.memory(_imageBytes!, height: 150, width: double.infinity, fit: BoxFit.cover)
            : AuthenticatedImage(
                imageId: _receiptImageId!, 
                height: 150, 
                width: double.infinity, 
                borderRadius: BorderRadius.circular(AppRadius.medium)
              ),
        ),
      ],
    );
  }
}
