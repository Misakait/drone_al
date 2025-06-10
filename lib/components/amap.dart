import 'package:flutter/material.dart';
import 'package:amap_map/amap_map.dart';
import 'package:x_amap_base/x_amap_base.dart';
import 'package:dio/dio.dart';

// 展示地图页面的主体组件
class ShowMapPageBody extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ShowMapPageState();
}

class _ShowMapPageState extends State<ShowMapPageBody> {
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
  // 地图控制器
  late AMapController _mapController;
  // 是否正在加载数据
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // 暂时不拉取API数据，使用假数据
    // fetchTrack();
  }

  // 从后端API获取轨迹数据
  Future<void> fetchTrack() async {
    try {
      // TODO: 替换为你的API地址
      final response = await Dio().get('http://你的API地址/track/latest');
      // 解析后端返回的坐标数组
      final coordinates = response.data['track']['coordinates'] as List;
      setState(() {
        // 将坐标数组转换为LatLng对象列表（注意经纬度顺序）
        _trackPoints = coordinates.map<LatLng>((e) => LatLng(e[1], e[0])).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      // 可根据需要添加错误提示
    }
  }

  // 地图创建完成时的回调
  void onMapCreated(AMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 构建高德地图组件
    final AMapWidget map = AMapWidget(
      // 如果有轨迹点则定位到第一个点，否则用默认位置
      initialCameraPosition: _trackPoints.isNotEmpty
          ? CameraPosition(target: _trackPoints.first, zoom: 14.0)
          : _kInitialPosition,
      onMapCreated: onMapCreated,
      // 绘制轨迹线，注意这里需要传入Set<Polyline>类型
      polylines: _trackPoints.isNotEmpty
          ? {
              Polyline(
                // polylineId: PolylineId('track'), // 轨迹线ID
                points: _trackPoints, // 轨迹点列表
                color: Colors.blue, // 轨迹线颜色
                width: 5, // 轨迹线宽度
              ),
            }
          : {},
    );

    // 页面布局，加载时显示进度条，加载完成显示地图
    return ConstrainedBox(
      constraints: BoxConstraints.expand(),
      child: _loading
          ? Center(child: CircularProgressIndicator()) // 加载中
          : Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: map, // 显示地图
            ),
    );
  }
}
