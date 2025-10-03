import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../providers/user_provider.dart';

class UploadScreenshotsPage extends ConsumerStatefulWidget {
  const UploadScreenshotsPage({super.key});

  @override
  ConsumerState<UploadScreenshotsPage> createState() =>
      _UploadScreenshotsPageState();
}

class _UploadScreenshotsPageState
    extends ConsumerState<UploadScreenshotsPage> {
  final ImagePicker _picker = ImagePicker();
  final List<_SelectedImage> _selectedImages = [];
  bool _isUploading = false;
  bool _isPicking = false;
  String? _errorMessage;

  Future<void> _pickImages() async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
      );

      if (!mounted) return;

      if (pickedFiles.isEmpty) {
        setState(() {
          _isPicking = false;
        });
        return;
      }

      final newImages = <_SelectedImage>[];
      for (final file in pickedFiles) {
        final bytes = await file.readAsBytes();
        newImages.add(_SelectedImage(file: file, bytes: bytes));
      }

      if (!mounted) return;

      setState(() {
        _selectedImages.addAll(newImages);
        _isPicking = false;
      });
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() {
        _isPicking = false;
        _errorMessage = 'Kunde inte öppna bildgalleriet. Försök igen.';
      });
    }
  }

  Future<void> _uploadSelected() async {
    if (_isUploading) return;

    final userState = ref.read(userIdProvider);
    final userId = userState.userId;

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingen användare hittades. Logga in och försök igen.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lägg till minst en bild innan du laddar upp.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      for (final image in List<_SelectedImage>.from(_selectedImages)) {
        final result = await saveIosScreenTime(
          userId: userId,
          imageBytes: image.bytes,
          fileName: image.file.name,
        );

        if (result == null) {
          throw Exception('Servern accepterade inte bilden ${image.file.name}.');
        }
      }

      if (!mounted) return;

      setState(() {
        _selectedImages.clear();
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bilderna laddades upp!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      const message =
          'Uppladdningen misslyckades. Kontrollera internetanslutningen och försök igen.';
      setState(() {
        _errorMessage = message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$message\n$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ladda upp skärmbilder'),
      ),
      body: SafeArea(
        child: userState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_isUploading) const LinearProgressIndicator(minHeight: 3),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Välj skärmbilder från ditt galleri och ladda upp dem till studien.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed:
                                (_isUploading || _isPicking) ? null : _pickImages,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(
                                _isPicking ? 'Öppnar galleri...' : 'Välj skärmbilder'),
                          ),
                          if (_isPicking) ...[
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text('Öppnar galleri...'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (_selectedImages.isEmpty)
                            _EmptySelectionNotice(isLoggedIn: userState.userId != null)
                          else
                            _SelectedImageGrid(
                              images: _selectedImages,
                              onRemove: _removeImage,
                            ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 24),
                            _ErrorBanner(message: _errorMessage!),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: (_isUploading || _isPicking) ? null : _uploadSelected,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(_isUploading
                              ? 'Laddar upp...'
                              : 'Ladda upp ${_selectedImages.isEmpty ? '' : '(${_selectedImages.length})'}'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SelectedImage {
  final XFile file;
  final Uint8List bytes;

  _SelectedImage({required this.file, required this.bytes});
}

class _SelectedImageGrid extends StatelessWidget {
  final List<_SelectedImage> images;
  final void Function(int index) onRemove;

  const _SelectedImageGrid({
    required this.images,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valda skärmbilder (${images.length}):',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final image = images[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      image.bytes,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => onRemove(index),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmptySelectionNotice extends StatelessWidget {
  final bool isLoggedIn;

  const _EmptySelectionNotice({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
  color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inga bilder valda ännu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isLoggedIn
                ? 'Tryck på "Välj skärmbilder" för att hämta bilder från din fotoström.'
                : 'Logga in för att kunna ladda upp skärmbilder.',
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        ],
      ),
    );
  }
}