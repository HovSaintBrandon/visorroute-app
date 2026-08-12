import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared_models/route_run.dart';
import '../../map_dashboard/state/supervisor_profile_provider.dart';
import '../data/route_repository.dart';

final routeRepositoryProvider = Provider((ref) => RouteRepository(ref.watch(dioClientProvider).dio));

class RouteRunState {
  final RouteRun? route;
  final bool isStarting;
  final String? errorMessage;

  RouteRunState({this.route, this.isStarting = false, this.errorMessage});
}

class RouteRunNotifier extends StateNotifier<RouteRunState> {
  final RouteRepository _repository;
  final Ref _ref;
  Timer? _locationPingTimer;

  RouteRunNotifier(this._repository, this._ref) : super(RouteRunState());

  /// Starting a route needs a real GPS fix — the server picks every
  /// unvisited/geocoded student in the zone itself from that start point.
  /// The HERE solve is synchronous and can take several seconds, so
  /// `isStarting` is meant to drive a blocking loading state, not a
  /// dismissible spinner.
  Future<bool> startRoute(String zoneId) async {
    state = RouteRunState(isStarting: true);
    try {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final created = await _repository.optimizeRoute(
        zoneId: zoneId,
        lat: position.latitude,
        lng: position.longitude,
      );
      // optimize's response leaves stops unpopulated — fetch detail to render them.
      final detail = await _repository.getRouteDetail(created.id);
      state = RouteRunState(route: detail);
      _startLocationPing();
      return true;
    } catch (e) {
      state = RouteRunState(errorMessage: e is ApiException ? e.message : 'Failed to start route: $e');
      return false;
    }
  }

  Future<void> advanceToNext() async {
    final current = state.route;
    if (current == null) return;
    final updated = await _repository.advanceStep(current.id);
    state = RouteRunState(route: current.copyWith(currentIndex: updated.currentIndex, status: updated.status));
    if (!(state.route?.isActive ?? false)) _stopLocationPing();
  }

  Future<void> abandonRoute() async {
    final current = state.route;
    if (current == null) return;
    final updated = await _repository.abandonRoute(current.id);
    state = RouteRunState(route: current.copyWith(currentIndex: updated.currentIndex, status: updated.status));
    _stopLocationPing();
  }

  /// 30-60s is the confirmed sweet spot — the server's ETA-recompute only
  /// actually fires every ~2min/~300m moved regardless, so more frequent
  /// pings are harmless but wasted.
  void _startLocationPing() {
    _locationPingTimer?.cancel();
    _locationPingTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      if (state.route?.isActive != true) return;
      try {
        final position = await Geolocator.getCurrentPosition();
        await _ref.read(supervisorRepositoryProvider).pingLocation(lat: position.latitude, lng: position.longitude);
      } catch (_) {
        // Best-effort — a missed ping just delays the next ETA recompute.
      }
    });
  }

  void _stopLocationPing() {
    _locationPingTimer?.cancel();
    _locationPingTimer = null;
  }

  @override
  void dispose() {
    _stopLocationPing();
    super.dispose();
  }
}

final routeRunProvider = StateNotifierProvider<RouteRunNotifier, RouteRunState>((ref) {
  return RouteRunNotifier(ref.watch(routeRepositoryProvider), ref);
});
