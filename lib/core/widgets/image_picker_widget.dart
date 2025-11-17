import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../flutter_flow/flutter_flow_theme.dart';

class FeqImagePickerWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String? imageUrl, File? file, Uint8List? bytes) onImagePicked;
  final VoidCallback? onTap;
  final double size;
  final String assetPlaceholder;
  final bool isUploading;

  const FeqImagePickerWidget({
    required this.onImagePicked,
    this.initialImageUrl,
    this.onTap,
    this.size = 100,
    this.assetPlaceholder = 'assets/images/person_icon.png',
    this.isUploading = false,
    super.key,
  });

  @override
  State<FeqImagePickerWidget> createState() => _FeqImagePickerWidgetState();
}

class _FeqImagePickerWidgetState extends State<FeqImagePickerWidget> {
  late String? _imageUrl;
  File? _pickedImage;
  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    _initImageUrl();
  }

  @override
  void didUpdateWidget(FeqImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialImageUrl != widget.initialImageUrl) {
      _initImageUrl();
    }
  }

  void _initImageUrl() {
    _imageUrl = widget.initialImageUrl;
  }

  Widget _buildImageWidget() {
    final theme = FlutterFlowTheme.of(context);
    final size = widget.size;

    Widget imageWidget;

    if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
      imageWidget = Image.memory(
        _pickedBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset(widget.assetPlaceholder, width: size, height: size, fit: BoxFit.cover),
      );
    } else if (_pickedImage != null) {
      imageWidget = Image.file(
        _pickedImage!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset(widget.assetPlaceholder, width: size, height: size, fit: BoxFit.cover),
      );
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      if (_imageUrl!.startsWith('data:')) {
        // Data URL
        final base64String = _imageUrl!.split(',').last;
        final bytes = base64Decode(base64String);
        imageWidget = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset(widget.assetPlaceholder, width: size, height: size, fit: BoxFit.cover),
        );
      } else if (_imageUrl!.startsWith('file://')) {
        // File URL
        final filePath = _imageUrl!.replaceFirst('file://', '');
        imageWidget = Image.file(
          File(filePath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset(widget.assetPlaceholder, width: size, height: size, fit: BoxFit.cover),
        );
      } else {
        // Network URL
        imageWidget = CachedNetworkImage(
          imageUrl: _imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, second) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (_, second, third) =>
              Image.asset(widget.assetPlaceholder, width: size, height: size, fit: BoxFit.cover),
        );
      }
    } else {
      imageWidget = Image.asset(widget.assetPlaceholder, width: size, height: size, fit: BoxFit.cover);
    }

    return Container(
      key: ValueKey(_imageUrl ?? _pickedBytes ?? _pickedImage),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.tertiary,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.iconsOnLightBackgroundsMainButtonsOnLightBackgrounds.withValues(alpha: 0.2),
          width: 3,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipOval(child: imageWidget),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isUploading ? null : widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildImageWidget(),
          if (widget.isUploading)
            SizedBox(
              width: widget.size * 0.35,
              height: widget.size * 0.35,
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
        ],
      ),
    );
  }
}