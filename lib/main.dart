import 'package:amap_map/amap_map.dart';
import 'package:drone_al/pages/HomePage.dart';
import 'package:drone_al/pages/ReportPage.dart';
import 'package:drone_al/pages/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'config/AmapConfig.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // ← 必须加
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AMapInitializer.init(context, apiKey: AmapConfig.amapApiKeys);
    AMapInitializer.updatePrivacyAgree(AmapConfig.amapPrivacyStatement);
    return MaterialApp(
      title: 'Drone Management Center',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // 添加全局页面转场动画主题
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const BottomNavPage(),
    );
  }
}

class BottomNavPage extends StatefulWidget {
  const BottomNavPage({super.key});
  @override
  State<BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<BottomNavPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // 动画控制器
  late AnimationController _pageTransitionController;
  late AnimationController _bottomNavAnimationController;
  late AnimationController _fabAnimationController;

  // 动画声明
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // 页面列表
  static final List<Widget> _pages = [
    const HomePage(), // 首页
    const ReportPage(), // 报告页
    const ProfilePage(), // 飞行状态页
  ];

  // 与页面列表对应的标题列表
  static const List<String> _pageTitles = [
    '无人机监控中心', // 对应 HomePage 的标题
    '报告中心', // 对应 ReportPage 的标题
    '飞行监控', // 对应 ProfilePage 的标题
  ];

  // 底部导航栏项目
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '首页',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.assessment_outlined),
      activeIcon: Icon(Icons.assessment),
      label: '报告',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.flight_outlined),
      activeIcon: Icon(Icons.flight),
      label: '状态',
    ),
  ];

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300), // 页面切换动画持续时间
      vsync: this,
    );

    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200), // 底部导航动画持续时间
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150), // 浮动按钮动画持续时间
      vsync: this,
    );

    // 初始化动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0), // 从右侧滑入
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeOutBack,
    ));

    // 启动初始动画
    _pageTransitionController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    // 释放动画控制器资源
    _pageTransitionController.dispose();
    _bottomNavAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  // 页面切换处理函数，带动画效果
  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      // 先执行退出动画
      _pageTransitionController.reverse().then((_) {
        // 切换页面
        setState(() {
          _selectedIndex = index;
        });
        // 执行进入动画
        _pageTransitionController.forward();
      });

      // 底部导航栏按钮点击动画
      _bottomNavAnimationController.forward().then((_) {
        _bottomNavAnimationController.reverse();
      });
    }
  }

  // 创建带动画的页面容器
  Widget _buildAnimatedPage(Widget page) {
    return AnimatedBuilder(
      animation: _pageTransitionController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: page,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 添加全局背景渐变
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.02),
              Theme.of(context).colorScheme.secondary.withOpacity(0.01),
              Colors.white,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages.map((page) => _buildAnimatedPage(page)).toList(),
        ),
      ),

      // 底部导航栏带动画效果
      bottomNavigationBar: AnimatedBuilder(
        animation: _bottomNavAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_bottomNavAnimationController.value * 0.05), // 轻微缩放效果
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Colors.grey,
                onTap: _onItemTapped,
                items: _navItems,
                backgroundColor: Colors.white,
                elevation: 0, // 移除默认阴影，使用自定义阴影
                // 添加导航栏项目的动画效果
                selectedFontSize: 12,
                unselectedFontSize: 10,
                iconSize: 24,
                selectedIconTheme: IconThemeData(
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        },
      ),


    );
  }
}
