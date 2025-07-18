import 'package:amap_map/amap_map.dart';
import 'package:drone_al/pages/HomePage.dart';
import 'package:drone_al/pages/ReportPage.dart';
import 'package:drone_al/pages/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'config/AmapConfig.dart';


void main() {
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

class _BottomNavPageState extends State<BottomNavPage> {
  int _selectedIndex = 0;

  // 页面列表
  static final List<Widget> _pages = [
    // 首页
    const HomePage(),
    // 报告页
    const ReportPage(),
    // // 消息页
    // const MessagePage(),
    // 我的页面
    const ProfilePage(),
  ];
// 与页面列表对应的标题列表
  static const List<String> _pageTitles = [
    '首页',       // 对应 HomePage 的标题
    '报告',
    '我的',       // 对应 ProfilePage 的标题
  ];
  // 底部导航栏项目
  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: '首页',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.explore_outlined),
      activeIcon: Icon(Icons.explore),
      label: '报告',
    ),
    // BottomNavigationBarItem(
    //   icon: Icon(Icons.message_outlined),
    //   activeIcon: Icon(Icons.message),
    //   label: '消息',
    // ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: '我的',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_pageTitles[_selectedIndex]),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: _navItems,
      ),
    );
  }
}


// // // 消息页
// // class MessagePage extends StatelessWidget {
// //   const MessagePage({super.key});
// //   @override
// //   Widget build(BuildContext context) {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: <Widget>[
// //           const Icon(Icons.message, size: 80, color: Colors.green),
// //           const SizedBox(height: 20),
// //           Text(
// //             '消息',
// //             style: Theme.of(context).textTheme.headlineMedium,
// //           ),
// //           const SizedBox(height: 20),
// //           const Text('您的消息中心'),
// //         ],
// //       ),
// //     );
// //   }
// // }
//
// // 我的页面
