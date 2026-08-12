import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../map_dashboard/state/zone_students_provider.dart';
import '../../route_run/state/route_run_provider.dart';
import '../state/visit_form_provider.dart';

class VisitLoggingSheet extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;
  final String workstationName;

  const VisitLoggingSheet({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.workstationName,
  });

  @override
  ConsumerState<VisitLoggingSheet> createState() => _VisitLoggingSheetState();
}

class _VisitLoggingSheetState extends ConsumerState<VisitLoggingSheet> {
  static const _maxPhotoBytes = 8 * 1024 * 1024;

  bool _isAssessed = true;
  double _score = 85;
  final _notesController = TextEditingController(text: 'Student present at station. Logbook signed and verified.');
  XFile? _pickedPhoto;
  bool _isPickingPhoto = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() => _isPickingPhoto = true);
    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo == null) return;

      final size = await File(photo.path).length();
      if (size > _maxPhotoBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo is larger than 8MB — please retake at a lower quality.')),
          );
        }
        return;
      }
      setState(() => _pickedPhoto = photo);
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _submitForm() async {
    if (ref.read(visitFormProvider).isSubmitting) return;

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not get your location: $e')));
      }
      return;
    }

    final ok = await ref.read(visitFormProvider.notifier).submitVisit(
          studentId: widget.studentId,
          type: _isAssessed ? 'assessment' : 'visit',
          score: _isAssessed ? _score : null,
          notes: _notesController.text,
          supervisorLat: position.latitude,
          supervisorLng: position.longitude,
        );

    if (!ok || !mounted) return;

    // Photo upload is independent of the already-saved visit above — its
    // failure only surfaces a retryable warning, it doesn't undo anything.
    if (_pickedPhoto != null) {
      final photoOk = await ref.read(visitFormProvider.notifier).uploadPhoto(_pickedPhoto!.path);
      if (!photoOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(visitFormProvider).photoErrorMessage ?? 'Photo upload failed. You can retry later.',
            ),
          ),
        );
      }
    }

    if (!mounted) return;
    ref.invalidate(zoneStudentsProvider);
    // Assumes POST /visits does NOT auto-advance the route pointer server
    // side — pending explicit confirmation. If the server turns out to
    // already advance on a normal visit, this call needs to be removed
    // (otherwise every visit would double-skip a stop).
    await ref.read(routeRunProvider.notifier).advanceToNext();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Visit for ${widget.studentName} logged! Route advanced to next pin.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final formState = ref.watch(visitFormProvider);
    final isSubmitting = formState.isSubmitting;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Log Workstation Visit', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(widget.studentName, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(widget.workstationName, style: theme.textTheme.bodyMedium),
              const Divider(height: 24),

              // Visited / Assessed Toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: theme.primaryColor,
                title: const Text('Formal Assessment Conducted', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Toggle on if grading rubrics were completed during this visit'),
                value: _isAssessed,
                onChanged: (val) => setState(() => _isAssessed = val),
              ),

              if (_isAssessed) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Assessment Score (0 - 100):', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _score.toStringAsFixed(0),
                        style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _score,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: theme.primaryColor,
                  onChanged: (val) => setState(() => _score = val),
                ),
              ],

              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Field Supervision Notes',
                  hintText: 'Enter observation details, work environment report...',
                ),
              ),

              const SizedBox(height: 14),

              // Photo Attachment button
              OutlinedButton.icon(
                onPressed: (isSubmitting || _isPickingPhoto) ? null : _pickPhoto,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isPickingPhoto
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(
                        _pickedPhoto != null ? Icons.check_circle : Icons.camera_alt_outlined,
                        color: _pickedPhoto != null ? Colors.green : theme.primaryColor,
                      ),
                label: Text(_pickedPhoto != null ? 'Photo Attached (${_pickedPhoto!.name})' : 'Attach Workstation Photo Proof'),
              ),

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: isDark ? Colors.black87 : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Save & Advance Route Pin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              if (formState.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(formState.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
