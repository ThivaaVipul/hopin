import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';

/// Rolls [child] up and out for the next one whenever [value] changes, like
/// a flip board's numbers (docs/PLAN.md, Look). With reduced motion the new
/// one simply appears.
class Rolling extends StatelessWidget {
  const Rolling({super.key, required this.value, required this.child});

  final Object value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : motion.base,
      switchInCurve: motion.ease,
      switchOutCurve: motion.ease,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.bottomStart,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey(value);
        return ClipRect(
          child: SlideTransition(
            position: Tween(
              begin: Offset(0, incoming ? 0.7 : -0.7),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey(value), child: child),
    );
  }
}
