import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/models/product_model.dart';

import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _productRepository;

  ProductCubit({required ProductRepository productRepository})
    : _productRepository = productRepository,
      super(ProductInitial());

  Future<void> loadFeed() async {
    try {
      if (state is! ProductLoaded) emit(ProductLoading());
      final products = await _productRepository.getFeedProducts();

      if (state is ProductLoaded) {
        emit((state as ProductLoaded).copyWith(feedProducts: products));
      } else {
        emit(ProductLoaded(feedProducts: products));
      }
    } catch (e) {
      if (state is! ProductLoaded) emit(ProductError(e.toString()));
    }
  }

  Future<void> loadSaved(List<String> savedIds) async {
    try {
      if (state is! ProductLoaded) emit(ProductLoading());
      final products = await _productRepository.getSavedProducts(savedIds);

      if (state is ProductLoaded) {
        emit((state as ProductLoaded).copyWith(savedProducts: products));
      } else {
        emit(ProductLoaded(savedProducts: products));
      }
    } catch (e) {
      if (state is! ProductLoaded) emit(ProductError(e.toString()));
    }
  }

  Future<void> search(String query, {String? category}) async {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      // We don't skip if query is empty anymore because we might be searching just by category
      try {
        final results = await _productRepository.searchProducts(query, category: category);
        emit(currentState.copyWith(searchResults: results));
      } catch (e) {
        // Silently fail search errors
        emit(currentState);
      }
    }
  }

  Future<bool> createProduct({
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
      final newProduct = await _productRepository.createProduct(
        sellerId: sellerId,
        title: title,
        description: description,
        location: location,
        categoryString: categoryString,
        imageFiles: imageFiles,
        durationInHours: durationInHours,
        latitude: latitude,
        longitude: longitude,
      );

      if (state is ProductLoaded) {
        final currentState = state as ProductLoaded;
        // Prepend the new product to the feed
        final updatedFeed = [newProduct, ...currentState.feedProducts];
        emit(currentState.copyWith(feedProducts: updatedFeed));
      } else {
        // If not loaded, reload feed
        await loadFeed();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _productRepository.deleteProduct(productId);
      
      if (state is ProductLoaded) {
        final currentState = state as ProductLoaded;
        final updatedFeed = currentState.feedProducts.where((p) => p.id != productId).toList();
        final updatedSaved = currentState.savedProducts.where((p) => p.id != productId).toList();
        final updatedSearch = currentState.searchResults.where((p) => p.id != productId).toList();
        
        emit(currentState.copyWith(
          feedProducts: updatedFeed,
          savedProducts: updatedSaved,
          searchResults: updatedSearch,
        ));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestPickup(String productId, String userId) async {
    try {
      await _productRepository.requestPickup(productId, userId);
      
      if (state is ProductLoaded) {
        final currentState = state as ProductLoaded;
        
        ProductModel updateProduct(ProductModel p) {
          if (p.id == productId && !p.requestedBy.contains(userId)) {
            return p.copyWith(requestedBy: [...p.requestedBy, userId]);
          }
          return p;
        }

        emit(currentState.copyWith(
          feedProducts: currentState.feedProducts.map(updateProduct).toList(),
          savedProducts: currentState.savedProducts.map(updateProduct).toList(),
          searchResults: currentState.searchResults.map(updateProduct).toList(),
        ));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resolveWinner(String productId, String winnerId) async {
    try {
      await _productRepository.resolveWinner(productId, winnerId);
      
      if (state is ProductLoaded) {
        final currentState = state as ProductLoaded;
        
        ProductModel updateProduct(ProductModel p) {
          if (p.id == productId) {
            return p.copyWith(selectedWinnerId: winnerId, status: ProductStatus.sold);
          }
          return p;
        }

        emit(currentState.copyWith(
          feedProducts: currentState.feedProducts.map(updateProduct).toList(),
          savedProducts: currentState.savedProducts.map(updateProduct).toList(),
          searchResults: currentState.searchResults.map(updateProduct).toList(),
        ));
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
