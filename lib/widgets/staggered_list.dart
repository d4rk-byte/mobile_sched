import 'package:flutter/material.dart';

import '../app/configs/theme.dart';

/// Wraps a list of widgets in a staggered fade + slide-up entrance.
///
/// Each child appears [staggerDelay] after the previous one.
/// Respects `MediaQuery.disableAnimations` — no animation when true.
///
/// Usage:
/// ```dart
/// StaggeredList(
///   children: [
///     _HeroBanner(...),
///     _InsightGrid(...),
///     _ScheduleSection(...),
///   ],
/// )
/// ```
class StaggeredList extends StatefulWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.staggerDelay = AppMotion.stagger,
    this.itemDuration = AppMotion.medium,
    this.offsetY = 8.0,
  });

  /// The widgets to display with staggered entrance.
  final List<Widget> children;

  /// Delay between each child's animation start. Defaults to 40ms.
  final Duration staggerDelay;

  /// Duration of each individual item's entrance animation. Defaults to 260ms.
  final Duration itemDuration;

  /// Vertical slide distance in logical pixels (slide up from +Y to 0).
  final double offsetY;

  @override
  State<StaggeredList> createState() => _StaggeredListState();
}

class _StaggeredListState extends State<StaggeredList>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _opacities;
  late final List<Animation<Offset>> _offsets;

  @override
  void initState() {
    super.initState();

    final count = widget.children.length;
    _controllers = List.generate(
      count,
      (i) => AnimationController(vsync: this, duration: widget.itemDuration),
    );

    _opacities = _controllers.map((ctrl) {
      return CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic);
    }).toList();

    _offsets = _controllers.map((ctrl) {
      return Tween<Offset>(
        begin: Offset(0, widget.offsetY / 100),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic),
      );
    }).toList();

    _startStagger();
  }

  void _startStagger() {
    for (int i = 0; i < _controllers.length; i++) {
      final delay = widget.staggerDelay * i;
      Future.delayed(delay, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.children,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          FadeTransition(
            opacity: _opacities[i],
            child: SlideTransition(
              position: _offsets[i],
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}

/// Wraps a single widget in a staggered fade + slide-up entrance.
/// Use within a ListView when you have `Padding` wrappers per card.
class StaggeredItem extends StatefulWidget {
  const StaggeredItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = AppMotion.stagger,
    this.itemDuration = AppMotion.medium,
    this.offsetY = 8.0,
  });

  final Widget child;
  final int index;
  final Duration staggerDelay;
  final Duration itemDuration;
  final double offsetY;

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.itemDuration);

    _opacity =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    _offset = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.staggerDelay * widget.index, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (reduceMotion) return widget.child;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
