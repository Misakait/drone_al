import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // 保存报告列表数据
  List<Map<String, dynamic>> reports = [];
  // 加载状态标记
  bool _loading = false;
  // Dio实例用于网络请求
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    // 页面初始化时加载报告数据
    _loadReports();
  }

  // 从后端API获取报告数据
  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
    });

    try {
      // 调用后端接口获取原始报告数据
      final response = await _dio.get('http://115.190.24.116:717/report_raw');
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
            };
          }).toList();
        });
      }
    } catch (e) {
      // 网络或解析异常处理
      print('Error loading reports: $e');
      // 可以在这里显示错误消息给用户
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // 下拉刷新报告列表
  Future<void> _refreshReports() async {
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

  // 展示报告详情弹窗，包括图片展示和数据饼图
  void _showDetailDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title'] ?? ''), // 报告标题
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 展示报告详细内容
              Text(report['detail'] ?? ''),
              const SizedBox(height: 16),

              // 数据分析饼图区域
              const Text(
                '数据分析:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // 三个饼图垂直排列
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

              // 如果有图片则展示图片区域
              if (report['imagePaths'] != null &&
                  report['imagePaths'].isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  '相关图片:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // 遍历所有图片路径并展示图片
                ...report['imagePaths']
                    .map<Widget>(
                      (imagePath) => Padding(
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
                    )
                    .toList(),
              ],
            ],
          ),
        ),
        actions: [
          // 关闭弹窗按钮
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("主页"),
      ),
      body: Stack(
        children: [
          // 加载中显示进度条，否则显示报告列表
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refreshReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(report['title'] ?? ''), // 报告标题
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 展示报告摘要
                              Text(report['summary'] ?? ''),
                              // 如果有图片则提示"包含图片"
                              if (report['imagePaths'] != null &&
                                  report['imagePaths'].isNotEmpty)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
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
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios), // 右侧箭头
                          onTap: () => _showDetailDialog(report), // 点击展示详情弹窗
                        ),
                      );
                    },
                  ),
                ),
          // 右下角刷新按钮和清空按钮
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
    );
  }
}
