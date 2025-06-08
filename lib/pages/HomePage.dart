import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../components/amap.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // const Icon(Icons.home, size: 80, color: Colors.blue),
          // const SizedBox(height: 20),
          Expanded(child: ShowMapPageBody()),
          // Text(
          //   '首页',
          //   style: Theme.of(context).textTheme.headlineMedium,
          // ),
          // const SizedBox(height: 20),
          // const Text('这里是首页内容区域'),
        ],
      ),
    );
  }
}