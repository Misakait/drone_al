import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/amap2.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // 添加动画混入类

  // 动画控制器
  late AnimationController _animationController;
  // 动画声明
  late Animation<double> _fadeAnimation; // 淡入动画
  late Animation<Offset> _slideAnimation; // 滑动动画
  late Animation<double> _scaleAnimation; // 缩放动画

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // 动画持续时间
      vsync: this,
    );

    // 初始化淡入动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn), // 前60%时间执行淡入
    ));

    // 初始化滑动动画 - 从上方滑入
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5), // 从上方开始
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut), // 20%-80%时间执行滑动
    ));

    // 初始化缩放动画
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.bounceOut), // 40%-100%时间执行缩放
    ));

    // 启动动画
    _startAnimation();
  }

  // 启动页面加载动画
  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose(); // 释放动画控制器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0), // 从左侧滑入
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
          )),
          child: const Text("无人机监控中心"),
        ),
        elevation: 0, // 移除阴影
        centerTitle: true, // 居中标题
      ),
      body: Stack(
        children: [
          // 添加渐变背景
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.1),
                  Colors.blue.withValues(alpha: 0.05),
                  Colors.white,
                ],
                stops: const [0.0, 0.5, 1.0], // 渐变停止点
              ),
            ),
          ),

          // 主要内容区域 - 地图组件
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      margin: const EdgeInsets.all(8), // 添加边距
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12), // 圆角容器
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4), // 阴影效果
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ShowMapPageBody(), // 地图组件
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 悬浮信息卡片 - 显示系统状态
          // Positioned(
          //   top: 20,
          //   left: 20,
          //   right: 20,
          //   child: AnimatedBuilder(
          //     animation: _animationController,
          //     builder: (context, child) {
          //       return SlideTransition(
          //         position: Tween<Offset>(
          //           begin: const Offset(0, -1), // 从上方滑入
          //           end: Offset.zero,
          //         ).animate(CurvedAnimation(
          //           parent: _animationController,
          //           curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
          //         )),
          //         child: FadeTransition(
          //           opacity: Tween<double>(
          //             begin: 0.0,
          //             end: 1.0,
          //           ).animate(CurvedAnimation(
          //             parent: _animationController,
          //             curve: const Interval(0.7, 1.0),
          //           )),
          //           child: Card(
          //             elevation: 8,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(16),
          //             ),
          //             child: Container(
          //               padding: const EdgeInsets.all(16),
          //               decoration: BoxDecoration(
          //                 borderRadius: BorderRadius.circular(16),
          //                 gradient: LinearGradient(
          //                   colors: [
          //                     Colors.blue.withValues(alpha: 0.8),
          //                     Colors.indigo.withValues(alpha: 0.8),
          //                   ],
          //                 ),
          //               ),
          //               child: Row(
          //                 children: [
          //                   // 状态指示器 - 带脉冲动画
          //                   AnimatedBuilder(
          //                     animation: _animationController,
          //                     builder: (context, child) {
          //                       return Transform.scale(
          //                         scale: 1.0 +
          //                             0.1 *
          //                                 ((_animationController.value * 4) %
          //                                     1), // 脉冲效果
          //                         child: Container(
          //                           width: 12,
          //                           height: 12,
          //                           decoration: const BoxDecoration(
          //                             color: Colors.green,
          //                             shape: BoxShape.circle,
          //                           ),
          //                         ),
          //                       );
          //                     },
          //                   ),
          //                   const SizedBox(width: 12),
          //                   const Expanded(
          //                     child: Text(
          //                       '系统运行正常',
          //                       style: TextStyle(
          //                         color: Colors.white,
          //                         fontWeight: FontWeight.bold,
          //                         fontSize: 16,
          //                       ),
          //                     ),
          //                   ),
          //                   // 信号强度图标 - 带波动动画
          //                   AnimatedBuilder(
          //                     animation: _animationController,
          //                     builder: (context, child) {
          //                       return Transform.rotate(
          //                         angle: 0.1 *
          //                             ((_animationController.value * 2) %
          //                                 1 - 0.5), // 轻微摆动
          //                         child: const Icon(
          //                           Icons.signal_cellular_4_bar,
          //                           color: Colors.white,
          //                           size: 20,
          //                         ),
          //                       );
          //                     },
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),

          // 底部控制面板
          // Positioned(
          //   bottom: 20,
          //   left: 20,
          //   right: 20,
          //   child: AnimatedBuilder(
          //     animation: _animationController,
          //     builder: (context, child) {
          //       return SlideTransition(
          //         position: Tween<Offset>(
          //           begin: const Offset(0, 1), // 从下方滑入
          //           end: Offset.zero,
          //         ).animate(CurvedAnimation(
          //           parent: _animationController,
          //           curve: const Interval(0.8, 1.0, curve: Curves.easeOutBack),
          //         )),
          //         child: FadeTransition(
          //           opacity: Tween<double>(
          //             begin: 0.0,
          //             end: 1.0,
          //           ).animate(CurvedAnimation(
          //             parent: _animationController,
          //             curve: const Interval(0.9, 1.0),
          //           )),
          //           child: Card(
          //             elevation: 12,
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(20),
          //             ),
          //             child: Container(
          //               padding: const EdgeInsets.symmetric(
          //                 horizontal: 20,
          //                 vertical: 16,
          //               ),
          //               decoration: BoxDecoration(
          //                 borderRadius: BorderRadius.circular(20),
          //                 color: Colors.white,
          //               ),
          //               child: Row(
          //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //                 children: [
          //                   // 快捷操作按钮 - 带延迟动画
          //                   ...[
          //                     {'icon': Icons.location_on, 'label': '定位', 'color': Colors.blue},
          //                     {'icon': Icons.photo_camera, 'label': '拍照', 'color': Colors.green},
          //                     {'icon': Icons.settings, 'label': '设置', 'color': Colors.orange},
          //                   ].asMap().entries.map((entry) {
          //                     int index = entry.key;
          //                     Map<String, dynamic> item = entry.value;
          //
          //                     return AnimatedBuilder(
          //                       animation: _animationController,
          //                       builder: (context, child) {
          //                         double delay = index * 0.1;
          //                         double animationValue =
          //                             (_animationController.value - delay)
          //                                 .clamp(0.0, 1.0);
          //
          //                         return Transform.scale(
          //                           scale: animationValue,
          //                           child: Material(
          //                             color: Colors.transparent,
          //                             child: InkWell(
          //                               borderRadius: BorderRadius.circular(12),
          //                               onTap: () {
          //                                 // 按钮点击处理
          //                                 ScaffoldMessenger.of(context).showSnackBar(
          //                                   SnackBar(
          //                                     content: Text('${item['label']}功能'),
          //                                     duration: const Duration(seconds: 1),
          //                                   ),
          //                                 );
          //                               },
          //                               child: Container(
          //                                 padding: const EdgeInsets.symmetric(
          //                                   horizontal: 16,
          //                                   vertical: 12,
          //                                 ),
          //                                 child: Column(
          //                                   mainAxisSize: MainAxisSize.min,
          //                                   children: [
          //                                     Icon(
          //                                       item['icon'],
          //                                       color: item['color'],
          //                                       size: 24,
          //                                     ),
          //                                     const SizedBox(height: 4),
          //                                     Text(
          //                                       item['label'],
          //                                       style: TextStyle(
          //                                         fontSize: 12,
          //                                         color: item['color'],
          //                                         fontWeight: FontWeight.w500,
          //                                       ),
          //                                     ),
          //                                   ],
          //                                 ),
          //                               ),
          //                             ),
          //                           ),
          //                         );
          //                       },
          //                     );
          //                   }).toList(),
          //                 ],
          //               ),
          //             ),
          //           ),
          //         )
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}
