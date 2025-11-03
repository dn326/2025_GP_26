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
      child: this,
      effects: info.effects,
      delay: info.delay, // ← نستخدم التأخير هنا مباشرة
    );
  }

  Widget animateOnActionTrigger(AnimationInfo info) {
    return fa.Animate(child: this, effects: info.effects, delay: info.delay);
  }

  Widget animateOnHover(AnimationInfo info) {
    return MouseRegion(
      onEnter: (_) {},
      child: fa.Animate(child: this, effects: info.effects, delay: info.delay),
    );
  }

  Widget animateOnTap(AnimationInfo info) {
    return GestureDetector(
      onTap: () {},
      child: fa.Animate(child: this, effects: info.effects, delay: info.delay),
    );
  }
}
