import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // 假数据，实际可用API获取
  List<Map<String, String>> reports = [
    {
      'title': '水质信息',
      'summary': 'PH: 7.2，溶解氧: 8.1mg/L',
      'detail': '水质良好，各项指标正常。'
    },
    {
      'title': '风机破损情况',
      'summary': '2号风机叶片有裂纹',
      'detail': '2号风机叶片发现细小裂纹，建议尽快检修。'
    },
  ];

  bool _loading = false;

  Future<void> _refreshReports() async {
    setState(() {
      _loading = true;
    });
    // 模拟网络请求延迟
    await Future.delayed(const Duration(seconds: 1));
    // 实际可在此处请求API获取最新数据
    setState(() {
      _loading = false;
    });
  }

  void _showDetailDialog(Map<String, String> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title'] ?? ''),
        content: Text(report['detail'] ?? ''),
        actions: [
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
    return Stack(
      children: [
        _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      title: Text(report['title'] ?? ''),
                      subtitle: Text(report['summary'] ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showDetailDialog(report),
                    ),
                  );
                },
              ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: _refreshReports,
            child: const Icon(Icons.refresh),
            tooltip: '刷新报告',
          ),
        ),
      ],
    );
  }
}