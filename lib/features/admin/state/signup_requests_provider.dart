import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../data/signup_request_repository.dart';

final signupRequestRepositoryProvider = Provider<SignupRequestRepository>((ref) {
  return SignupRequestRepository(ref.watch(dioClientProvider).dio);
});

/// null = "All"; the queue's default view is 'pending'.
final selectedStatusFilterProvider = StateProvider<String?>((ref) => 'pending');

final signupRequestDetailProvider = FutureProvider.family<SignupRequest, String>((ref, id) {
  return ref.watch(signupRequestRepositoryProvider).getRequest(id);
});

class SignupRequestsState {
  final List<SignupRequest> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  SignupRequestsState({this.items = const [], this.page = 1, this.hasMore = true, this.isLoadingMore = false});
}

class SignupRequestsNotifier extends StateNotifier<AsyncValue<SignupRequestsState>> {
  static const _pageSize = 20;
  final SignupRequestRepository _repository;
  final String? _status;

  SignupRequestsNotifier(this._repository, this._status) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.listRequests(status: _status, page: 1, limit: _pageSize);
      state = AsyncValue.data(SignupRequestsState(items: items, page: 1, hasMore: items.length == _pageSize));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncValue.data(SignupRequestsState(items: current.items, page: current.page, hasMore: true, isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final newItems = await _repository.listRequests(status: _status, page: nextPage, limit: _pageSize);
      state = AsyncValue.data(SignupRequestsState(
        items: [...current.items, ...newItems],
        page: nextPage,
        hasMore: newItems.length == _pageSize,
      ));
    } catch (_) {
      state = AsyncValue.data(SignupRequestsState(items: current.items, page: current.page, hasMore: current.hasMore));
    }
  }

  Future<String?> approve(String id) async {
    try {
      await _repository.approve(id);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> reject(String id, {String? reason}) async {
    try {
      await _repository.reject(id, reason: reason);
      await refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final signupRequestsProvider =
    StateNotifierProvider.autoDispose<SignupRequestsNotifier, AsyncValue<SignupRequestsState>>((ref) {
  final status = ref.watch(selectedStatusFilterProvider);
  return SignupRequestsNotifier(ref.watch(signupRequestRepositoryProvider), status);
});
