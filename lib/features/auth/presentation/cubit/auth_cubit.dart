import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  /// CHECK CURRENT AUTH STATE
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      final user = authRepository.currentUser;

      if (user == null) {
        emit(AuthUnauthenticated());
      } else {
        final userModel = await authRepository.getUserModel(user.uid);
        if (userModel == null || !userModel.isProfileComplete) {
          emit(AuthProfileIncomplete(user));
        } else {
          emit(AuthAuthenticated(user, userModel));
        }
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// GOOGLE SIGN IN
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());

    try {
      final userCredential = await authRepository.signInWithGoogle();
      
      if (userCredential?.user != null) {
        final user = userCredential!.user!;
        final userModel = await authRepository.getUserModel(user.uid);
        if (userModel == null || !userModel.isProfileComplete) {
          emit(AuthProfileIncomplete(user));
        } else {
          emit(AuthAuthenticated(user, userModel));
        }
      } else {
        // Sign in was cancelled or failed without an exception
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// COMPLETE PROFILE
  Future<void> completeProfile({required String name, File? imageFile}) async {
    emit(AuthLoading());
    try {
      final user = authRepository.currentUser;
      if (user == null) {
        emit(AuthUnauthenticated());
        return;
      }
      
      String? photoUrl = user.photoURL;
      if (imageFile != null) {
        photoUrl = await authRepository.uploadProfilePicture(user.uid, imageFile);
      }

      final userModel = UserModel(
        id: user.uid,
        name: name,
        photoUrl: photoUrl,
        isProfileComplete: true,
      );

      await authRepository.saveUserModel(userModel);
      emit(AuthAuthenticated(user, userModel));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// UPDATE PROFILE (for editing name)
  Future<void> updateProfile({required String name}) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      try {
        final updatedUserModel = currentState.userModel.copyWith(name: name);
        // Optimistic UI update
        emit(AuthAuthenticated(currentState.user, updatedUserModel));
        // Sync to Firestore
        await authRepository.saveUserModel(updatedUserModel);
      } catch (e) {
        // Revert on failure
        emit(currentState);
      }
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// TOGGLE SAVE PRODUCT
  Future<void> toggleSaveProduct(String productId) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      try {
        final currentSaved = List<String>.from(currentState.userModel.savedProducts);
        final isSaved = currentSaved.contains(productId);
        
        // Optimistic UI update
        if (isSaved) {
          currentSaved.remove(productId);
        } else {
          currentSaved.add(productId);
        }
        
        final updatedUserModel = currentState.userModel.copyWith(savedProducts: currentSaved);
        emit(AuthAuthenticated(currentState.user, updatedUserModel));
        
        // Background sync to Firestore
        await authRepository.toggleSavedProduct(
          currentState.user.uid,
          productId,
          !isSaved,
        );
      } catch (e) {
        // Revert on error
        emit(currentState);
      }
    }
  }
}
