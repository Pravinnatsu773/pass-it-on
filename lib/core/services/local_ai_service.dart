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
  Future<bool> initialize(String modelPath);
  Future<GemmaResult> generateListingDetails(String title);
}

/// Native Android Local AI Service using MethodChannels
class NativeGemmaService implements LocalAIService {
  static const MethodChannel _methodChannel = MethodChannel('com.example.pass_it_on/gemma');
  static const EventChannel _eventChannel = EventChannel('com.example.pass_it_on/gemma_stream');
  
  bool _isInitialized = false;

  @override
  Future<bool> initialize(String modelPath) async {
    try {
      final success = await _methodChannel.invokeMethod<bool>('initialize', {
        'modelName': modelPath,
      });
      _isInitialized = success ?? false;
      if (_isInitialized) {
        debugPrint('Native Gemma model initialized successfully.');
      } else {
        debugPrint('Native Gemma model failed to initialize internally.');
      }
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize NativeGemmaService: $e');
      _isInitialized = false;
      throw Exception('Device incompatible or out of memory: $e');
    }
  }

  @override
  Future<GemmaResult> generateListingDetails(String title) async {
    if (!_isInitialized) {
      throw Exception('NativeGemmaService not initialized. Cannot generate listing details.');
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
      throw Exception('Error generating response natively: $e');
    }
  }
}
