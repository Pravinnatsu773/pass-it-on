import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/product_cubit.dart';
import '../cubit/product_state.dart';
import '../widgets/product_card.dart';

import 'product_detail_page.dart';
import '../../../../core/utils/map_utils.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onSearchTapped;

  const HomePage({super.key, this.onSearchTapped});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentLocation = 'Fetching location...';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _currentLocation = 'Location services disabled';
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _currentLocation = 'Location permissions denied';
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _currentLocation = 'Location permissions denied forever';
        });
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
      Geocoding geocoding = Geocoding();
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            String locality = 'Unknown location';
            if (place.locality != null && place.locality!.isNotEmpty) {
              locality = place.locality!;
            } else if (place.subLocality != null &&
                place.subLocality!.isNotEmpty) {
              locality = place.subLocality!;
            } else if (place.name != null && place.name!.isNotEmpty) {
              locality = place.name!;
            }
            _currentLocation = locality;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentLocation = 'Unknown location';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = 'Failed: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            String firstName = 'There';
            if (state is AuthAuthenticated) {
              final fullName = state.userModel.name;
              firstName = fullName.split(' ').first;
            } else if (state is AuthProfileIncomplete) {
              final fullName = state.user.displayName ?? 'User';
              firstName = fullName.split(' ').first;
            }

            return SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              'Hello, $firstName',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F4C3A),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Color(0xFF5A5A5A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentLocation,
                                style: const TextStyle(
                                  color: Color(0xFF5A5A5A),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SEARCH BAR
                  Semantics(
                    button: true,
                    label: 'Search items in your community',
                    child: GestureDetector(
                      onTap: widget.onSearchTapped,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search items in your community...',
                              hintStyle: TextStyle(
                                color: Color(0xFF8B8B8B),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Color(0xFF8B8B8B),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(height: 24),

                  // DASHBOARD CARDS
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: Container(
                  //         padding: const EdgeInsets.all(20),
                  //         decoration: BoxDecoration(
                  //           color: const Color(0xFF33634B),
                  //           borderRadius: BorderRadius.circular(20),
                  //         ),
                  //         child: const Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text('Impact', style: TextStyle(color: Color(0xFF8BB8A1), fontSize: 12)),
                  //             SizedBox(height: 8),
                  //             Text(
                  //               '12\nItems\nRehomed',
                  //               style: TextStyle(
                  //                 color: Colors.white,
                  //                 fontSize: 24,
                  //                 fontWeight: FontWeight.bold,
                  //                 height: 1.2,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 16),
                  //     Expanded(
                  //       child: Container(
                  //         padding: const EdgeInsets.all(20),
                  //         decoration: BoxDecoration(
                  //           color: const Color(0xFFBDE7F4),
                  //           borderRadius: BorderRadius.circular(20),
                  //         ),
                  //         child: const Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text('Community', style: TextStyle(color: Color(0xFF67A4B6), fontSize: 12)),
                  //             SizedBox(height: 8),
                  //             Text(
                  //               '48\nNeighbors\nNear',
                  //               style: TextStyle(
                  //                 color: Color(0xFF1E5B6E),
                  //                 fontSize: 24,
                  //                 fontWeight: FontWeight.bold,
                  //                 height: 1.2,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 16),

                  // NEARBY GIVEAWAYS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nearby Giveaways',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      // Row(
                      //   children: const [
                      //     Icon(Icons.tune, size: 16, color: Color(0xFF5A5A5A)),
                      //     SizedBox(width: 4),
                      //     Text(
                      //       'Filter',
                      //       style: TextStyle(
                      //         color: Color(0xFF5A5A5A),
                      //         fontSize: 12,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // PRODUCT LIST
                  BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, productState) {
                      if (productState is ProductLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                              color: Color(0xFF0F4C3A),
                            ),
                          ),
                        );
                      }

                      if (productState is ProductError) {
                        return Center(
                          child: Text(
                            'Error loading products: ${productState.message}',
                          ),
                        );
                      }

                      if (productState is ProductLoaded) {
                        final products = productState.feedProducts;

                        if (products.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('No products available yet.'),
                            ),
                          );
                        }

                        // Determine saved items from AuthState
                        List<String> savedProductIds = [];
                        String currentUserId = '';
                        if (state is AuthAuthenticated) {
                          savedProductIds = state.userModel.savedProducts;
                          currentUserId = state.userModel.id;
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final isSaved = savedProductIds.contains(
                              product.id,
                            );
                            final isOwner = product.sellerId == currentUserId;

                            // Formatting time ago naively for UI
                            final diff = DateTime.now().difference(
                              product.createdAt,
                            );
                            String timeString = '${diff.inHours}h ago';
                            if (diff.inHours == 0)
                              timeString = '${diff.inMinutes}m ago';
                            if (diff.inDays > 0)
                              timeString = '${diff.inDays}d ago';

                            double? distanceInKm;
                            if (_currentPosition != null &&
                                product.latitude != null &&
                                product.longitude != null) {
                              final distanceInMeters =
                                  Geolocator.distanceBetween(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                    product.latitude!,
                                    product.longitude!,
                                  );
                              distanceInKm = distanceInMeters / 1000;
                            }

                            return ProductCard(
                              imageUrl: product.imageUrls.isNotEmpty
                                  ? product.imageUrls.first
                                  : 'https://placehold.co/600x400/png',
                              title: product.title,
                              location: _formatLocation(product.location),
                              distanceInKm: distanceInKm,
                              timePosted: timeString,
                              categoryString: product.categoryString,
                              tags: product.tags,
                              isSaved: isSaved,
                              isOwner: isOwner,
                              hasJoined: product.requestedBy.contains(
                                currentUserId,
                              ),
                              hasEnded:
                                  product.expiresAt != null &&
                                  DateTime.now().isAfter(product.expiresAt!),
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
                                context.read<AuthCubit>().toggleSaveProduct(
                                  product.id,
                                );
                              },
                              onInterested: () async {
                                if (isOwner) {
                                  // Do nothing or view logic
                                  return;
                                }
                                final success = await context
                                    .read<ProductCubit>()
                                    .requestPickup(product.id, currentUserId);
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Joined the pickup raffle for ${product.title}',
                                      ),
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
            );
          },
        ),
      ),
    );
  }
}
