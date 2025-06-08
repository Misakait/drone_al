import 'package:x_amap_base/x_amap_base.dart';

class AmapConfig {
  ///高德地图 key
  static const amapAndroidKey = '146b0aaea83c76ffa85d842bd41f75de';

  ///配置您申请的apikey，在此处配置之后，可以在初始化[AMapWidget]时，通过`apiKey`属性设置
  ///
  ///注意：使用[AMapWidget]的`apiKey`属性设置的key的优先级高于通过Native配置key的优先级，
  ///使用[AMapWidget]的`apiKey`属性配置后Native配置的key将失效，请根据实际情况选择使用
  static const AMapApiKey amapApiKeys = AMapApiKey(androidKey: amapAndroidKey);
  ///高德隐私合规声明，这里只是示例，实际使用中请按照实际参数设置>          >          [AMapPrivacyStatement]的'hasContains''hasShow''hasAgree'这三个参数
  ///
  /// 注意：[AMapPrivacyStatement]的'hasContains''hasShow''hasAgree'这三个参数中有一个为false，高德SDK均不会工作，会造成地图白屏等现象
  ///
  /// 高德开发者合规指南请参考：https://lbs.amap.com/agreement/compliance
  ///
  /// 高德SDK合规使用方案请参考：https://lbs.amap.com/news/sdkhgsy
  static const AMapPrivacyStatement amapPrivacyStatement = AMapPrivacyStatement(hasContains: true, hasShow: true, hasAgree: true);
}