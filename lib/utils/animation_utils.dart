/**
 * 动画工具类
 * 提供通用的动画效果和动画曲线
 * 统一管理项目中的动画配置
 */

import 'package:flutter/material.dart';

/// 动画工具类 - 提供各种预定义的动画效果
class AnimationUtils {

  /// 动画持续时间常量
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration verySlowDuration = Duration(milliseconds: 800);

  /// 常用动画曲线
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve backCurve = Curves.easeOutBack;

  /// 创建淡入动画
  /// [controller] 动画控制器
  /// [begin] 起始透明度 (默认 0.0)
  /// [end] 结束透明度 (默认 1.0)
  /// [curve] 动画曲线 (默认 easeInOut)
  static Animation<double> createFadeAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 创建滑动动画
  /// [controller] 动画控制器
  /// [begin] 起始偏移 (默认从右侧滑入)
  /// [end] 结束偏移 (默认 Offset.zero)
  /// [curve] 动画曲线 (默认 elasticOut)
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Curve curve = elasticCurve,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 创建缩放动画
  /// [controller] 动画控制器
  /// [begin] 起始缩放比例 (默认 0.8)
  /// [end] 结束缩放比例 (默认 1.0)
  /// [curve] 动画曲线 (默认 bounceOut)
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 0.8,
    double end = 1.0,
    Curve curve = bounceCurve,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 创建旋转动画
  /// [controller] 动画控制器
  /// [begin] 起始角度 (默认 0.0)
  /// [end] 结束角度 (默认 1.0, 表示一整圈)
  /// [curve] 动画曲线 (默认 linear)
  static Animation<double> createRotationAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.linear,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// 创建延迟动画 - 用于列表项依次出现的效果
  /// [controller] 动画控制器
  /// [delay] 延迟时间比例 (0.0 - 1.0)
  /// [curve] 动画曲线
  static Animation<double> createDelayedAnimation(
    AnimationController controller,
    double delay, {
    Curve curve = defaultCurve,
  }) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Interval(delay, 1.0, curve: curve),
    ));
  }

  /// 创建组合动画控制器
  /// [vsync] TickerProvider
  /// [duration] 动画持续时间
  static AnimationController createController(
    TickerProvider vsync, {
    Duration duration = normalDuration,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }
}

/// 预定义的动画组件
class AnimatedWidgets {

  /// 带淡入效果的组件
  /// [child] 子组件
  /// [animation] 动画对象
  static Widget fadeIn(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// 带滑入效果的组件
  /// [child] 子组件
  /// [animation] 滑动动画对象
  static Widget slideIn(Widget child, Animation<Offset> animation) {
    return SlideTransition(
      position: animation,
      child: child,
    );
  }

  /// 带缩放效果的组件
  /// [child] 子组件
  /// [animation] 缩放动画对象
  static Widget scaleIn(Widget child, Animation<double> animation) {
    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  /// 带旋转效果的组件
  /// [child] 子组件
  /// [animation] 旋转动画对象
  static Widget rotateIn(Widget child, Animation<double> animation) {
    return RotationTransition(
      turns: animation,
      child: child,
    );
  }

  /// 组合动画效果 - 淡入 + 滑入 + 缩放
  /// [child] 子组件
  /// [fadeAnimation] 淡入动画
  /// [slideAnimation] 滑入动画
  /// [scaleAnimation] 缩放动画
  static Widget combineAnimations(
    Widget child,
    Animation<double> fadeAnimation,
    Animation<Offset> slideAnimation,
    Animation<double> scaleAnimation,
  ) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      ),
    );
  }
}

/// 自定义动画曲线
class CustomCurves {

  /// 自定义弹跳曲线
  static const Curve customBounce = Curves.bounceOut;

  /// 自定义弹性曲线
  static const Curve customElastic = Curves.elasticOut;

  /// 自定义回弹曲线
  static const Curve customBack = Curves.easeOutBack;

  /// 缓慢开始，快速结束
  static const Curve slowFast = Curves.easeInQuart;

  /// 快速开始，缓慢结束
  static const Curve fastSlow = Curves.easeOutQuart;

  /// 平滑的S形曲线
  static const Curve smooth = Curves.easeInOutCubic;
}

/// 预定义的页面转场动画
class PageTransitions {

  /// 从右侧滑入的页面转场
  static Widget slideFromRight(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// 从底部滑入的页面转场
  static Widget slideFromBottom(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// 缩放淡入的页面转场
  static Widget scaleIn(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  /// 旋转淡入的页面转场
  static Widget rotateIn(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.5,
        end: 1.0,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

/// 加载动画组件
class LoadingAnimations {

  /// 旋转的加载指示器
  /// [size] 大小
  /// [color] 颜色
  static Widget rotatingLoader({
    double size = 50.0,
    Color color = Colors.blue,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 3.0,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  /// 脉冲效果的加载指示器
  /// [child] 子组件
  /// [controller] 动画控制器
  static Widget pulsingLoader(Widget child, AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Transform.scale(
          scale: 1.0 + 0.2 * (controller.value),
          child: Opacity(
            opacity: 1.0 - 0.3 * controller.value,
            child: child,
          ),
        );
      },
    );
  }

  /// 波浪效果的加载指示器
  /// [controller] 动画控制器
  /// [color] 颜色
  static Widget waveLoader(AnimationController controller, {Color color = Colors.blue}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            double delay = index * 0.2;
            double animationValue = (controller.value - delay).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8 + 16 * animationValue,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }
}
