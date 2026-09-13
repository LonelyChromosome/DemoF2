import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  const platformRoot = 'platform/android_widget/app/src/main';
  const androidRoot = 'android/app/src/main';
  const packagePath =
      'kotlin/vn/edu/phenikaa/better_phenikaa_schedule';

  test('theme change waits for Home and keeps the current card visible', () {
    final mainActivity = _read('$platformRoot/$packagePath/MainActivity.kt');
    final provider = _read(
      '$platformRoot/$packagePath/ScheduleWidgetProvider.kt',
    );

    expect(mainActivity, contains('pendingWidgetTargetTheme'));
    expect(mainActivity, contains('override fun onStop()'));
    expect(mainActivity, contains('HOME_SURFACE_SETTLE_MS'));
    expect(mainActivity, contains('stageThemeTransition'));
    expect(mainActivity, contains('refreshHiddenCollection'));
    expect(provider, contains('keepCurrent.setFloat'));
    expect(provider, contains('partiallyUpdateAppWidget'));
    expect(provider, contains('PHASE_STAGED'));
    expect(provider, contains('PHASE_FADING_OUT'));
    expect(provider, contains('PHASE_WAITING_TARGET'));
    expect(provider, contains('PHASE_FADING_IN'));
  });

  test('transition uses a bounded fade and waits for target data', () {
    final provider = _read(
      '$platformRoot/$packagePath/ScheduleWidgetProvider.kt',
    );
    final service = _read(
      '$platformRoot/$packagePath/ScheduleWidgetService.kt',
    );

    expect(provider, contains('runFadeOut'));
    expect(provider, contains('switchTargetCollection'));
    expect(provider, contains('maybeStartFadeIn'));
    expect(provider, contains('runFadeIn'));
    expect(provider, contains('TRANSITION_FRAME_COUNT = 8'));
    expect(provider, contains('TRANSITION_FRAME_DELAY_MS = 36L'));
    expect(provider, contains('ACTION_COLLECTION_FRAME_READY'));
    expect(service, contains('signalReadyOnce'));
    expect(service, contains('renderWidgetTransitionFrame'));
  });

  test('new widget remains swipeable and initializes its date state', () {
    final provider = _read(
      '$platformRoot/$packagePath/ScheduleWidgetProvider.kt',
    );
    final service = _read(
      '$platformRoot/$packagePath/ScheduleWidgetService.kt',
    );
    final layout = _read('$platformRoot/res/layout/schedule_widget.xml');

    expect(provider, contains('val showRefreshCover = false'));
    expect(provider, contains('views.setRemoteAdapter'));
    expect(provider, contains('views.setPendingIntentTemplate'));
    expect(provider, contains('notifyAppWidgetViewDataChanged'));
    expect(provider, contains('views.setDisplayedChild(R.id.widget_list, 0)'));
    expect(provider, contains('override fun onDeleted'));
    expect(service, contains('rememberVisiblePosition'));
    expect(service, contains('selectedDateKey(widgetId)'));
    expect(layout, contains('<StackView'));
    expect(layout, contains('android:loopViews="true"'));
    expect(layout, contains('android:clickable="true"'));
    expect(layout, contains('android:inAnimation="@animator/widget_instant_in"'));
    expect(layout, contains('android:outAnimation="@animator/widget_instant_out"'));
  });

  test('responsive sizing, safe cover, and Minecraft font remain', () {
    final provider = _read(
      '$platformRoot/$packagePath/ScheduleWidgetProvider.kt',
    );
    final service = _read(
      '$platformRoot/$packagePath/ScheduleWidgetService.kt',
    );
    final layout = _read('$platformRoot/res/layout/schedule_widget.xml');
    final info = _read('$platformRoot/res/xml/schedule_widget_info.xml');

    expect(provider, contains('exactWidgetSizes'));
    expect(provider, contains('setViewLayoutWidth'));
    expect(provider, contains('setViewLayoutHeight'));
    expect(service, contains('CONTENT_LEFT_FRACTION'));
    expect(service, contains('R.font.minecraft_custom'));
    expect(File('assets/fonts/minecraft.ttf').lengthSync(), greaterThan(0));
    expect(
      File('$platformRoot/res/font/minecraft_custom.ttf').lengthSync(),
      greaterThan(0),
    );
    expect(layout, contains('android:id="@+id/widget_refresh_cover"'));
    expect(layout, contains('android:visibility="gone"'));
    expect(info, contains('android:minResizeWidth="220dp"'));
    expect(info, contains('android:resizeMode="horizontal"'));
  });

  test('generated Android sources mirror the canonical platform files', () {
    const mirroredFiles = <String>[
      '$packagePath/MainActivity.kt',
      '$packagePath/ScheduleWidgetProvider.kt',
      '$packagePath/ScheduleWidgetService.kt',
      'res/layout/schedule_widget.xml',
      'res/layout/schedule_widget_item.xml',
      'res/font/minecraft_custom.ttf',
      'res/xml/schedule_widget_info.xml',
      'res/drawable-nodpi/ic_launcher_foreground.png',
      'res/mipmap-hdpi/ic_launcher.png',
      'res/mipmap-hdpi/ic_launcher_round.png',
      'res/mipmap-mdpi/ic_launcher.png',
      'res/mipmap-mdpi/ic_launcher_round.png',
      'res/mipmap-xhdpi/ic_launcher.png',
      'res/mipmap-xhdpi/ic_launcher_round.png',
      'res/mipmap-xxhdpi/ic_launcher.png',
      'res/mipmap-xxhdpi/ic_launcher_round.png',
      'res/mipmap-xxxhdpi/ic_launcher.png',
      'res/mipmap-xxxhdpi/ic_launcher_round.png',
    ];

    for (final relativePath in mirroredFiles) {
      expect(
        File('$androidRoot/$relativePath').readAsBytesSync(),
        File('$platformRoot/$relativePath').readAsBytesSync(),
        reason: '$relativePath is out of sync',
      );
    }
  });
}
