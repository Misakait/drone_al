import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amap_map/amap_map.dart';
import 'package:http/http.dart' as http;
import 'package:x_amap_base/x_amap_base.dart';

// 展示地图页面的主体组件
class ShowMapPageBody extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ShowMapPageState();
}

class _ShowMapPageState extends State<ShowMapPageBody> {
  // 地图初始摄像头位置
  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(31.0, 121.0),
    zoom: 14.0,
  );

  // 存储轨迹点的列表
  List<LatLng> _trackPoints = [];

  // 地图控制器
  late AMapController _mapController;
  bool _mapControllerReady = false;

  // SSE连接相关
  StreamSubscription? _sseSubscription;
  http.Client? _httpClient;

  @override
  void initState() {
    super.initState();
    _connectToSSE();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _httpClient?.close();
    super.dispose();
  }

  // 连接到SSE端点
  void _connectToSSE() async {
    try {
      _httpClient = http.Client();
      final request = http.Request('GET', Uri.parse('http://115.190.24.116:3001/sse/location'));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await _httpClient!.send(request);

      _sseSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleSSEMessage, onError: (error) {
        print('SSE Error: $error');
        // 重连逻辑
        Future.delayed(const Duration(seconds: 5), () {
          _connectToSSE();
        });
      });
    } catch (e) {
      print('Failed to connect to SSE: $e');
      // 重连逻辑
      Future.delayed(const Duration(seconds: 5), () {
        _connectToSSE();
      });
    }
  }

  // 处理SSE消息
  void _handleSSEMessage(String message) {
    if (message.startsWith('data: ')) {
      final data = message.substring(6);
      try {
        final locationData = jsonDecode(data);
        final longitude = locationData['longitude'];
        final latitude = locationData['latitude'];

        if (longitude != null && latitude != null) {
          final newPoint = LatLng(latitude.toDouble(), longitude.toDouble());
          setState(() {
            _trackPoints.add(newPoint);
          });

          // 如果地图已准备好，移动视角到最新点
          if (_mapControllerReady && _trackPoints.isNotEmpty) {
            _moveToLatestPoint();
          }
        }
      } catch (e) {
        print('Error parsing SSE data: $e');
      }
    }
  }

  // 移动地图视角到最新的点
  Future<void> _moveToLatestPoint() async {
    if (_trackPoints.isNotEmpty && _mapControllerReady) {
      await _mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _trackPoints.last,
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  // 地图创建完成时的回调
  void onMapCreated(AMapController controller) {
    setState(() {
      _mapController = controller;
      _mapControllerReady = true;
    });
  }

  // 为每个轨迹点生成Marker
  Set<Marker> get _markers => _trackPoints
      .asMap()
      .entries
      .map((entry) => Marker(
            position: entry.value,
            infoWindow: InfoWindow(title: '点${entry.key + 1}'),
          ))
      .toSet();

  @override
  Widget build(BuildContext context) {
    final AMapWidget map = AMapWidget(
      initialCameraPosition: _kInitialPosition,
      onMapCreated: onMapCreated,
      // 绘制轨迹线
      polylines: _trackPoints.length > 1
          ? {
              Polyline(
                points: _trackPoints,
                color: Colors.blue,
                width: 5,
              ),
            }
          : {},
      // 添加每个点的marker
      markers: _markers,
    );

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: map,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_trackPoints.isNotEmpty) {
            _moveToLatestPoint();
          }
        },
        child: const Icon(Icons.my_location),
        tooltip: '定位到最新位置',
      ),
    );
  }
}
