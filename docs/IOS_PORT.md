# Better Phenikaa trên iPhone

DemoF2 tái sử dụng toàn bộ lớp Flutter, parser QLĐT, dữ liệu offline, giao diện
và hệ thống theme từ DemoF. Phần riêng của iOS chỉ gồm cấu hình Runner, nhận
diện ứng dụng và widget màn hình chính viết bằng WidgetKit.

## Phạm vi đã có

- Runner iOS 15+ với bundle ID `vn.edu.phenikaa.betterphenikaa`.
- Đăng nhập QLĐT bằng `flutter_inappwebview` và dùng chung luồng import hiện có.
- Icon và launch screen Better Phenikaa.
- WidgetKit cỡ nhỏ và vừa, đọc toàn bộ snapshot lịch học qua App Group.
- Đồng bộ môn tiếp theo, phòng, giờ học và chín theme hiện có.
- Deep link `betterphenikaa://schedule` từ widget về ứng dụng.
- Build kiểm tra không ký mã trên macOS qua GitHub Actions.

WidgetKit kiểm soát lịch cập nhật và animation của widget. Vì vậy hiệu ứng đổi
theme 30 FPS trong 0,5 giây của Android không thể sao chép nguyên xi trên màn
hình chính iOS; iOS sẽ đổi sang giao diện mới theo cơ chế reload/timeline của
hệ thống.

## Chạy bằng iPhone Simulator

Yêu cầu macOS, Xcode, CocoaPods và Flutter 3.47.2.

```bash
flutter config --no-enable-swift-package-manager
flutter pub get
open -a Simulator
flutter devices
flutter run -d <simulator-id>
```

Simulator kiểm tra được ứng dụng. Việc thêm và kiểm tra widget nên thực hiện
trên một simulator đã boot bằng Xcode; dữ liệu lịch xuất hiện sau khi mở app và
đồng bộ ít nhất một lần.

## Chạy trên iPhone thật

1. Mở `ios/Runner.xcworkspace` bằng Xcode.
2. Chọn cùng một Apple Developer Team cho target `Runner` và
   `BetterPhenikaaWidget`.
3. Đăng ký App Group `group.vn.edu.phenikaa.betterphenikaa` và bật nhóm này cho
   cả hai App ID trong Apple Developer portal.
4. Giữ capability App Groups của cả hai target trỏ vào đúng nhóm trên.
5. Chọn iPhone đã bật Developer Mode rồi bấm Run.

Nếu bundle ID đã có chủ sở hữu khác, cần đổi đồng bộ bundle ID của app, widget
và App Group trước khi ký. File `.zip` sinh bởi CI chỉ dùng để xác nhận source
build được; iPhone không cài trực tiếp bản chưa ký này.

## Build thủ công

```bash
flutter analyze
flutter test
flutter build ios --release --no-codesign
```

Để phát hành TestFlight/App Store, cấu hình Distribution certificate và
provisioning profile trong Xcode rồi Archive target `Runner`.
