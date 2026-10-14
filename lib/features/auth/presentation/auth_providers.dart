import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_entity.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Stream current Firebase User auth state
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Stream active UserEntity profile document
final currentUserProfileProvider = StreamProvider<UserEntity?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);
  final repo = ref.watch(authRepositoryProvider);
  return repo.streamUserProfile(authUser.uid);
});

/// Async notifier for Auth operations
class AuthControllerNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signIn(email: email, password: password),
    );
  }

  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUp(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthControllerNotifier, void>(
        () => AuthControllerNotifier());
