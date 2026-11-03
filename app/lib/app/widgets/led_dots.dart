import 'package:flutter/material.dart';
import 'package:hopin/app/theme.dart';

/// A row of board lights: the Board look's signature (docs/PLAN.md, Look).
///
/// [lit] lights are amber, the rest dim. With [lightUp], the lit ones come on
/// one after another the first time the row appears: one controller with an
/// interval per light. With reduced motion they are simply on. Later changes
/// to [lit] fade each light in or out.
class LedDots extends StatefulWidget {
  const LedDots({
    super.key,
    required this.count,
    int? lit,
    this.lightUp = false,
    this.size = 8,
  }) : lit = lit ?? count;

  final int count;
  final int lit;
  final bool lightUp;
  final double size;

  @override
  State<LedDots> createState() => _LedDotsState();
}

class _LedDotsState extends State<LedDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.lightUp ? 0 : 1,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !widget.lightUp) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.duration = context.motion.slow * 2;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final motion = context.motion;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.count; i++)
            Padding(
              padding: EdgeInsetsDirectional.only(
                end: i == widget.count - 1 ? 0 : widget.size * 0.7,
              ),
              child: AnimatedContainer(
                duration: motion.base,
                curve: motion.ease,
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < widget.lit
                      ? Color.lerp(
                          colors.amberDim,
                          colors.amber,
                          Interval(
                            i / widget.count,
                            (i + 1) / widget.count,
                          ).transform(_controller.value),
                        )
                      : colors.amberDim,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
