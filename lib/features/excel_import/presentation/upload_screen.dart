import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_nav_bar.dart';
import '../state/import_batch_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  String _selectedScope = 'zone';
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null || result.files.isEmpty) return;
    setState(() => _selectedFile = result.files.single);
  }

  Future<void> _submitUpload() async {
    final path = _selectedFile?.path;
    if (path == null) return;
    setState(() => _isUploading = true);

    final batchId = await ref.read(importBatchProvider.notifier).startUpload(
          filePath: path,
          scope: _selectedScope,
        );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (batchId != null) {
      context.go('/import/$batchId/review');
    } else {
      final error = ref.read(importBatchProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Upload failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navItems = [
      const NavItem(activeIcon: Icons.map, inactiveIcon: Icons.map_outlined, label: 'Zone Map', route: '/map'),
      const NavItem(activeIcon: Icons.file_upload, inactiveIcon: Icons.file_upload_outlined, label: 'Excel Import', route: '/import/history'),
      const NavItem(activeIcon: Icons.bar_chart, inactiveIcon: Icons.bar_chart_outlined, label: 'Reports', route: '/reports'),
      const NavItem(activeIcon: Icons.notifications, inactiveIcon: Icons.notifications_outlined, label: 'Alerts', route: '/notifications'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workstation Excel Batch Import'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.table_chart_rounded, color: theme.primaryColor, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Upload Student Workstation Roster',
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload an .xlsx file containing Reg No, Student Name, Workstation Location, and Coordinates.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),

                        // File Drag-Drop / Pick container
                        GestureDetector(
                          onTap: _pickFile,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: theme.primaryColor.withOpacity(0.4),
                                style: BorderStyle.solid,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 48, color: theme.primaryColor),
                                const SizedBox(height: 10),
                                Text(
                                  _selectedFile?.name ?? 'Tap to Select Excel File (.xlsx)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                if (_selectedFile != null)
                                  Text(
                                    'File size: ${(_selectedFile!.size / 1024).toStringAsFixed(0)} KB • Ready to upload',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text('Import Scope', style: theme.textTheme.titleMedium),
                RadioListTile<String>(
                  title: const Text('My Assigned Zone Only'),
                  value: 'zone',
                  groupValue: _selectedScope,
                  activeColor: theme.primaryColor,
                  onChanged: (val) => setState(() => _selectedScope = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Full University Roster (Admin only)'),
                  value: 'full',
                  groupValue: _selectedScope,
                  activeColor: theme.primaryColor,
                  onChanged: (val) => setState(() => _selectedScope = val!),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_selectedFile == null || _isUploading) ? null : _submitUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: isDark ? Colors.black87 : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Upload & Process Batch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Custom Floating Pill Nav Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              currentIndex: 1,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/map');
                    break;
                  case 1:
                    context.go('/import/history');
                    break;
                  case 2:
                    context.go('/reports');
                    break;
                  case 3:
                    context.go('/notifications');
                    break;
                }
              },
              items: navItems,
            ),
          ),
        ],
      ),
    );
  }
}
