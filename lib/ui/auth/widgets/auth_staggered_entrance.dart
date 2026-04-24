import 'dart:async';

import 'package:flutter/material.dart';
import '../../../app/configs/theme.dart';

class AuthStaggeredEntrance extends StatefulWidget {
  const AuthStaggeredEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.fast,
    this.offsetY = 0.03,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final Curve curve;

  @override
  State<AuthStaggeredEntrance> createState() => _AuthStaggeredEntranceState();
}

class _AuthStaggeredEntranceState extends State<AuthStaggeredEntrance> {
  Timer? _timer;
  bool _isVisible = false;

  bool _shouldReduceMotion(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) {
      return false;
    }

    return mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
  }

  void _showChild() {
    if (!mounted || _isVisible) {
      return;
    }

    setState(() {
      _isVisible = true;
    });
  }

  void _scheduleEntrance() {
    _timer?.cancel();

    if (widget.delay == Duration.zero) {
      _showChild();
      return;
    }

    _timer = Timer(widget.delay, _showChild);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_shouldReduceMotion(context)) {
      _timer?.cancel();
      _timer = null;
      _isVisible = true;
      return;
    }

    if (!_isVisible && _timer == null) {
      _scheduleEntrance();
    }
  }

  @override
  void didUpdateWidget(covariant AuthStaggeredEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isVisible || _shouldReduceMotion(context)) {
      return;
    }

    if (oldWidget.delay != widget.delay) {
      _scheduleEntrance();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldReduceMotion(context)) {
      return widget.child;
    }

    return AnimatedSlide(
      duration: widget.duration,
      curve: widget.curve,
      offset: _isVisible ? Offset.zero : Offset(0, widget.offsetY),
      child: AnimatedOpacity(
        duration: widget.duration,
        curve: widget.curve,
        opacity: _isVisible ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}
