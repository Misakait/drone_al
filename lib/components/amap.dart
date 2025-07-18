import 'package:flutter/material.dart';
import 'package:amap_map/amap_map.dart';
import 'package:x_amap_base/x_amap_base.dart';
import 'package:dio/dio.dart';
import 'dart:async';

// 展示地图页面的主体组件
class ShowMapPageBody extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ShowMapPageState();
}
//添加了 AutomaticKeepAliveClientMixin，并正确实现了 wantKeepAlive，保证地图页面切换时不会被重建，状态会被保留
class _ShowMapPageState extends State<ShowMapPageBody> with AutomaticKeepAliveClientMixin {
  // 地图初始摄像头位置，定位到上海附近
  static final CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(31.0, 121.0), // 初始定位到第一个点附近
    zoom: 14.0,
  );

  // 存储轨迹点的列表（此处使用假数据，后续可替换为API获取的数据）
  List<LatLng> _trackPoints = [
    LatLng(31.0, 121.0),
    LatLng(31.1, 121.2),
    LatLng(31.2, 122.5),
  ];
  LatLng get _centerOfTrackPoints {
    if (_trackPoints.isEmpty) return _kInitialPosition.target;
    double lat = 0, lng = 0;
    for (var p in _trackPoints) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / _trackPoints.length, lng / _trackPoints.length);
  }
  // 为每个轨迹点生成一个Marker
  Set<Marker> get _markers => _trackPoints
      .asMap()
      .entries
      .map((entry) => Marker(
            position: entry.value,
            infoWindow: InfoWindow(title: '点${entry.key + 1}'),
          ))
      .toSet();
  // 地图控制器
  late AMapController _mapController;
  // 是否正在加载数据
  bool _loading = false;
  Timer? _timer; // 定时器

  @override
  void initState() {
    super.initState();
    fetchTrack();
    // 启动定时器，每5秒自动拉取一次数据
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchTrack(auto: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 从后端API获取轨迹数据，auto为true时为定时自动拉取
  Future<void> fetchTrack({bool auto = false}) async {
    try {
      final response = await Dio().get('http://192.168.3.18:3001/track_latest');
      final coordinates = response.data['coordinates'] as List;
      print(coordinates);
      List<LatLng> newTrackPoints = coordinates.map<LatLng>((e) => LatLng(e[1], e[0])).toList();
      // 比对新旧数据
      bool isDifferent = newTrackPoints.length != _trackPoints.length ||
          newTrackPoints.asMap().entries.any((e) =>
              _trackPoints.length <= e.key ||
              _trackPoints[e.key] != e.value);
      if (isDifferent) {
        setState(() {
          _trackPoints = newTrackPoints;
          _loading = false;
        });
        print('Track data updated: ${_trackPoints.length} points');
      } else if (!auto) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching track data: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  // 地图创建完成时的回调
  void onMapCreated(AMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 保证 AutomaticKeepAliveClientMixin 正常工作
    // 构建高德地图组件
    final AMapWidget map = AMapWidget(
      // 如果有轨迹点则定位到第一个点，否则用默认位置
      initialCameraPosition: _trackPoints.isNotEmpty
          // ? CameraPosition(target: _trackPoints.first, zoom: 15.0)
          ? CameraPosition(target: _centerOfTrackPoints, zoom: 15.0)
          : _kInitialPosition,
      onMapCreated: onMapCreated,
      // 绘制轨迹线，注意这里需要传入Set<Polyline>类型
      polylines: _trackPoints.isNotEmpty
          ? {
              Polyline(
                points: _trackPoints, // 轨迹点列表
                color: Colors.blue, // 轨迹线颜色
                width: 5, // 轨迹线宽度
              ),
            }
          : {},
      // 添加每个点的marker
      markers: _markers,
    );

    // 页面布局，加载时显示进度条，加载完成显示地图，并添加悬浮按钮
    return Stack(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints.expand(),
          child: _loading
              ? Center(child: CircularProgressIndicator()) // 加载中
              : Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: map, // 显示地图
                ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _loading = true;
              });
              fetchTrack();
            },
            child: Icon(Icons.refresh),
            tooltip: '刷新轨迹',
          ),
        ),
      ],
    );
  }
}
