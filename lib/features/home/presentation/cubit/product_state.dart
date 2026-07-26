import 'package:equatable/equatable.dart';
import '../../../home/data/models/product_model.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductModel> feedProducts;
  final List<ProductModel> savedProducts;
  final List<ProductModel> searchResults;

  const ProductLoaded({
    this.feedProducts = const [],
    this.savedProducts = const [],
    this.searchResults = const [],
  });

  ProductLoaded copyWith({
    List<ProductModel>? feedProducts,
    List<ProductModel>? savedProducts,
    List<ProductModel>? searchResults,
  }) {
    return ProductLoaded(
      feedProducts: feedProducts ?? this.feedProducts,
      savedProducts: savedProducts ?? this.savedProducts,
      searchResults: searchResults ?? this.searchResults,
    );
  }

  @override
  List<Object> get props => [feedProducts, savedProducts, searchResults];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}
