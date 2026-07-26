import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/product_cubit.dart';
import '../widgets/categories_widget.dart';
import '../widgets/location_search_dialog.dart';
import '../../../../core/services/local_ai_service.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  double? _selectedLatitude;
  double? _selectedLongitude;

  final LocalAIService _aiService = NativeGemmaService(); // Using the native MethodChannel implementation!
  bool _isAiLoading = false;
  bool _isAiInitialized = false;

  @override
  void initState() {
    super.initState();
    _initAIService();
  }

  Future<void> _initAIService() async {
    // Note: mediapipe_genai requires an absolute file path. 
    // Once you place the model in assets/models/gemma.task, 
    // you would typically copy it to getApplicationDocumentsDirectory() here, 
    // and pass the absolute path to initialize().
    // We pass the filename of the model inside assets/models/
    await _aiService.initialize('gemma-2b-it-gpu-int4.bin');
    if (mounted) {
      setState(() {
        _isAiInitialized = true;
      });
    }
  }

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _categories = CategoriesWidget.categories
      .map((c) => c['name'] as String)
      .toList();
  late String _selectedCategory = _categories.first;

  final List<int> _durations = [1, 6, 12, 24, 48, 72];
  int _selectedDuration = 24;

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one image.'),
            backgroundColor: Color(0xFF0F4C3A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthAuthenticated) return;
      final sellerId = authState.user.uid;

      setState(() {
        _isLoading = true;
      });

      final success = await context.read<ProductCubit>().createProduct(
        sellerId: sellerId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        categoryString: _selectedCategory.toUpperCase(),
        imageFiles: _selectedImages.map((e) => File(e.path)).toList(),
        durationInHours: _selectedDuration,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          setState(() {
            _selectedImages.clear();
            _titleController.clear();
            _descriptionController.clear();
            _locationController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing created successfully! 🎉'),
              backgroundColor: Color(0xFF0F4C3A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create listing. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _generateWithAI() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title first to use AI generation.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isAiLoading = true;
    });

    try {
      final result = await _aiService.generateListingDetails(title);
      if (mounted) {
        setState(() {
          _descriptionController.text = result.description;
          if (_categories.contains(result.category)) {
            _selectedCategory = result.category;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ AI successfully generated the description!'),
            backgroundColor: Color(0xFF0F4C3A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate with AI. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1C1E),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Semantics(
            label: label,
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              readOnly: readOnly,
              onTap: onTap,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF8B8B8B),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF8B8B8B)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: const Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1C1E),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Semantics(
            label: 'Category',
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF8B8B8B),
              ),
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.category_outlined,
                  color: Color(0xFF8B8B8B),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: const Text(
            'Raffle Duration (Hours)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1C1E),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Semantics(
            label: 'Raffle Duration in Hours',
            child: DropdownButtonFormField<int>(
              value: _selectedDuration,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF8B8B8B),
              ),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.timer_outlined, color: Color(0xFF8B8B8B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              items: _durations.map((int duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text('$duration Hours'),
                );
              }).toList(),
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDuration = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      body: SafeArea(
        child: SingleChildScrollView(
          primary: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CUSTOM HEADER
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: const [
                    Text(
                      'Create Listing',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F4C3A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // PHOTO UPLOAD AREA
                      const Text(
                        'Photos',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        button: true,
                        label: 'Add photos',
                        child: GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EBE9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Color(0xFF0F4C3A),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Tap to add photos',
                                  style: TextStyle(
                                    color: Color(0xFF0F4C3A),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add up to 5 photos',
                                  style: TextStyle(
                                    color: Color(0xFF5A5A5A),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SELECTED IMAGES GALLERY
                      if (_selectedImages.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      image: DecorationImage(
                                        image: FileImage(
                                          File(_selectedImages[index].path),
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 18,
                                    child: Semantics(
                                      button: true,
                                      label: 'Remove photo ${index + 1}',
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF1A1C1E),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      if (_selectedImages.isNotEmpty)
                        const SizedBox(height: 24),
                      if (_selectedImages.isEmpty) const SizedBox(height: 8),

                      // INPUT FIELDS
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title',
                        hint: 'What are you giving away?',
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: (_isAiLoading || !_isAiInitialized) ? null : _generateWithAI,
                          icon: _isAiLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome, color: Color(0xFF0F4C3A)),
                          label: Text(
                            _isAiLoading 
                                ? 'Generating...' 
                                : (!_isAiInitialized ? 'Loading AI...' : 'Auto-Complete with AI'),
                            style: const TextStyle(
                              color: Color(0xFF0F4C3A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE8F4F8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Describe the item condition, history, etc.',
                        icon: Icons.description_outlined,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),

                      _buildTextField(
                        controller: _locationController,
                        label: 'Location',
                        hint: 'Where can they pick it up?',
                        icon: Icons.location_on_outlined,
                        readOnly: true,
                        onTap: () async {
                          final result = await showDialog<LocationResult>(
                            context: context,
                            builder: (context) => const LocationSearchDialog(),
                          );
                          if (result != null) {
                            setState(() {
                              _locationController.text = result.displayName;
                              _selectedLatitude = result.latitude;
                              _selectedLongitude = result.longitude;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      _buildCategoryDropdown(),
                      const SizedBox(height: 24),

                      _buildDurationDropdown(),
                      const SizedBox(height: 40),

                      // SUBMIT BUTTON
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C3A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Post Listing',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
