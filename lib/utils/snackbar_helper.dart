import 'dart:async';
import 'package:flutter/material.dart';

enum AppSnackBarType { info, success, error }

OverlayEntry? _currentEntry;
Timer? _currentTimer;

void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  AppSnackBarType type = AppSnackBarType.info,
}) {
  FocusScope.of(context).unfocus();

  _currentTimer?.cancel();
  _currentEntry?.remove();

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _TopNotification(
      message: message,
      type: type,
      onDismiss: () {
        if (entry.mounted) entry.remove();
        if (_currentEntry == entry) _currentEntry = null;
      },
    ),
  );

  _currentEntry = entry;
  overlay.insert(entry);

  _currentTimer = Timer(duration, () {
    if (entry.mounted) entry.remove();
    if (_currentEntry == entry) _currentEntry = null;
  });
}

class _TopNotification extends StatefulWidget {
  final String message;
  final AppSnackBarType type;
  final VoidCallback onDismiss;

  const _TopNotification({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  Color get _background {
    switch (widget.type) {
      case AppSnackBarType.success:
        return const Color(0xFF2E7D32); // hijau
      case AppSnackBarType.error:
        return const Color(0xFFC62828); // merah
      case AppSnackBarType.info:
        return const Color(0xFF2E2E2E); // netral (sama seperti sebelumnya)
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AppSnackBarType.success:
        return Icons.check_circle_outline;
      case AppSnackBarType.error:
        return Icons.error_outline;
      case AppSnackBarType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      top: _visible ? topPadding + 8 : -100,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: widget.onDismiss,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Icon(_icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.message, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}