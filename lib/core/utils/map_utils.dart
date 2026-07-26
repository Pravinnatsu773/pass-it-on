import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class MapUtils {
  static Future<void> openDirections({
    required BuildContext context,
    required Position? currentPosition,
    required double? destLat,
    required double? destLng,
    required String destName,
  }) async {
    String url = '';
    
    if (currentPosition != null && destLat != null && destLng != null) {
      url = 'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=$destLat,$destLng';
    } else {
      url = 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(destName)}';
    }

    final uri = Uri.parse(url);
    try {
      final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map.')),
        );
      }
    }
  }
}
