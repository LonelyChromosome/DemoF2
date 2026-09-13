import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _read(String path) => File(path).readAsStringSync();

void main() {
  const appGroup = 'group.vn.edu.phenikaa.betterphenikaa';
  const appBundle = 'vn.edu.phenikaa.betterphenikaa';
  const widgetBundle = 'vn.edu.phenikaa.betterphenikaa.widget';

  test('iOS Runner and WidgetKit target keep their production identities', () {
    final project = _read('ios/Runner.xcodeproj/project.pbxproj');
    final runnerInfo = _read('ios/Runner/Info.plist');
    final widgetInfo = _read('ios/BetterPhenikaaWidget/Info.plist');

    expect(project, contains('productType = "com.apple.product-type.app-extension"'));
    expect(project, contains('BetterPhenikaaWidget.appex in Embed App Extensions'));
    expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = $appBundle;'));
    expect(project, contains('PRODUCT_BUNDLE_IDENTIFIER = $widgetBundle;'));
    expect(runnerInfo, contains('<string>Better Phenikaa App</string>'));
    expect(runnerInfo, contains('<string>betterphenikaa</string>'));
    expect(widgetInfo, contains('com.apple.widgetkit-extension'));
  });

  test('Flutter and WidgetKit share one App Group and snapshot key', () {
    final bridge = _read('lib/platform/home_widget_bridge.dart');
    final widget = _read(
      'ios/BetterPhenikaaWidget/BetterPhenikaaWidget.swift',
    );
    final runnerEntitlements = _read('ios/Runner/Runner.entitlements');
    final widgetEntitlements = _read(
      'ios/BetterPhenikaaWidget/BetterPhenikaaWidget.entitlements',
    );

    for (final source in <String>[
      bridge,
      widget,
      runnerEntitlements,
      widgetEntitlements,
    ]) {
      expect(source, contains(appGroup));
    }
    expect(bridge, contains('better_phenikaa_snapshot_v1'));
    expect(widget, contains('better_phenikaa_snapshot_v1'));
    expect(bridge, contains("iOSWidgetName = 'BetterPhenikaaWidget'"));
    expect(widget, contains('widgetKind = "BetterPhenikaaWidget"'));
  });

  test('iOS widget exposes schedule, themes, and supported families', () {
    final widget = _read(
      'ios/BetterPhenikaaWidget/BetterPhenikaaWidget.swift',
    );

    expect(widget, contains('JSONDecoder().decode(StoredSnapshot.self'));
    expect(widget, contains('case "minecraft"'));
    expect(widget, contains('case "steam"'));
    expect(widget, contains('.supportedFamilies([.systemSmall, .systemMedium])'));
    expect(widget, contains('.widgetURL(URL(string: "betterphenikaa://schedule"))'));
  });

  test('iOS artwork and CocoaPods configuration are committed', () {
    final pubspec = _read('pubspec.yaml');
    final iconContents = _read(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json',
    );

    expect(pubspec, contains('enable-swift-package-manager: false'));
    expect(_read('ios/Podfile'), contains("platform :ios, '15.0'"));
    expect(iconContents, contains('Icon-App-1024x1024@1x.png'));
    expect(
      File(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
        'Icon-App-1024x1024@1x.png',
      ).lengthSync(),
      greaterThan(0),
    );
    expect(
      File(
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/'
        'LaunchImage@3x.png',
      ).lengthSync(),
      greaterThan(0),
    );
  });
}
