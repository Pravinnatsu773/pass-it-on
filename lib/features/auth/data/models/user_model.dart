import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String? photoUrl;
  final bool isProfileComplete;
  final List<String> savedProducts;
  
  const UserModel({
    required this.id,
    required this.name,
    this.photoUrl,
    this.isProfileComplete = false,
    this.savedProducts = const [],
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      isProfileComplete: json['isProfileComplete'] as bool? ?? false,
      savedProducts: (json['savedProducts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'isProfileComplete': isProfileComplete,
      'savedProducts': savedProducts,
    };
  }
  
  UserModel copyWith({
    String? id,
    String? name,
    String? photoUrl,
    bool? isProfileComplete,
    List<String>? savedProducts,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      savedProducts: savedProducts ?? this.savedProducts,
    );
  }

  @override
  List<Object?> get props => [id, name, photoUrl, isProfileComplete, savedProducts];
}
