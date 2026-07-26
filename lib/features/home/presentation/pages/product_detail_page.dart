import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/product_cubit.dart';
import '../../data/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;
  final bool isOwner;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.isOwner,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  String? sellerName;
  String? sellerPhotoUrl;
  Position? _currentPosition;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchSellerName();
    _fetchPosition();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resolveRaffleIfNeeded(ProductModel p) async {
    if (p.expiresAt != null &&
        DateTime.now().isAfter(p.expiresAt!) &&
        p.selectedWinnerId == null &&
        p.requestedBy.isNotEmpty) {
      final participants = p.requestedBy.toList()..shuffle();
      final winner = participants.first;
      await context.read<ProductCubit>().resolveWinner(p.id, winner);
    }
  }

  Stream<ProductModel> get _productStream {
    return FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return ProductModel.fromJson(snapshot.data()!, snapshot.id);
          }
          return widget.product;
        });
  }

  Future<void> _fetchPosition() async {
    try {
      final position =
          await Geolocator.getLastKnownPosition() ??
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

  Future<void> _openDirections() async {
    String url = '';

    if (_currentPosition != null &&
        widget.product.latitude != null &&
        widget.product.longitude != null) {
      url =
          'https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${widget.product.latitude},${widget.product.longitude}';
    } else {
      url =
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(widget.product.location)}';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open map.')));
      }
    }
  }

  Future<void> _fetchSellerName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.product.sellerId)
          .get();
      if (doc.exists) {
        setState(() {
          sellerName = doc.data()?['name'] ?? 'Unknown User';
          sellerPhotoUrl = doc.data()?['photoUrl'];
        });
      }
    } catch (e) {
      // Ignored
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ProductModel>(
      stream: _productStream,
      initialData: widget.product,
      builder: (context, snapshot) {
        final product = snapshot.data ?? widget.product;

        // Try to resolve if needed
        _resolveRaffleIfNeeded(product);

        return Scaffold(
          backgroundColor: const Color(0xFFF9FBFA),
          body: CustomScrollView(
            slivers: [
              // APP BAR & IMAGE
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                backgroundColor: const Color(0xFFF9FBFA),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Semantics(
                    button: true,
                    label: 'Back',
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      bool isSaved = false;
                      if (authState is AuthAuthenticated) {
                        isSaved = authState.userModel.savedProducts.contains(
                          widget.product.id,
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Semantics(
                          button: true,
                          label: isSaved ? 'Remove from saved' : 'Save product',
                          child: GestureDetector(
                            onTap: () {
                              context.read<AuthCubit>().toggleSaveProduct(
                                widget.product.id,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                size: 20,
                                color: const Color(0xFF0F4C3A),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: product.imageUrls.isNotEmpty
                      ? PageView.builder(
                          itemCount: product.imageUrls.length,
                          itemBuilder: (context, index) {
                            return ExcludeSemantics(
                              child: CachedNetworkImage(
                                imageUrl: product.imageUrls[index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : ExcludeSemantics(
                          child: Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              // CONTENT
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FBFA),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -32, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category and Time
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EBE9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product.categoryString.toUpperCase() ==
                                        'GENERAL'
                                    ? 'OTHER'
                                    : product.categoryString.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF0F4C3A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            Text(
                              _getTimeString(product),
                              style: const TextStyle(
                                color: Color(0xFF5A5A5A),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Countdown Timer
                        Builder(
                          builder: (context) {
                            if (product.expiresAt != null &&
                                DateTime.now().isBefore(product.expiresAt!)) {
                              final diff = product.expiresAt!.difference(
                                DateTime.now(),
                              );
                              final hours = diff.inHours.toString().padLeft(
                                2,
                                '0',
                              );
                              final minutes = (diff.inMinutes % 60)
                                  .toString()
                                  .padLeft(2, '0');
                              final seconds = (diff.inSeconds % 60)
                                  .toString()
                                  .padLeft(2, '0');

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4E5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFFB347),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer,
                                      size: 18,
                                      color: Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Raffle ends in $hours:$minutes:$seconds',
                                      style: const TextStyle(
                                        color: Color(0xFFD97706),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        // Title
                        Semantics(
                          header: true,
                          child: Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1C1E),
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (product.description != null &&
                            product.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            product.description!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF5A5A5A),
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Location
                        Builder(
                          builder: (context) {
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

                            final displayLoc = _formatLocation(
                              product.location,
                            );
                            final textToDisplay = distanceInKm != null
                                ? '$displayLoc (${distanceInKm.toStringAsFixed(1)}km)'
                                : displayLoc;

                            return Semantics(
                              button: true,
                              label: 'Open location in maps',
                              child: GestureDetector(
                                onTap: _openDirections,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: Color(0xFF0F4C3A),
                                    ),
                                    Flexible(
                                      child: Text(
                                        textToDisplay,
                                        style: const TextStyle(
                                          color: Color(0xFF0F4C3A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.open_in_new,
                                      size: 14,
                                      color: Color(0xFF0F4C3A),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),



                        if (product.requestedBy.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          Semantics(
                            button: true,
                            label: 'View participants',
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  builder: (context) {
                                    return SafeArea(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Semantics(
                                                    header: true,
                                                    child: Text(
                                                      'Participants (${product.requestedBy.length})',
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color(
                                                          0xFF1A1C1E,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Semantics(
                                                    button: true,
                                                    label:
                                                        'Close participants dialog',
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.close,
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Flexible(
                                              child: ListView.separated(
                                                shrinkWrap: true,
                                                itemCount:
                                                    product.requestedBy.length,
                                                separatorBuilder:
                                                    (context, index) =>
                                                        const Divider(
                                                          height: 1,
                                                          color: Color(
                                                            0xFFE8EBE9,
                                                          ),
                                                        ),
                                                itemBuilder: (context, index) {
                                                  final uid = product
                                                      .requestedBy[index];
                                                  final isWinner =
                                                      product
                                                          .selectedWinnerId ==
                                                      uid;
                                                  return _UserListItem(
                                                    userId: uid,
                                                    isWinner: isWinner,
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8EBE9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Participants (${product.requestedBy.length})',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A1C1E),
                                      ),
                                    ),
                                    ExcludeSemantics(
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Color(0xFF5A5A5A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Seller Info
                        Semantics(
                          header: true,
                          child: const Text(
                            'Posted By',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1C1E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: sellerPhotoUrl != null
                                  ? CachedNetworkImageProvider(sellerPhotoUrl!)
                                  : null,
                              child: sellerPhotoUrl == null
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isOwner
                                      ? 'You'
                                      : (sellerName ?? 'Loading...'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1C1E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 16,
                        ), // minimal padding before scroll ends
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(24.0).copyWith(
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 24.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Builder(
              builder: (context) {
                String currentUserId = '';
                final authState = context.read<AuthCubit>().state;
                if (authState is AuthAuthenticated) {
                  currentUserId = authState.userModel.id;
                }

                if (widget.isOwner) {
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Product'),
                            content: const Text(
                              'Are you sure you want to delete this product?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Color(0xFF5A5A5A)),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          if (!context.mounted) return;
                          final success = await context
                              .read<ProductCubit>()
                              .deleteProduct(product.id);
                          if (!context.mounted) return;
                          if (success) {
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to delete product'),
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Delete Product',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                }

                final isExpired =
                    product.expiresAt != null &&
                    DateTime.now().isAfter(product.expiresAt!);
                final hasRequested = product.requestedBy.contains(
                  currentUserId,
                );
                final hasWinner = product.selectedWinnerId != null;

                if (isExpired || hasWinner) {
                  final isMe = product.selectedWinnerId == currentUserId;
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF0F4C3A)
                          : const Color(0xFFE8EBE9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isMe ? '🎉 You won the raffle! 🎉' : 'Raffle Ended',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : const Color(0xFF5A5A5A),
                      ),
                    ),
                  );
                }

                bool hasEnded =
                    product.expiresAt != null &&
                    DateTime.now().isAfter(product.expiresAt!);

                if (hasRequested) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EBE9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      hasEnded
                          ? 'Joined (Raffle Ended)'
                          : 'Joined (Waiting for Raffle...)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A5A5A),
                      ),
                    ),
                  );
                }

                if (hasEnded) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EBE9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Raffle Ended',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A5A5A),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await context
                          .read<ProductCubit>()
                          .requestPickup(product.id, currentUserId);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Joined the pickup raffle!'),
                            backgroundColor: Color(0xFF0F4C3A),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C3A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Join Raffle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getTimeString(ProductModel product) {
    final diff = DateTime.now().difference(product.createdAt);
    if (diff.inHours == 0) return '${diff.inMinutes}m ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    return '${diff.inHours}h ago';
  }
}

class _UserListItem extends StatefulWidget {
  final String userId;
  final bool isWinner;
  const _UserListItem({required this.userId, this.isWinner = false});

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  String? userName;
  String? userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchName();
  }

  Future<void> _fetchName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          userName = doc.data()?['name'] ?? 'Unknown User';
          userPhotoUrl = doc.data()?['photoUrl'];
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: widget.isWinner
            ? const Color(0xFF0F4C3A)
            : Colors.grey.shade300,
        backgroundImage: userPhotoUrl != null
            ? CachedNetworkImageProvider(userPhotoUrl!)
            : null,
        child: userPhotoUrl == null
            ? Icon(
                Icons.person,
                color: widget.isWinner ? Colors.white : Colors.grey,
              )
            : null,
      ),
      title: Text(
        userName ?? 'Loading...',
        style: TextStyle(
          fontWeight: widget.isWinner ? FontWeight.bold : FontWeight.normal,
          color: widget.isWinner
              ? const Color(0xFF0F4C3A)
              : const Color(0xFF1A1C1E),
        ),
      ),
      trailing: widget.isWinner
          ? const Icon(Icons.star, color: Color(0xFFFFB347))
          : null,
    );
  }
}
