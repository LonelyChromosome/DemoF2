import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

/// Keeps Flutter-side widget storage consistent across Android and iOS.
abstract final class HomeWidgetBridge {
  static const appGroupId = 'group.vn.edu.phenikaa.betterphenikaa';
  static const androidWidgetName = 'ScheduleWidgetProvider';
  static const iOSWidgetName = 'BetterPhenikaaWidget';
  static const snapshotKey = 'better_phenikaa_snapshot_v1';

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isSupported => _isAndroid || _isIOS;

  static Future<bool> publishSchedule({
    required String snapshot,
    required String subjectName,
    required String room,
    required String time,
  }) async {
    if (!isSupported) return false;
    return _guard(() async {
      await _configureIOS();
      if (_isIOS) {
        await HomeWidget.saveWidgetData<String>(snapshotKey, snapshot);
      }
      await HomeWidget.saveWidgetData<String>('subjectName', subjectName);
      await HomeWidget.saveWidgetData<String>('room', room);
      await HomeWidget.saveWidgetData<String>('time', time);
      await _reload();
    });
  }

  static Future<bool> clearSchedule() async {
    if (!isSupported) return false;
    return _guard(() async {
      await _configureIOS();
      if (_isIOS) {
        await HomeWidget.saveWidgetData<String>(snapshotKey, null);
      }
      await HomeWidget.saveWidgetData<String>('subjectName', '');
      await HomeWidget.saveWidgetData<String>('room', '');
      await HomeWidget.saveWidgetData<String>('time', '');
      await _reload();
    });
  }

  static Future<bool> syncTheme(String themeKey) async {
    if (!isSupported) return false;
    return _guard(() async {
      await _configureIOS();
      if (_isIOS) {
        await HomeWidget.saveWidgetData<String>('appTheme', themeKey);
      }
      await _reload();
    });
  }

  static Future<void> _configureIOS() async {
    if (_isIOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }
  }

  static Future<void> _reload() async {
    await HomeWidget.updateWidget(
      name: _isAndroid ? androidWidgetName : iOSWidgetName,
      androidName: _isAndroid ? androidWidgetName : null,
      iOSName: _isIOS ? iOSWidgetName : null,
    );
  }

  static Future<bool> _guard(Future<void> Function() operation) async {
    try {
      await operation();
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
