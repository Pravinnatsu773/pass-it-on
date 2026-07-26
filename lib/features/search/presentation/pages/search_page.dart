import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../home/presentation/cubit/product_cubit.dart';
import '../../../home/presentation/cubit/product_state.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../../home/presentation/widgets/categories_widget.dart';
import '../../../home/presentation/pages/product_detail_page.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/map_utils.dart';

class SearchPage extends StatefulWidget {
  final bool isActive;
  const SearchPage({super.key, this.isActive = false});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Position? _currentPosition;
  String? _selectedCategory;

  // Removed dummy _products list

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    _fetchPosition();
  }

  Future<void> _fetchPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  String _formatLocation(String rawLocation) {
    if (rawLocation.trim().isEmpty) return rawLocation;
    final parts = rawLocation.split(',');
    if (parts.length >= 3) {
      return parts[1].trim();
    }
    return parts[0].trim();
  }

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _searchFocusNode.requestFocus();
    } else if (!widget.isActive && oldWidget.isActive) {
      _searchFocusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH HEADER
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Semantics(
                  label: 'Search items',
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Search items in your community...',
                      hintStyle: TextStyle(color: Color(0xFF8B8B8B), fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF8B8B8B)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {});
                      context.read<ProductCubit>().search(
                        value,
                        category: _selectedCategory,
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // CATEGORIES
            Padding(
              padding: const EdgeInsets.only(left: 24.0),
              child: CategoriesWidget(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    if (_selectedCategory == category) {
                      _selectedCategory = null; // Toggle off
                    } else {
                      _selectedCategory = category;
                    }
                  });
                  context.read<ProductCubit>().search(
                    _searchController.text,
                    category: _selectedCategory,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // RESULTS LIST
            Expanded(
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        (_searchController.text.isEmpty && _selectedCategory == null) ? 'Latest Added' : 'Search Results',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<ProductCubit, ProductState>(
                      builder: (context, productState) {
                        if (productState is ProductLoaded) {
                          List<ProductModel> results = (_searchController.text.isEmpty && _selectedCategory == null)
                              ? productState.feedProducts.take(10).toList()
                              : productState.searchResults;
                              
                          // Sort by distance
                          if (_currentPosition != null && results.isNotEmpty) {
                            results = List.from(results); // Make mutable
                            results.sort((a, b) {
                              if (a.latitude == null && b.latitude == null) return 0;
                              if (a.latitude == null) return 1;
                              if (b.latitude == null) return -1;
                              
                              final distA = Geolocator.distanceBetween(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                                a.latitude!,
                                a.longitude!,
                              );
                              final distB = Geolocator.distanceBetween(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                                b.latitude!,
                                b.longitude!,
                              );
                              return distA.compareTo(distB);
                            });
                          }
                          
                          if (results.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('No results found.'),
                              ),
                            );
                          }
                          
                          // Determine saved items from AuthState
                          List<String> savedProductIds = [];
                          String currentUserId = '';
                          final authState = context.read<AuthCubit>().state;
                          if (authState is AuthAuthenticated) {
                            savedProductIds = authState.userModel.savedProducts;
                            currentUserId = authState.userModel.id;
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final product = results[index];
                              final isSaved = savedProductIds.contains(product.id);
                              final isOwner = product.sellerId == currentUserId;
                              
                              // Formatting time ago naively for UI
                              final diff = DateTime.now().difference(product.createdAt);
                              String timeString = '${diff.inHours}h ago';
                              if (diff.inHours == 0) timeString = '${diff.inMinutes}m ago';
                              if (diff.inDays > 0) timeString = '${diff.inDays}d ago';

                              double? distanceInKm;
                              if (_currentPosition != null &&
                                  product.latitude != null &&
                                  product.longitude != null) {
                                final distanceInMeters = Geolocator.distanceBetween(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                  product.latitude!,
                                  product.longitude!,
                                );
                                distanceInKm = distanceInMeters / 1000;
                              }

                              return ProductCard(
                                imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : 'https://placehold.co/600x400/png',
                                title: product.title,
                                location: _formatLocation(product.location),
                                distanceInKm: distanceInKm,
                                timePosted: timeString,
                                categoryString: product.categoryString,
                                tags: product.tags,
                                isSaved: isSaved,
                                isOwner: isOwner,
                                hasJoined: product.requestedBy.contains(currentUserId),
                                hasEnded: product.expiresAt != null && DateTime.now().isAfter(product.expiresAt!),
                                onLocationTapped: () {
                                  MapUtils.openDirections(
                                    context: context,
                                    currentPosition: _currentPosition,
                                    destLat: product.latitude,
                                    destLng: product.longitude,
                                    destName: product.location,
                                  );
                                },
                                onCardTapped: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailPage(
                                        product: product,
                                        isOwner: isOwner,
                                      ),
                                    ),
                                  );
                                },
                                onSaveTapped: () {
                                  context.read<AuthCubit>().toggleSaveProduct(product.id);
                                },
                                onInterested: () async {
                                  if (isOwner) return;
                                  final success = await context.read<ProductCubit>().requestPickup(product.id, currentUserId);
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Joined the pickup raffle for ${product.title}'),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
