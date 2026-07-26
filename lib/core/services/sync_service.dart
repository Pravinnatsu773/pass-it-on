import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../network/connectivity_provider.dart';
import '../storage/sync_queue.dart';

/// Listens to connectivity and pushes pending offline changes to Firebase 
/// when the device comes back online.
class SyncService {
  final ConnectivityProvider _connectivityProvider;
  final SyncQueue _syncQueue;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  bool _isSyncing = false;

  SyncService({
    required ConnectivityProvider connectivityProvider,
    required SyncQueue syncQueue,
    required FirebaseFirestore firestore,
    FirebaseStorage? storage,
  })  : _connectivityProvider = connectivityProvider,
        _syncQueue = syncQueue,
        _firestore = firestore,
        _storage = storage ?? FirebaseStorage.instance {
    
    // Listen for network changes
    _connectivityProvider.addListener(_onNetworkChanged);
  }

  void _onNetworkChanged() {
    if (_connectivityProvider.isOnline) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_isSyncing) return; // Prevent concurrent sync loops
    _isSyncing = true;

    try {
      final pendingItems = await _syncQueue.getPendingItems();

      if (pendingItems.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (final item in pendingItems) {
        final id = item['id'] as String;
        final collectionName = item['collectionName'] as String;
        final entityId = item['entityId'] as String;
        final operation = item['operation'] as String;
        final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        try {
          // Push to Firebase based on operation
          if (operation == 'CREATE' || operation == 'UPDATE') {
             if (payload.containsKey('localImagePaths')) {
                final List<dynamic> paths = payload['localImagePaths'];
                final List<String> imageUrls = [];
                final uuid = const Uuid();
                
                for (var path in paths) {
                  final String imageId = uuid.v4();
                  final Reference ref = _storage
                      .ref()
                      .child(collectionName)
                      .child(entityId)
                      .child('img_$imageId.jpg');

                  await ref.putFile(File(path as String));
                  final String downloadUrl = await ref.getDownloadURL();
                  imageUrls.add(downloadUrl);
                }
                
                payload['imageUrls'] = imageUrls;
                payload.remove('localImagePaths');
             }

             await _firestore.collection(collectionName).doc(entityId).set(payload);
          } else if (operation == 'DELETE') {
             await _firestore.collection(collectionName).doc(entityId).delete();
          }

          // If successful, remove from local queue
          await _syncQueue.removeFromQueue(id);
        } catch (e) {
          debugPrint('Failed to sync item $id: $e');
          // If it fails (e.g. timeout), break the loop and try again next time network state changes
          break; 
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
  
  void dispose() {
    _connectivityProvider.removeListener(_onNetworkChanged);
  }
}
