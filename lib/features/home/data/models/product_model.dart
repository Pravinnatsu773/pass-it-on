import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus { available, requested, sold }

class ProductModel extends Equatable {
  final String id;
  final String sellerId;
  final String title;
  final String? description;
  final String location;
  final String categoryString;
  final List<String> tags;
  final List<String> imageUrls;
  final DateTime createdAt;
  final ProductStatus status;
  final double? latitude;
  final double? longitude;
  final DateTime? expiresAt;
  final List<String> requestedBy;
  final String? selectedWinnerId;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.title,
    this.description,
    required this.location,
    required this.categoryString,
    required this.tags,
    required this.imageUrls,
    required this.createdAt,
    this.status = ProductStatus.available,
    this.latitude,
    this.longitude,
    this.expiresAt,
    this.requestedBy = const [],
    this.selectedWinnerId,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json, String documentId) {
    DateTime parsedDate;
    if (json['createdAt'] is Timestamp) {
      parsedDate = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      parsedDate = DateTime.tryParse(json['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }
    
    DateTime? parsedExpires;
    if (json['expiresAt'] is Timestamp) {
      parsedExpires = (json['expiresAt'] as Timestamp).toDate();
    } else if (json['expiresAt'] is String) {
      parsedExpires = DateTime.tryParse(json['expiresAt']);
    }

    return ProductModel(
      id: documentId,
      sellerId: json['sellerId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String? ?? '',
      categoryString: json['categoryString'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: parsedDate,
      status: ProductStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProductStatus.available,
      ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      expiresAt: parsedExpires,
      requestedBy: (json['requestedBy'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      selectedWinnerId: json['selectedWinnerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'location': location,
      'categoryString': categoryString,
      'tags': tags,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.name,
      'latitude': latitude,
      'longitude': longitude,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'requestedBy': requestedBy,
      'selectedWinnerId': selectedWinnerId,
    };
  }

  ProductModel copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    String? location,
    String? categoryString,
    List<String>? tags,
    List<String>? imageUrls,
    DateTime? createdAt,
    ProductStatus? status,
    double? latitude,
    double? longitude,
    DateTime? expiresAt,
    List<String>? requestedBy,
    String? selectedWinnerId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      categoryString: categoryString ?? this.categoryString,
      tags: tags ?? this.tags,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      expiresAt: expiresAt ?? this.expiresAt,
      requestedBy: requestedBy ?? this.requestedBy,
      selectedWinnerId: selectedWinnerId ?? this.selectedWinnerId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sellerId,
        title,
        description,
        location,
        categoryString,
        tags,
        imageUrls,
        createdAt,
        status,
        latitude,
        longitude,
        expiresAt,
        requestedBy,
        selectedWinnerId,
      ];
}
