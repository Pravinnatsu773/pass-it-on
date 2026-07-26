import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../home/presentation/cubit/product_cubit.dart';
import '../../../home/presentation/cubit/product_state.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../../home/presentation/pages/product_detail_page.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/map_utils.dart';

class SavedPage extends StatefulWidget {
  const SavedPage({super.key});

  @override
  State<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends State<SavedPage> {
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadSavedProducts();
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

  void _loadSavedProducts() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProductCubit>().loadSaved(authState.userModel.savedProducts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listenWhen: (previous, current) {
            if (current is! AuthAuthenticated) return false;
            
            // If we just authenticated, we definitely need to load
            if (previous is! AuthAuthenticated) return true;
            
            // If already authenticated, only load if the saved list grew
            return previous.userModel.savedProducts.length < current.userModel.savedProducts.length;
          },
          listener: (context, authState) {
            if (authState is AuthAuthenticated) {
              context.read<ProductCubit>().loadSaved(authState.userModel.savedProducts);
            }
          },
          builder: (context, authState) {
            List<String> savedProductIds = [];
            String currentUserId = '';
            if (authState is AuthAuthenticated) {
              savedProductIds = authState.userModel.savedProducts;
              currentUserId = authState.userModel.id;
            }

            return BlocBuilder<ProductCubit, ProductState>(
              builder: (context, productState) {
                List<dynamic> savedProducts = [];
                if (productState is ProductLoaded) {
                  // We only display the ones that the user still has bookmarked locally
                  savedProducts = productState.savedProducts
                      .where((p) => savedProductIds.contains(p.id))
                      .toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // HEADER
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Semantics(
                            header: true,
                            child: const Text(
                              'Saved Items',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F4C3A),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8EBE9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${savedProducts.length} items',
                              style: const TextStyle(
                                color: Color(0xFF0F4C3A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // SAVED LIST
                    Expanded(
                      child: savedProducts.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              primary: false,
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              itemCount: savedProducts.length,
                              itemBuilder: (context, index) {
                                final product = savedProducts[index];
                                final isOwner = product.sellerId == currentUserId;
                                
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
                                  isSaved: true,
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
                                          backgroundColor: const Color(0xFF0F4C3A),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Semantics(
        label: 'No saved items yet. Items you save will appear here',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            ExcludeSemantics(
              child: Icon(
                Icons.bookmark_border,
                size: 80,
                color: Color(0xFF8B8B8B),
              ),
            ),
            SizedBox(height: 16),
            ExcludeSemantics(
              child: Text(
                'No saved items yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1C1E),
                ),
              ),
            ),
            SizedBox(height: 8),
            ExcludeSemantics(
              child: Text(
                'Items you save will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5A5A5A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
