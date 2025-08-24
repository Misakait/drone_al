import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with TickerProviderStateMixin { // 添加动画混入类，支持多个动画控制器
  // 保存报告列表数据
  List<Map<String, dynamic>> reports = [];
  // 加载状态标记
  bool _loading = false;
  // Dio实例用于网络请求
  final Dio _dio = Dio();

  // 动画控制器声明
  late AnimationController _listAnimationController; // 列表项动画控制器
  late AnimationController _pieChartAnimationController; // 饼图动画控制器
  late AnimationController _loadingAnimationController; // 加载动画控制器
  late AnimationController _fabAnimationController; // 浮动按钮动画控制器

  // 动画声明
  late Animation<double> _fadeAnimation; // 淡入动画
  late Animation<Offset> _slideAnimation; // 滑动动画
  late Animation<double> _scaleAnimation; // 缩放动画
  late Animation<double> _rotationAnimation; // 旋转动画

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800), // 列表动画持续时间
      vsync: this,
    );

    _pieChartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // 饼图动画持续时间
      vsync: this,
    );

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500), // 加载动画持续时间
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300), // 浮动按钮动画持续时间
      vsync: this,
    );

    // 初始化动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeInOut, // 使用缓动曲线
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), // 从下方滑入
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.elasticOut, // 使用弹性曲线
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.bounceOut, // 使用反弹曲线
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.linear,
    ));

    // 启动浮动按钮动画
    _fabAnimationController.forward();

    // 页面初始化时加载报告数据
    _loadReports();
  }

  @override
  void dispose() {
    // 释放动画控制器资源
    _listAnimationController.dispose();
    _pieChartAnimationController.dispose();
    _loadingAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  // 从后端API获取报告数据
  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
    });

    // 启动加载动画
    _loadingAnimationController.repeat();

    try {
      // 调用后端接口获取原始报告数据
      final response = await _dio.get('http://115.190.24.116:717/report_raw');
      // final response = await _dio.get('http://192.168.3.18:717/report_raw');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          // 对每条报告数据进行处理
          reports = data.map((item) {
            // 截取detail字段前30个字符作为summary
            String summary = item['detail'] ?? '';
            if (summary.length > 30) {
              summary = summary.substring(0, 30) + '...';
            }

            // 处理图片路径，补全为完整URL
            List<String> imagePaths = [];
            if (item['photoPath'] != null && item['photoPath'].isNotEmpty) {
              String photoPath = item['photoPath'];
              // 支持多张图片，按逗号分割
              List<String> paths = photoPath
                  .split(',')
                  .map((path) => path.trim())
                  .toList();
              imagePaths = paths.where((path) => path.isNotEmpty).map((path) {
                // 拼接图片完整访问地址
                return 'http://115.190.24.116:2007$path';
              }).toList();
            }

            // 返回处理后的报告数据
            return {
              '_id': item['_id'],
              'title': item['title'] ?? '',
              'summary': summary,
              'detail': item['detail'] ?? '',
              'createdAt': item['createdAt'],
              'imagePaths': imagePaths,
              'damage': (item['damage'] ?? 0.0).toDouble(),
              'rust': (item['rust'] ?? 0.0).toDouble(),
              'covering': (item['covering'] ?? 0.0).toDouble(),
              'ai_report': item['ai_report'] ?? '',
            };
          }).toList();
        });

        // 数据加载完成后启动列表动画
        _listAnimationController.forward();
      }
    } catch (e) {
      // 网络或解析异常处理
      print('Error loading reports: $e');
      // 可以在这里显示错误消息给用户
    } finally {
      setState(() {
        _loading = false;
      });

      // 停止加载动画
      _loadingAnimationController.stop();
    }
  }

  // 下拉刷新报告列表
  Future<void> _refreshReports() async {
    // 重置动画状态
    _listAnimationController.reset();
    await _loadReports();
  }

  // 清空所有报告数据
  Future<void> _deleteAllReports() async {
    try {
      final response = await _dio.delete(
        'http://115.190.24.116:717/report_raw/delete_all',
      );
      if (response.statusCode == 200) {
        // 删除成功后刷新列表
        await _loadReports();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('所有报告已清空')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('清空失败：${response.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清空失败：$e')));
    }
  }

  // 创建饼图组件
  Widget _buildPieChart(String title, double value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16), // 增加标题和图表之间的间距
        SizedBox(
          height: 120,
          width: 120,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: [
                PieChartSectionData(
                  value: value * 100,
                  color: color,
                  title: '${(value * 100).toStringAsFixed(1)}%',
                  radius: 45,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: (1 - value) * 100,
                  color: Colors.grey[300]!,
                  title: '',
                  radius: 45,
                ),
              ],
            ),
          ),
        ),
        // const SizedBox(height: 8), // 增加图表和百分比文字之间的间距
        // Text(
        //   '${(value * 100).toStringAsFixed(1)}%',
        //   style: TextStyle(
        //     fontSize: 14,
        //     color: color,
        //     fontWeight: FontWeight.w600,
        //   ),
        // ),
      ],
    );
  }

  // 展示带动画的报告详情弹窗
  void _showDetailDialog(Map<String, dynamic> report) {
    // 重置饼图动画
    _pieChartAnimationController.reset();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400), // 自定义弹窗动画时长
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container(); // 占位容器
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // 自定义弹窗转场动画
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1), // 从底部滑入
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut, // 弹性曲线
          )),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.8,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack, // 回弹效果
            )),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // 圆角弹窗
              ),
              title: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: Text(report['title'] ?? ''),
                  );
                },
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 报告详情带淡入动画
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: const Interval(0.2, 1.0), // 延迟动画
                          )),
                          child: Text(report['detail'] ?? ''),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 数据分析标题动画
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(-1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: const Interval(0.3, 1.0),
                          )),
                          child: const Text(
                            '数据分析:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // 三个饼图垂直排列，带动画效果
                    Column(
                      children: [
                        Center(
                          child: _buildPieChart(
                            '损坏程度',
                            report['damage'] ?? 0.0,
                            Colors.red,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: _buildPieChart(
                            '锈蚀程度',
                            report['rust'] ?? 0.0,
                            Colors.orange,

                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: _buildPieChart(
                            '覆盖程度',
                            report['covering'] ?? 0.0,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    // 图片区域带动画
                    if (report['imagePaths'] != null &&
                        report['imagePaths'].isNotEmpty) ...[
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: const Interval(0.5, 1.0),
                            )),
                            child: const Text(
                              '相关图片:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ...report['imagePaths']
                          .asMap()
                          .entries
                          .map<Widget>(
                            (entry) {
                              int imageIndex = entry.key;
                              String imagePath = entry.value;

                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: Offset(0, 0.5 * (imageIndex + 1)),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Interval(
                                        0.6 + imageIndex * 0.1,
                                        1.0,
                                      ),
                                    )),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imagePath,
                                          fit: BoxFit.cover,
                                          // 图片加载失败时显示错误图标
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              height: 100,
                                              width: double.infinity,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(Icons.error, color: Colors.grey),
                                              ),
                                            );
                                          },
                                          // 图片加载中显示进度条
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              height: 100,
                                              width: double.infinity,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                          .toList(),
                    ],
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: const Interval(0.8, 1.0),
                          )),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("AI分析报告:"),
                              Text(report['ai_report'] ?? ''),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.9, 1.0),
                      )),
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('关闭'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    // 延迟启动饼图动画，等待弹窗完全显示
    Future.delayed(const Duration(milliseconds: 200), () {
      _pieChartAnimationController.forward();
    });
  }

  // 创建带动画的列表项
  Widget _buildAnimatedListItem(Map<String, dynamic> report, int index) {
    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        // 为每个列表项添加延迟动画
        double delay = index * 0.1;
        double animationValue = (_listAnimationController.value - delay).clamp(0.0, 1.0);

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0), // 从右侧滑入
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _listAnimationController,
            curve: Interval(delay, 1.0, curve: Curves.elasticOut),
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _listAnimationController,
              curve: Interval(delay, 1.0, curve: Curves.easeIn),
            )),
            child: Transform.scale(
              scale: 0.8 + (0.2 * animationValue), // 缩放动画
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4, // 增加阴影
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 圆角卡片
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showDetailDialog(report), // 点击展示详情弹窗
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report['title'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(report['summary'] ?? ''),
                          if (report['imagePaths'] != null &&
                              report['imagePaths'].isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '包含图片',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
        title: const Text("报告中心"),
        elevation: 0, // 移除阴影
      ),
      body: Stack(
        children: [
          // 添加渐变背景
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),

          // 主要内容区域
          _loading
              ? Center(
                  child: AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159, // 旋转动画
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshReports,
                  color: Colors.blue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _buildAnimatedListItem(report, index);
                    },
                  ),
                ),
          Positioned(
            bottom: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _refreshReports,
                  child: const Icon(Icons.refresh),
                  tooltip: '刷新报告',
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  onPressed: _deleteAllReports,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.delete),
                  tooltip: '清空所有报告',
                ),
              ],
            ),
          ),
        ],

      ),

      // 带动画的浮动操作按钮
      // floatingActionButton: ScaleTransition(
      //   scale: _fabAnimationController,
      //   child: FloatingActionButton(
      //     onPressed: _refreshReports,
      //     child: const Icon(Icons.refresh, color: Colors.white),
      //   ),
      // ),
      
    );
    
  }
}
