# TownPass - 台北通

台北通是由台北市政府開發的開源專案，旨在提供市民便捷的數位市政服務平台。

## 台北好安心

「台北好安心」是整合在台北通 App 中的智慧安全路線規劃服務，透過分析台北市公共安全數據，為使用者提供最安全的移動路線建議。

### 主要功能

- **智慧安全路線規劃**：根據犯罪統計、路燈分布、警察局位置等資料計算最安全路線
- **多種交通模式**：支援行人、自行車、車輛三種交通方式
- **即時位置追蹤**：透過 GPS 定位提供準確的路線導航
- **圖層視覺化**：可視化顯示各種安全相關資訊
- **WebView 整合**：無縫整合網頁版地圖服務至原生 App

### 相關專案

台北好安心採用前後端分離架構：

- **前端**：[https://github.com/yd-tw/taipei-codefest-2025](https://github.com/yd-tw/taipei-codefest-2025)
- **後端**：[https://github.com/mcg25035/taipei-codefest-2025-nov-backend](https://github.com/mcg25035/taipei-codefest-2025-nov-backend)

### 技術實作

台北好安心透過 WebView 整合網頁版地圖服務，並實現 Flutter 與 WebView 之間的雙向通訊：

```dart
MyServiceItemId.syncControl => MyServiceItem(
  title: '台北好安心',
  description: '安全路線規劃、提醒',
  icon: Assets.svg.iconLocationSearch24.svg(),
  category: MyServiceCategory.explore,
  destinationUrl: 'http://192.168.22.73:3001', // 開發環境
  forceWebViewTitle: '台北好安心',
)
```

#### Flutter to WebView 通訊

- GPS 位置廣播：將裝置的即時位置傳送給 WebView
- 使用者模式同步：同步使用者選擇的交通模式（行人/自行車/車輛）

#### WebView to Flutter 通訊

- 接收網頁端的狀態變更
- 處理使用者互動事件

---

## 開發環境設置

### 環境需求

- [Flutter](https://docs.flutter.dev/get-started/install) 或 [FVM](https://fvm.app/documentation/getting-started/installation)
- [XCode](https://developer.apple.com/xcode/)（iOS 開發）
- [Android SDK](https://developer.android.com/studio/index.html)（Android 開發）

### 建置專案

1. 安裝專案相依套件：

   ```bash
   flutter pub get
   ```

2. 產生必要的程式碼檔案：

   ```bash
   flutter packages pub run build_runner build
   ```

3. 執行專案：

   ```bash
   flutter run
   ```

### Android 開發注意事項

如需使用 HTTP 連線（開發環境），請在 `AndroidManifest.xml` 中啟用 cleartext traffic：

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

---

## 關於 TownPass

TownPass 不僅僅是一個應用程式，它是一個開放的社群專案。透過開源，每位市民都能參與應用程式的構思、開發和優化。這不僅提升市民的參與感和滿意度，也能集思廣益，持續改善應用程式，使其真正服務於市民。

我們歡迎開發者提交程式碼、回報問題、提供建議，甚至開發新功能和創意想法，共同完善 TownPass，邁向智慧城市的願景。

### 更多資訊

詳細的開發指南請參考[官方文件](https://tpe-guideline.web.app/en/docs/)。

---

**讓台北市的每一步都更安心 🛡️**
