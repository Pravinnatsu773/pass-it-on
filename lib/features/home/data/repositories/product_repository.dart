import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import 'dart:convert';
import '../../../../core/storage/sync_queue.dart';
import '../../../../core/network/connectivity_provider.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final SyncQueue _syncQueue;
  final ConnectivityProvider _connectivityProvider;

  ProductRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required SyncQueue syncQueue,
    required ConnectivityProvider connectivityProvider,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _syncQueue = syncQueue,
        _connectivityProvider = connectivityProvider;

  /// Upload multiple images to Firebase Storage
  Future<List<String>> _uploadImages(String productId, List<File> imageFiles) async {
    final List<String> imageUrls = [];
    final uuid = const Uuid();

    for (var i = 0; i < imageFiles.length; i++) {
      try {
        final String imageId = uuid.v4();
        final Reference ref = _storage
            .ref()
            .child('products')
            .child(productId)
            .child('img_$imageId.jpg');

        await ref.putFile(imageFiles[i]);
        final String downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
      }
    }
    return imageUrls;
  }

  /// Create a new product in Firestore
  Future<ProductModel> createProduct({
    required String sellerId,
    required String title,
    String? description,
    required String location,
    required String categoryString,
    required List<File> imageFiles,
    required int durationInHours,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final String productId = const Uuid().v4();
      
      final bool isOnline = _connectivityProvider.isOnline;
      List<String> imageUrls = [];
      List<String> localImagePaths = [];

      if (isOnline) {
        imageUrls = await _uploadImages(productId, imageFiles);
      } else {
        localImagePaths = imageFiles.map((f) => f.path).toList();
      }

      final newProduct = ProductModel(
        id: productId,
        sellerId: sellerId,
        title: title,
        description: description,
        location: location,
        categoryString: categoryString,
        tags: const ['Available'], // Default tag
        imageUrls: isOnline ? imageUrls : localImagePaths,
        createdAt: DateTime.now(),
        status: ProductStatus.available,
        latitude: latitude,
        longitude: longitude,
        expiresAt: DateTime.now().add(Duration(hours: durationInHours)),
        requestedBy: const [],
      );

      final payload = newProduct.toJson();
      if (!isOnline) {
        if (localImagePaths.isNotEmpty) {
          payload['localImagePaths'] = localImagePaths;
        }
        await _syncQueue.addToQueue(
          entityId: productId,
          collectionName: 'products',
          operation: SyncOperation.create,
          payload: jsonEncode(payload),
        );
      }

      // Save to Firestore
      await _firestore
          .collection('products')
          .doc(productId)
          .set(newProduct.toJson());

      return newProduct;
    } catch (e) {
      debugPrint('Error creating product: $e');
      rethrow;
    }
  }

  /// Delete a product from Firestore
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      // Note: In a production app, we would also delete the associated images from Firebase Storage here.
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  /// Request pickup (join the raffle)
  Future<void> requestPickup(String productId, String userId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'requestedBy': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      debugPrint('Error requesting pickup: $e');
      rethrow;
    }
  }

  /// Resolve the winner for a product
  Future<void> resolveWinner(String productId, String winnerId) async {
    try {
      final docRef = _firestore.collection('products').doc(productId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;
        
        final data = snapshot.data();
        if (data != null && data['selectedWinnerId'] == null) {
          transaction.update(docRef, {
            'selectedWinnerId': winnerId,
            'status': ProductStatus.sold.name,
          });
        }
      });
    } catch (e) {
      debugPrint('Error resolving winner: $e');
      rethrow;
    }
  }

  /// Get feed products (latest first)
  Future<List<ProductModel>> getFeedProducts({int limit = 20}) async {
    try {
      // Note: We remove the 'where' clause for status to avoid needing a Firestore
      // composite index for (status + createdAt). We filter locally instead.
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(limit * 3) // Fetch more to account for filtered items
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .where((p) => p.status == ProductStatus.available)
          .take(limit)
          .toList();
    } catch (e) {
      debugPrint('Error getting feed products: $e');
      return [];
    }
  }

  /// Get saved products by their IDs
  Future<List<ProductModel>> getSavedProducts(List<String> productIds) async {
    if (productIds.isEmpty) return [];
    
    try {
      // Firestore 'whereIn' supports up to 10 items. For a robust app, we chunk it.
      List<ProductModel> allSaved = [];
      
      for (var i = 0; i < productIds.length; i += 10) {
        final end = (i + 10 < productIds.length) ? i + 10 : productIds.length;
        final chunk = productIds.sublist(i, end);
        
        final snapshot = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
            
        allSaved.addAll(
          snapshot.docs.map((doc) => ProductModel.fromJson(doc.data(), doc.id)),
        );
      }
      
      // Sort by createdAt descending locally since whereIn doesn't preserve order easily
      allSaved.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allSaved;
    } catch (e) {
      debugPrint('Error getting saved products: $e');
      return [];
    }
  }

  /// Basic search products (title match via prefix)
  /// Note: Firestore doesn't support full-text search easily. This is a basic implementation.
  Future<List<ProductModel>> searchProducts(String query, {String? category}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(50) 
          .get();

      final allRecent = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data(), doc.id))
          .toList();
          
      final lowerQuery = query.toLowerCase().trim();
      final targetCategory = category?.toLowerCase();
      
      return allRecent.where((p) {
        if (p.status != ProductStatus.available) return false;
        
        // Filter by category if provided
        if (targetCategory != null && p.categoryString.toLowerCase() != targetCategory) {
          return false;
        }
        
        // If query is empty, return true (just category match)
        if (lowerQuery.isEmpty) return true;

        return p.title.toLowerCase().contains(lowerQuery) || 
               p.categoryString.toLowerCase().contains(lowerQuery) ||
               p.location.toLowerCase().contains(lowerQuery);
      }).toList();
      
    } catch (e) {
      debugPrint('Error searching products: $e');
      return [];
    }
  }
}
