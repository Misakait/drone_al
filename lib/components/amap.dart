import 'dart:io';

import 'package:flutter/material.dart';
import 'package:amap_map/amap_map.dart';
import 'package:flutter_z_location/flutter_z_location.dart';
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
    // LatLng(31.0, 121.0),
    // LatLng(31.1, 121.2),
    // LatLng(31.2, 122.5),
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
  // 地图控制器是否已初始化
  bool _mapControllerReady = false;
  // 是否正在加载数据
  bool _loading = false;
  Timer? _timer; // 定时器
  LatLng? _locationPoint ; // 当前定位点

  @override
  void initState() {
    super.initState();
    // fetchTrack();
    _initLocationAndTrack();
    // 启动定时器，每5秒自动拉取一次数据
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      fetchTrack(auto: true);
    });
  }

  Future<void> _initLocationAndTrack() async {
    final coordinate = await FlutterZLocation.getCoordinate();

    if (coordinate != null) {
      setState(() {
        _locationPoint = LatLng(coordinate.latitude, coordinate.longitude);
      });
      // 如果地图控制器已准备好，立即移动到用户位置
      if (_mapControllerReady) {
        _moveToLocation();
      }
    }
    await fetchTrack();
  }

  // 移动地图视角到用户位置
  Future<void> _moveToLocation() async {
    if (_locationPoint != null && _mapControllerReady) {
      await _mapController.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _locationPoint!,
            zoom: 16.0, // 使用稍微高一点的缩放级别
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 从后端API获取轨迹数据，auto为true时为定时自动拉取
  Future<void> fetchTrack({bool auto = false}) async {
    // final coordinate = await FlutterZLocation.getCoordinate();
    // 弹窗显示经纬度
    // if (coordinate != null) {
    //   showDialog(
    //     context: context,
    //     builder: (context) => AlertDialog(
    //       title: Text('当前位置'),
    //       content: Text('经度: ${coordinate.longitude}\n纬度: ${coordinate.latitude}'),
    //       actions: [
    //         TextButton(
    //           onPressed: () => Navigator.of(context).pop(),
    //           child: Text('关闭'),
    //         ),
    //       ],
    //     ),
    //   );
    // }

    try {
      final response = await Dio().get('http://115.190.24.116:717/track_latest');
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
      _mapControllerReady = true;
    });
    // 地图创建后如果已有位置信息，立即移动到用户位置并更新markers
    if (_locationPoint != null) {
      _moveToLocation();
    }
  }

  Set<Marker> get _allMarkers {
    final trackMarkers = _markers;
    final locationMarker = _locationPoint == null
        ? <Marker>{}
        : {
            Marker(
              position: _locationPoint!,
              infoWindow: InfoWindow(title: '我的位置'),

            ),
          };
    return {...trackMarkers, ...locationMarker};
  }

  LatLng get _mapCenter {

    if (_locationPoint != null) return _locationPoint!;
    if (_trackPoints.isNotEmpty) return _centerOfTrackPoints;
    return _kInitialPosition.target;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 保证 AutomaticKeepAliveClientMixin 正常工作
    // 构建高德地图组件
    final AMapWidget map = AMapWidget(
      // initialCameraPosition: _trackPoints.isNotEmpty
      // // ? CameraPosition(target: _trackPoints.first, zoom: 15.0)
      //     ? CameraPosition(target: _centerOfTrackPoints, zoom: 15.0)
      //     : _kInitialPosition,
      // initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 15.0),
      initialCameraPosition: CameraPosition(target: _locationPoint ?? _mapCenter, zoom: 15.0),
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
      markers: _allMarkers,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: "location_btn",
                onPressed: () {
                  _moveToLocation();
                },
                child: Icon(Icons.my_location),
                tooltip: '定位到我的位置',
              ),
              SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "refresh_btn",
                onPressed: () {
                  setState(() {
                    _loading = true;
                  });
                  fetchTrack();
                },
                child: Icon(Icons.refresh),
                tooltip: '刷新轨迹',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
