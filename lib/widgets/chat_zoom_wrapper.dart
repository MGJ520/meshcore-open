import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/chat_text_scale_service.dart';

/// Gesture wrapper that exposes two-finger pinch-to-zoom for chat scrollables.
/// Double-tap resets the scale. Only the wrapper itself listens to gestures;
/// child scrollables keep their normal touch handling.
class ChatZoomWrapper extends StatelessWidget {
  ChatZoomWrapper({super.key, required this.child, this.onDoubleTap});

  final Widget child;
  final VoidCallback? onDoubleTap;
  final _ZoomGestureState _state = _ZoomGestureState();

  @override
  Widget build(BuildContext context) {
    final service = context.read<ChatTextScaleService>();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        service.reset();
        onDoubleTap?.call();
      },
      onScaleStart: (details) {
        if (details.pointerCount != 2) return;
        _state.startScale = service.scale;
      },
      onScaleUpdate: (details) {
        if (details.pointerCount != 2) return;
        final baseScale = _state.startScale ?? service.scale;
        service.setScale(baseScale * details.scale);
      },
      onScaleEnd: (_) {
        _state.startScale = null;
      },
      child: child,
    );
  }
}

class _ZoomGestureState {
  double? startScale;
}
