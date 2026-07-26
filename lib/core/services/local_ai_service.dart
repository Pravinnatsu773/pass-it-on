import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
class GemmaResult {
  final String description;
  final String category;

  GemmaResult({required this.description, required this.category});
}

abstract class LocalAIService {
  Future<void> initialize(String modelPath);
  Future<GemmaResult> generateListingDetails(String title);
}

/// Simulated Local AI Service for UI testing or fallback when model is missing.
class SimulatedGemmaService implements LocalAIService {
  @override
  Future<void> initialize(String modelPath) async {
    // Nothing to initialize for simulated service
  }

  @override
  Future<GemmaResult> generateListingDetails(String title) async {
    await Future.delayed(Duration(milliseconds: 1000 + Random().nextInt(1000)));

    final lowerTitle = title.toLowerCase();
    String category = 'Miscellaneous';
    String description = '';

    if (lowerTitle.contains('chair') || lowerTitle.contains('desk') || lowerTitle.contains('table') || lowerTitle.contains('sofa') || lowerTitle.contains('bed')) {
      category = 'Furniture';
      description = 'A wonderful $title available for pickup. It has been well-loved and is still in great functional condition. Perfect for your home! Must pick up.';
    } else if (lowerTitle.contains('phone') || lowerTitle.contains('laptop') || lowerTitle.contains('tv') || lowerTitle.contains('monitor')) {
      category = 'Electronics';
      description = 'Up for grabs: $title. Tested and works perfectly. A great opportunity if you are looking for electronics. Includes power cables.';
    } else if (lowerTitle.contains('shirt') || lowerTitle.contains('pants') || lowerTitle.contains('coat') || lowerTitle.contains('jacket') || lowerTitle.contains('shoes')) {
      category = 'Clothes';
      description = 'Gently used $title. Clean, washed, and ready for a new owner. Great condition with no major tears or stains.';
    } else if (lowerTitle.contains('book') || lowerTitle.contains('novel') || lowerTitle.contains('textbook')) {
      category = 'Books';
      description = 'An interesting read: $title. The pages are crisp and the spine is intact. Ready to be passed on to the next reader.';
    } else if (lowerTitle.contains('plate') || lowerTitle.contains('bowl') || lowerTitle.contains('pot') || lowerTitle.contains('pan')) {
      category = 'Kitchen';
      description = 'Useful $title for your kitchen. Still in great condition and ready to cook or serve up a storm!';
    } else {
      category = 'Others';
      description = 'Offering this $title to the community. Still has plenty of life left in it! Check out the pictures for details.';
    }

    return GemmaResult(
      description: description,
      category: category,
    );
  }
}

/// Native Android Local AI Service using MethodChannels
class NativeGemmaService implements LocalAIService {
  static const MethodChannel _methodChannel = MethodChannel('com.example.pass_it_on/gemma');
  static const EventChannel _eventChannel = EventChannel('com.example.pass_it_on/gemma_stream');
  
  bool _isInitialized = false;

  @override
  Future<void> initialize(String modelPath) async {
    try {
      final success = await _methodChannel.invokeMethod<bool>('initialize', {
        'modelName': modelPath,
      });
      _isInitialized = success ?? false;
      if (_isInitialized) {
        debugPrint('Native Gemma model initialized successfully.');
      }
    } catch (e) {
      debugPrint('Failed to initialize NativeGemmaService: $e');
      _isInitialized = false;
    }
  }

  @override
  Future<GemmaResult> generateListingDetails(String title) async {
    if (!_isInitialized) {
      debugPrint('NativeGemmaService not initialized. Falling back to SimulatedGemmaService.');
      return SimulatedGemmaService().generateListingDetails(title);
    }

    try {
      final prompt = "Generate a polite marketplace description and one category from (Books, Furniture, Electronics, Kitchen, Clothes, Others) for an item titled: '$title'. Format response exactly as: CATEGORY: <category>\nDESCRIPTION: <description>";
      
      final completer = Completer<GemmaResult>();
      final buffer = StringBuffer();
      late StreamSubscription subscription;

      subscription = _eventChannel.receiveBroadcastStream().listen((event) {
        final chunk = event as String;
        if (chunk == "[DONE]") {
          subscription.cancel();
          final response = buffer.toString();
          
          String category = 'Others';
          String description = response;

          // Extremely basic parser for the prompt format
          if (response.contains('CATEGORY:') && response.contains('DESCRIPTION:')) {
            final parts = response.split('DESCRIPTION:');
            category = parts[0].replaceAll('CATEGORY:', '').trim();
            description = parts[1].trim();
          }

          if (!completer.isCompleted) {
            completer.complete(GemmaResult(
              description: description,
              category: category,
            ));
          }
        } else {
          buffer.write(chunk);
        }
      }, onError: (error) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      // Trigger the native generation
      await _methodChannel.invokeMethod('generateResponse', {
        'prompt': prompt,
      });

      return completer.future;
    } catch (e) {
      debugPrint('Error generating response natively: $e');
      return SimulatedGemmaService().generateListingDetails(title);
    }
  }
}
