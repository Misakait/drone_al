/**
 * 飞行报告页面
 * 功能：
 * 1. 通过WebSocket连接后端服务器获取实时飞行数据
 * 2. 显示实时数据：电池容量、预计剩余时间、舱内温度、飞行高度、距离风机
 * 3. 使用fl_chart库绘制数据趋势图表
 * 4. 支持自动重连机制
 * 5. 丰富的动画效果增强用户体验
 */

import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:async';

/// 飞行报告页面 - 有状态组件
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// 飞行报告页面状态类
class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin { // 添加动画混入类，支持多个动画控制器

  // WebSocket连接通道
  WebSocketChannel? channel;
  // WebSocket连接状态标志
  bool isConnected = false;

  // ========== 实时数据变量 ==========
  double batteryCapacity = 0.0;    // 电池容量百分比
  double estimatedTime = 0.0;      // 预计剩余使用时间（分钟）
  double cabinTemperature = 0.0;   // 舱内温度（摄氏度）
  double aircraftAltitude = 0.0;   // 飞行器高度（米）
  double distanceToFan = 0.0;      // 距离风机的距离（米）
  double airPressure = 0.0;        // 气压（帕斯卡）

  // ========== 历史数据用于图表绘制 ==========
  List<FlSpot> batteryData = [];      // 电池容量历史数据点
  List<FlSpot> temperatureData = [];  // 温度历史数据点
  List<FlSpot> altitudeData = [];     // 高度历史数据点
  List<FlSpot> distanceData = [];     // 距离历史数据点
  List<FlSpot> pressureData = [];     // 气压历史数据点

  // 数据点索引，用于X轴坐标
  int dataPointIndex = 0;
  // 重连定时器
  Timer? reconnectTimer;

  // ========== 动画控制器声明 ==========
  late AnimationController _pageAnimationController; // 页面加载动画控制器
  late AnimationController _dataAnimationController; // 数据更新动画控制器
  late AnimationController _chartAnimationController; // 图表动画控制器
  late AnimationController _connectionAnimationController; // 连接状态动画控制器
  late AnimationController _pulseAnimationController; // 脉冲动画控制器

