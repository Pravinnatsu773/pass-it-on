import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final String timePosted;
  final VoidCallback onInterested;
  final String categoryString;
  final List<String> tags;
  final bool isSaved;
  final bool isOwner;
  final bool hasJoined;
  final bool hasEnded;
  final VoidCallback onSaveTapped;
  final VoidCallback? onCardTapped;
  final VoidCallback? onLocationTapped;
  final double? distanceInKm;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.timePosted,
    required this.onInterested,
    this.categoryString = 'GENERAL',
    this.tags = const ['Available'],
    this.isSaved = false,
    this.isOwner = false,
    this.hasJoined = false,
    this.hasEnded = false,
    required this.onSaveTapped,
    this.onCardTapped,
    this.onLocationTapped,
    this.distanceInKm,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      hint: 'View product details',
      child: GestureDetector(
        onTap: onCardTapped,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image with Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: ExcludeSemantics(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 220,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 220,
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
                  // Tags (Top Left)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Row(
                      children: tags
                          .where((tag) => tag.toLowerCase() != 'available')
                          .map((tag) {
                        final isAvailable = false;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? const Color(0xFF0F4C3A)
                                : Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: isAvailable
                                  ? Colors.white
                                  : const Color(0xFF1A1C1E),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Bookmark (Top Right)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Semantics(
                      button: true,
                      label: isSaved ? 'Remove from saved' : 'Save product',
                      child: GestureDetector(
                        onTap: onSaveTapped,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 20,
                            color: const Color(0xFF0F4C3A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category
                    Text(
                      categoryString.toUpperCase() == 'GENERAL'
                          ? 'OTHER'
                          : categoryString.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF0F4C3A),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1C1E),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Location and Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Semantics(
                            button: onLocationTapped != null,
                            label: onLocationTapped != null
                                ? 'Open location in maps'
                                : null,
                            child: GestureDetector(
                              onTap: onLocationTapped,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Color(0xFF5A5A5A),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      distanceInKm != null
                                          ? '$location (${distanceInKm!.toStringAsFixed(1)}km)'
                                          : location,
                                      style: TextStyle(
                                        color: const Color(0xFF5A5A5A),
                                        fontSize: 12,
                                        decoration: onLocationTapped != null
                                            ? TextDecoration.underline
                                            : TextDecoration.none,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (onLocationTapped != null) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.open_in_new,
                                      size: 12,
                                      color: Color(0xFF5A5A5A),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timePosted,
                          style: const TextStyle(
                            color: Color(0xFF5A5A5A),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (hasJoined || hasEnded)
                            ? null
                            : onInterested,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C3A),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE8EBE9),
                          disabledForegroundColor: const Color(0xFF5A5A5A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isOwner
                              ? 'View'
                              : (hasEnded
                                    ? 'Raffle Ended'
                                    : (hasJoined ? 'Joined' : 'Join Raffle')),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
