/**
 * 飞行报告页面
 * 功能：
 * 1. 通过WebSocket连接后端服务器获取实时飞行数据
 * 2. 显示实时数据：电池容量、预计剩余时间、舱内温度、飞行高度、距离风机
 * 3. 使用fl_chart库绘制数据趋势图表
 * 4. 支持自动重连机制
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';  // WebSocket通信库
import 'package:fl_chart/fl_chart.dart';  // 图表绘制库
import 'dart:convert';  // JSON数据解析
import 'dart:async';   // 异步处理和定时器

/// 飞行报告页面 - 有状态组件
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

/// 飞行报告页面状态类
class _ProfilePageState extends State<ProfilePage> {
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

  // ========== 历史数据用于图表绘制 ==========
  List<FlSpot> batteryData = [];      // 电池容量历史数据点
  List<FlSpot> temperatureData = [];  // 温度历史数据点
  List<FlSpot> altitudeData = [];     // 高度历史数据点
  List<FlSpot> distanceData = [];     // 距离历史数据点

  // 数据点索引，用于X轴坐标
  int dataPointIndex = 0;

  // 重连定时器
  Timer? reconnectTimer;

  @override
  void initState() {
    super.initState();
    // 页面初始化时连接WebSocket
    connectWebSocket();
  }

  /**
   * 连接WebSocket服务器
   * 建立与后端的实时数据通信连接
   */
  void connectWebSocket() {
    try {
      // 创建WebSocket连接
      channel = WebSocketChannel.connect(
        Uri.parse('ws://115.190.24.116:717/flight_ws'),
      );

      // 更新连接状态为已连接
      setState(() {
        isConnected = true;
      });

      // 监听WebSocket数据流
      channel!.stream.listen(
        // 接收到数据时的处理
        (data) {
          try {
            // 解析JSON数据
            final jsonData = json.decode(data);
            // 更新飞行数据
            updateFlightData(jsonData);
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
          // 启动重连机制
          startReconnect();
        },
        // 连接关闭时的处理
        onDone: () {
          print('WebSocket连接关闭');
          setState(() {
            isConnected = false;
          });
          // 启动重连机制
          startReconnect();
        },
      );
    } catch (e) {
      print('连接WebSocket失败: $e');
      setState(() {
        isConnected = false;
      });
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
      estimatedTime = (data['estimated_remaining_usage_time'] ?? 0.0).toDouble();
      cabinTemperature = (data['cabin_temperature'] ?? 0.0).toDouble();
      aircraftAltitude = (data['aircraft_altitude'] ?? 0.0).toDouble();
      distanceToFan = (data['distance_to_fan'] ?? 0.0).toDouble();

      // 添加数据到历史记录用于图表展示
      // X轴使用数据点索引，Y轴使用实际数值
      final x = dataPointIndex.toDouble();

      // 电池容量数据 - 限制最多10个数据点
      if (batteryData.length >= 10) batteryData.removeAt(0);
      batteryData.add(FlSpot(x, batteryCapacity));

      // 温度数据 - 限制最多10个数据点
      if (temperatureData.length >= 10) temperatureData.removeAt(0);
      temperatureData.add(FlSpot(x, cabinTemperature));

      // 高度数据 - 限制最多10个数据点
      if (altitudeData.length >= 10) altitudeData.removeAt(0);
      altitudeData.add(FlSpot(x, aircraftAltitude));

      // 距离数据 - 限制最多10个数据点
      if (distanceData.length >= 10) distanceData.removeAt(0);
      distanceData.add(FlSpot(x, distanceToFan));

      // 递增数据点索引
      dataPointIndex++;
    });
  }

  @override
  void dispose() {
    // 页面销毁时关闭WebSocket连接
    channel?.sink.close();
    // 取消重连定时器
    reconnectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 应用栏配置
      appBar: AppBar(
        title: const Text('飞行报告'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Colors.white,
        actions: [
          // 连接状态指示器
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                // WiFi图标 - 根据连接状态显示不同图标和颜色
                Icon(
                  isConnected ? Icons.wifi : Icons.wifi_off,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                // 连接状态文字
                Text(
                  isConnected ? '已连接' : '未连接',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // 页面主体内容 - 可滚动视图
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ========== 实时数据展示卡片 ==========
            Card(
              elevation: 4,  // 卡片阴影深度
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    const Text(
                      '实时数据',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // 各项数据行
                    _buildDataRow('电池容量', '${batteryCapacity.toStringAsFixed(1)}%', Icons.battery_full),
                    _buildDataRow('预计剩余时间', '${estimatedTime.toStringAsFixed(1)}分钟', Icons.timer),
                    _buildDataRow('舱内温度', '${cabinTemperature.toStringAsFixed(1)}°C', Icons.thermostat),
                    _buildDataRow('飞行高度', '${aircraftAltitude.toStringAsFixed(1)}m', Icons.flight_takeoff),
                    _buildDataRow('距离风机', '${distanceToFan.toStringAsFixed(1)}m', Icons.location_on),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ========== 电池容量趋势图 ==========
            _buildChart('电池容量趋势 (%)', batteryData, Colors.green),

            const SizedBox(height: 20),

            // ========== 温度趋势图 ==========
            _buildChart('舱内温度趋势 (°C)', temperatureData, Colors.red),

            const SizedBox(height: 20),

            // ========== 高度趋势图 ==========
            _buildChart('飞行高度趋势 (m)', altitudeData, Colors.blue),

            const SizedBox(height: 20),

            // ========== 距离趋势图 ==========
            _buildChart('距离风机趋势 (m)', distanceData, Colors.orange),
          ],
        ),
      ),
    );
  }

  /**
   * 构建数据行组件
   * 参数:
   *   label - 数据标签（如"电池容量"）
   *   value - 数据值（如"75.5%"）
   *   icon - 显示的图标
   * 返回: 包含图标、标签和数值的行组件
   */
  Widget _buildDataRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // 左侧图标
          Icon(icon, color: Colors.blue[600], size: 24),
          const SizedBox(width: 12),
          // 中间标签 - 占用剩余空间
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          // 右侧数值 - 加粗显示
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /**
   * 构建图表组件
   * 参数:
   *   title - 图表标题
   *   data - 图表数据点列表
   *   color - 图表主色调
   * 返回: 包含标题和折线图的卡片组件
   */
  Widget _buildChart(String title, List<FlSpot> data, Color color) {
    return Card(
      elevation: 4,  // 卡片阴影
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图表标题
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 图表容器
            SizedBox(
              height: 200,  // 固定图表高度
              child: data.isEmpty
                  ? // 无数据时显示等待提示
                    const Center(
                      child: Text(
                        '等待数据...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : // 有数据时显示折线图
                    LineChart(
                      LineChartData(
                        // ========== 网格配置 ==========
                        gridData: FlGridData(
                          show: true,              // 显示网格
                          drawVerticalLine: true,  // 显示垂直网格线
                          horizontalInterval: 1,   // 水平网格线间隔
                          verticalInterval: 1,     // 垂直网格线间隔
                          // 水平网格线样式
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                          // 垂直网格线样式
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                        ),
                        // ========== 坐标轴标题配置 ==========
                        titlesData: FlTitlesData(
                          show: true,
                          // 隐藏右侧和顶部标题
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          // 底部X轴标题配置
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,  // 预留空间
                              interval: 1,       // 标题间隔
                              getTitlesWidget: (value, meta) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    value.toInt().toString(),  // 显示整数值
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // 左侧Y轴标题配置
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(0),  // 显示整数值
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                );
                              },
                              reservedSize: 42,  // Y轴标题预留宽度
                            ),
                          ),
                        ),
                        // ========== 边框配置 ==========
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: const Color(0xff37434d)),
                        ),
                        // ========== 坐标轴范围配置 ==========
                        minX: data.isEmpty ? 0 : data.first.x,  // X轴最小值
                        maxX: data.isEmpty ? 10 : data.last.x,   // X轴最大值
                        // Y轴范围：最小值-1 到 最大值+1，增加上下边距
                        minY: data.isEmpty ? 0 : data.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1,
                        maxY: data.isEmpty ? 10 : data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1,
                        // ========== 折线数据配置 ==========
                        lineBarsData: [
                          LineChartBarData(
                            spots: data,          // 数据点
                            isCurved: true,       // 平滑曲线
                            // 线条渐变色
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.3),  // 半透明起始色
                                color,                          // 主色调
                              ],
                            ),
                            barWidth: 3,              // 线条宽度
                            isStrokeCapRound: true,   // 圆形线条端点
                            dotData: FlDotData(       // 隐藏数据点
                              show: false,
                            ),
                            // 线条下方填充区域
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.3),  // 顶部半透明
                                  color.withValues(alpha: 0.1),  // 底部更透明
                                ],
                                begin: Alignment.topCenter,     // 渐变起点
                                end: Alignment.bottomCenter,    // 渐变终点
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
