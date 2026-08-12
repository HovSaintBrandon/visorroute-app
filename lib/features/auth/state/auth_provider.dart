import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/token_storage.dart';
import '../../map_dashboard/state/supervisor_profile_provider.dart';
import '../../student_status/state/student_status_provider.dart';
import '../data/auth_repository.dart';

class AuthState {
  final bool isLoggedIn;
  final UserRole role;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.isLoggedIn = false,
    this.role = UserRole.student,
    this.userId,
    this.userName,
    this.userEmail,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserRole? role,
    String? userName,
    String? userId,
    String? userEmail,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      role: role ?? this.role,
      userName: userName ?? this.userName,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._tokenStorage, this._ref) : super(AuthState()) {
    // If the interceptor exhausts a refresh attempt mid-session, it has no
    // Riverpod access of its own — this hook lets it force us back to
    // logged-out instead of the UI silently keeping stale "logged in" state.
    _ref.read(dioClientProvider).authInterceptor.onSessionExpired = () {
      state = AuthState();
    };
  }

  Future<bool> login(String identifier, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _authRepository.login(identifier: identifier, password: password);

      await _tokenStorage.saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken);
      _ref.read(dioClientProvider).authInterceptor.setTokens(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
          );

      // Login returns no user identity at all — GET /students/me or
      // GET /supervisors/me is the only way to learn who just logged in.
      String? userId;
      String? userName;
      String? userEmail;
      if (result.role == UserRole.student) {
        final student = await _ref.read(studentStatusRepoProvider).getMyStatus();
        userId = student.id;
        userName = student.fullName;
      } else if (result.role == UserRole.supervisor) {
        final supervisor = await _ref.read(supervisorRepositoryProvider).getMe();
        userId = supervisor.id;
        userName = supervisor.name;
        userEmail = supervisor.email;
      }

      state = AuthState(
        isLoggedIn: true,
        role: result.role,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = AuthState(
        isLoading: false,
        errorMessage: e is ApiException ? e.message : 'Unable to sign in. Please check your connection and try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      await _authRepository.logout(refreshToken);
    }
    await _tokenStorage.clear();
    _ref.read(dioClientProvider).authInterceptor.clearTokens();
    state = AuthState();
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(dioClientProvider).dio));

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref.watch(tokenStorageProvider), ref);
});