  // ========== 动画声明 ==========
  late Animation<double> _fadeAnimation; // 淡入动画
  late Animation<Offset> _slideAnimation; // 滑动动画
  late Animation<double> _scaleAnimation; // 缩放动画
  late Animation<double> _rotationAnimation; // 旋转动画
  late Animation<double> _pulseAnimation; // 脉冲动画

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _pageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 页面动画持续时间
      vsync: this,
    );

    _dataAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600), // 数据更新动画持续时间
      vsync: this,
    );

    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800), // 图表动画持续时间
      vsync: this,
    );

    _connectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000), // 连接状态动画持续时间
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000), // 脉冲动画持续时间
      vsync: this,
    );

    // 初始化动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), // 从下方滑入
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dataAnimationController,
      curve: Curves.bounceOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _connectionAnimationController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    // 启动页面加载动画
    _pageAnimationController.forward();

    // 启动脉冲动画（循环）
    _pulseAnimationController.repeat(reverse: true);

    // 页面初始化时连接WebSocket
    connectWebSocket();
  }

  @override
  void dispose() {
    // 释放动画控制器资源
    _pageAnimationController.dispose();
    _dataAnimationController.dispose();
    _chartAnimationController.dispose();
    _connectionAnimationController.dispose();
    _pulseAnimationController.dispose();

    // 关闭WebSocket连接
    channel?.sink.close();
    reconnectTimer?.cancel();
    super.dispose();
  }

  /**
   * 连接WebSocket服务器
   * 建立与后端的实时数据通信连接
   */
  void connectWebSocket() {
    try {
      // 启动连接动画
      _connectionAnimationController.repeat();

      // 创建WebSocket连接
      channel = WebSocketChannel.connect(
        Uri.parse('ws://115.190.24.116:8080/flight_ws'),
      );

      // 更新连接状态为已连接
      setState(() {
        isConnected = true;
      });

      // 停止连接动画
      _connectionAnimationController.stop();

      // 监听WebSocket数据流
      channel!.stream.listen(
        // 接收到数据时的处理
        (data) {
          try {
            // 解析JSON数据
            final jsonData = json.decode(data);
            log('接收到数据: $jsonData');
            // 提取嵌套的飞行数据
            final flightData = jsonData['data'];
            if (flightData != null) {
              // 更新飞行数据
              updateFlightData(flightData);
            }
          } catch (e) {
            print('解析数据错误: $e');
          }
        },
        // 连接错误时的处理
        onError: (error) {
          print('WebSocket错误: $error');
          setState(() {
            isConnected = false;
          });
          _connectionAnimationController.stop();
          // 启动重连机制
          startReconnect();
        },
        // 连接关闭时的处理
        onDone: () {
          print('WebSocket连接关闭');
          setState(() {
            isConnected = false;
          });
          _connectionAnimationController.stop();
          // 启动重连机制
          startReconnect();
        },
      );
    } catch (e) {
      print('连接WebSocket失败: $e');
      setState(() {
        isConnected = false;
      });
      _connectionAnimationController.stop();
      // 启动重连机制
      startReconnect();
    }
  }

  /**
   * 启动重连机制
   * 在连接断开后等待5秒后尝试重新连接
   */
  void startReconnect() {
    // 取消之前的重连定时器
    reconnectTimer?.cancel();
    // 设置5秒后重连
    reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!isConnected) {
        connectWebSocket();
      }
    });
  }

  /**
   * 更新飞行数据
   * 参数: data - 从WebSocket接收的JSON数据
   * 功能: 解析数据并更新UI显示，同时添加到历史数据用于图表展示
   */
  void updateFlightData(Map<String, dynamic> data) {
    setState(() {
      // 更新实时数据，使用??操作符提供默认值防止null
      batteryCapacity = (data['battery_capacity'] ?? 0.0).toDouble();
      estimatedTime = (data['estimated_time'] ?? 0.0).toDouble();
      cabinTemperature = (data['cabin_temperature'] ?? 0.0).toDouble();
      aircraftAltitude = (data['aircraft_altitude'] ?? 0.0).toDouble();
      distanceToFan = (data['distance_to_fan'] ?? 0.0).toDouble();
      airPressure = (data['air_pressure'] ?? 0.0).toDouble();

      // 添加新的数据点到历史数据列表
      batteryData.add(FlSpot(dataPointIndex.toDouble(), batteryCapacity));
      temperatureData.add(FlSpot(dataPointIndex.toDouble(), cabinTemperature));
      altitudeData.add(FlSpot(dataPointIndex.toDouble(), aircraftAltitude));
      distanceData.add(FlSpot(dataPointIndex.toDouble(), distanceToFan));
      pressureData.add(FlSpot(dataPointIndex.toDouble(), airPressure));

      // 限制历史数据点数量，保持图表性能
      const maxDataPoints = 50;
      if (batteryData.length > maxDataPoints) {
        batteryData.removeAt(0);
        temperatureData.removeAt(0);
        altitudeData.removeAt(0);
        distanceData.removeAt(0);
        pressureData.removeAt(0);
      }

      // 递增数据点索引
      dataPointIndex++;
    });

    // 触发数据更新动画
    _dataAnimationController.reset();
    _dataAnimationController.forward();

    // 触发图表更新动画
    _chartAnimationController.reset();
    _chartAnimationController.forward();
  }

  /**
   * 构建带动画的数据卡片
   * 参数: title - 卡片标题, value - 数值, unit - 单位, icon - 图标, color - 颜色, index - 索引用于延迟动画
   */
  Widget _buildAnimatedDataCard(
    String title,
    double value,
    String unit,
    IconData icon,
    Color color,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _pageAnimationController,
      builder: (context, child) {
        // 计算延迟动画，让卡片依次出现
        double delay = index * 0.1;
        double animationValue = (_pageAnimationController.value - delay).clamp(0.0, 1.0);

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0), // 从右侧滑入
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _pageAnimationController,
            curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _pageAnimationController,
              curve: Interval(delay, 1.0, curve: Curves.easeIn),
            )),
            child: AnimatedBuilder(
              animation: _dataAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Card(
                    elevation: 8,
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.1),
                            color.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          // 图标带脉冲动画
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Icon(
                                  icon,
                                  size: 32,
                                  color: color,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          // 数值带计数动画
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: value),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedValue, child) {
                              return Text(
                                '${animatedValue.toStringAsFixed(1)}$unit',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                );
              },
            ),
          ),
        );
      }
    );
  }

  /**
   * 构建带动画的图表卡片
   * 参数: title - 图表标题, data - 数据点列表, color - 颜色
   */
  Widget _buildAnimatedChart(String title, List<FlSpot> data, Color color) {
    if (data.isEmpty) {
      return Container();
    }

    return AnimatedBuilder(
      animation: _chartAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Card(
              elevation: 6,
              margin: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _chartAnimationController,
                        builder: (context, child) {
                          // 根据动画进度显示数据点
                          int visibleDataPoints = (data.length * _chartAnimationController.value).round();
                          List<FlSpot> animatedData = data.take(visibleDataPoints).toList();

                          return LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey[300]!,
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toStringAsFixed(0),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: animatedData,
                                  isCurved: true,
                                  color: color,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: color.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _pageAnimationController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
          )),
          child: const Text("飞行监控"),
        ),
        elevation: 0,
        centerTitle: true,
        // 连接状态指示器
        actions: [
          AnimatedBuilder(
            animation: _connectionAnimationController,
            builder: (context, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Icon(
                        isConnected ? Icons.wifi : Icons.wifi_off,
                        color: isConnected ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? '已连接' : '断开',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.inversePrimary.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // 实时数据网格 - 3x2布局
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                children: [
                  _buildAnimatedDataCard(
                    '电池容量',
                    batteryCapacity,
                    '%',
                    Icons.battery_charging_full,
                    Colors.green,
                    0,
                  ),
                  _buildAnimatedDataCard(
                    '预计时间',
                    estimatedTime,
                    'min',
                    Icons.access_time,
                    Colors.blue,
                    1,
                  ),
                  _buildAnimatedDataCard(
                    '舱内温度',
                    cabinTemperature,
                    '°C',
                    Icons.thermostat,
                    Colors.orange,
                    2,
                  ),
                  _buildAnimatedDataCard(
                    '飞行高度',
                    aircraftAltitude,
                    'm',
                    Icons.flight_takeoff,
                    Colors.purple,
                    3,
                  ),
                  _buildAnimatedDataCard(
                    '距离风机',
                    distanceToFan,
                    'm',
                    Icons.speed,
                    Colors.red,
                    4,
                  ),
                  _buildAnimatedDataCard(
                    '气压',
                    airPressure / 1000, // 转换为千帕显示
                    'kPa',
                    Icons.compress,
                    Colors.teal,
                    5,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 图表区域
              if (batteryData.isNotEmpty) ...[
                _buildAnimatedChart('电池容量趋势', batteryData, Colors.green),
                _buildAnimatedChart('温度变化', temperatureData, Colors.orange),
                _buildAnimatedChart('高度变化', altitudeData, Colors.purple),
                _buildAnimatedChart('距离变化', distanceData, Colors.red),
                _buildAnimatedChart('气压变化', pressureData, Colors.teal),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
