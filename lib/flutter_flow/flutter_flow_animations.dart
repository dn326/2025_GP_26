// lib/flutter_flow/flutter_flow_animations.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' as fa;

enum AnimationTrigger { onPageLoad, onActionTrigger, onHover, onTap }

class AnimationInfo {
  AnimationInfo({
    required this.trigger,
    required this.effects,
    this.loop = false,
    this.delay,
  });

  final AnimationTrigger trigger;
  final List<fa.Effect<dynamic>> effects;
  final bool loop;
  final Duration? delay;
}

void setupAnimations(List<AnimationInfo> animations, TickerProvider vsync) {}

extension FFAnimateExtensions on Widget {
  Widget animateOnPageLoad(AnimationInfo info) {
    return fa.Animate(
      effects: info.effects,
      delay: info.delay,
      child: this, // ← نستخدم التأخير هنا مباشرة
    );
  }

  Widget animateOnActionTrigger(AnimationInfo info) {
    return fa.Animate(effects: info.effects, delay: info.delay, child: this);
  }

  Widget animateOnHover(AnimationInfo info) {
    return MouseRegion(
      onEnter: (_) {},
      child: fa.Animate(effects: info.effects, delay: info.delay, child: this),
    );
  }

  Widget animateOnTap(AnimationInfo info) {
    return GestureDetector(
      onTap: () {},
      child: fa.Animate(effects: info.effects, delay: info.delay, child: this),
    );
  }
}
