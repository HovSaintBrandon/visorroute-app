// NOTE: written against the documented HERE SDK for Flutter v4 API surface
// (per the HERE SDK for Flutter Developer Guide's "Integrate the HERE SDK"
// tutorial) — the `here_sdk` package isn't physically present in
// plugins/here_sdk/ yet (see pubspec.yaml), so this file cannot be resolved
// by `flutter analyze`/`flutter pub get` until that tarball is unzipped in.
// Once it is, run `flutter analyze` on this file first and reconcile any
// drift against the actual installed package's real class/method names.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/mapview.dart';
import '../state/workstation_confirm_provider.dart';

/// Uber-style "confirm your workplace" picker: a real map fills the screen,
/// a fixed pin marks its center, a search bar on top lets the student jump
/// straight to their workplace by name, and they can still pan/zoom to
/// fine-tune before confirming. Full-screen route, not a modal — see
/// MyStatusScreen's banner for the entry point.
class WorkstationConfirmScreen extends ConsumerStatefulWidget {
  const WorkstationConfirmScreen({super.key});

  @override
  ConsumerState<WorkstationConfirmScreen> createState() => _WorkstationConfirmScreenState();
}

class _WorkstationConfirmScreenState extends ConsumerState<WorkstationConfirmScreen> {
  // Nairobi — same last-resort default as the backend's KENYA_FALLBACK_BIAS,
  // used only until the map actually loads a real scene / the student searches.
  static const _fallbackLat = -1.286389;
  static const _fallbackLng = 36.817223;

  HereMapController? _hereMapController;
  final _searchController = TextEditingController();
  String? _selectedAddress;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(HereMapController controller) {
    _hereMapController = controller;
    const distanceToEarthInMeters = 2000.0;
    final measure = MapMeasure(MapMeasureKind.distanceInMeters, distanceToEarthInMeters);
    controller.camera.lookAtPointWithMeasure(GeoCoordinates(_fallbackLat, _fallbackLng), measure);
    controller.mapScene.loadSceneForMapScheme(MapScheme.normalDay, (MapError? error) {
      if (error != null) debugPrint('Map scene not loaded: $error');
    });
  }

  void _flyTo(double lat, double lng) {
    final controller = _hereMapController;
    if (controller == null) return;
    final measure = MapMeasure(MapMeasureKind.distanceInMeters, 300.0);
    controller.camera.lookAtPointWithMeasure(GeoCoordinates(lat, lng), measure);
  }

  Future<void> _confirm() async {
    final controller = _hereMapController;
    if (controller == null) return;

    // The selected point is wherever the fixed center pin is pointing right
    // now — i.e. the camera's current target, however the student got there
    // (a search-result tap, or manually panning/zooming).
    final target = controller.camera.state.targetCoordinates;

    final success = await ref.read(workstationConfirmProvider.notifier).confirmLocation(
          lat: target.latitude,
          lng: target.longitude,
          address: _selectedAddress,
        );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final error = ref.read(workstationConfirmProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to save your location.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(workstationSearchProvider);
    final confirmState = ref.watch(workstationConfirmProvider);

    return Scaffold(
      body: Stack(
        children: [
          HereMap(onMapCreated: _onMapCreated),

          // Fixed center pin — the map moves underneath it, not the other way
          // around, same convention as most rideshare pickup pickers.
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36), // visually anchor the pin *tip* to the exact center
                child: Icon(Icons.location_pin, size: 48, color: Colors.redAccent),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Colors.white),
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(28),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search for your workplace',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: searchState.isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onChanged: (query) => ref.read(workstationSearchProvider.notifier).search(query),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (searchState.results.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 260),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: searchState.results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final result = searchState.results[index];
                            return ListTile(
                              leading: const Icon(Icons.place_outlined),
                              title: Text(result.title),
                              subtitle: Text(result.formattedAddress, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () {
                                _flyTo(result.lat, result.lng);
                                setState(() => _selectedAddress = result.formattedAddress);
                                _searchController.text = result.title;
                                ref.read(workstationSearchProvider.notifier).clear();
                                FocusScope.of(context).unfocus();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                      'Drag the map so the pin sits exactly on your workplace, then confirm.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: confirmState.isSaving ? null : _confirm,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: confirmState.isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Confirm this location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
