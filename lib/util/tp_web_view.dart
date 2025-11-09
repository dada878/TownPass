import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:town_pass/gen/assets.gen.dart';
import 'package:town_pass/util/tp_app_bar.dart';
import 'package:town_pass/util/tp_colors.dart';
import 'package:town_pass/util/web_message_handler/tp_web_message_listener.dart';
import 'package:town_pass/page/sync_test/webview_push_service.dart';

class WebViewArgument {
  final String? url;
  final String? forceTitle;

  const WebViewArgument({
    this.url,
    this.forceTitle,
  });
}

/// App 內開網頁使用，可使用 `openUrl` 並以 `url` 為參數帶入開啟網頁： \
/// `forceTitle` 將會強制套用網頁標題為
///
/// ```
/// Get.toNamed(TPRoute.webView, arguments: url);
/// ```
class TPWebView extends StatelessWidget {
  final TPAppBarController? titleController;

  TPWebView({
    super.key,
    this.titleController,
  });

  String get url => (Get.arguments as WebViewArgument?)?.url ?? '';

  String? get forceTitle => (Get.arguments as WebViewArgument?)?.forceTitle;

  final TPAppBarController _defaultTitleController = TPAppBarController();

  TPAppBarController get appBarController => titleController ?? _defaultTitleController;

  final Rxn<InAppWebViewController> webViewController = Rxn<InAppWebViewController>();

  final RxBool canGoBack = RxBool(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TPAppBar(
        backgroundColor: TPColors.primary500,
        foregroundColor: TPColors.white,
        leading: Obx(
          () => switch (canGoBack.value) {
            true => IconButton(
                icon: Assets.svg.expand.svg(),
                onPressed: () async => await webViewController.value?.goBack(),
                style: const ButtonStyle(
                  iconSize: WidgetStatePropertyAll<double>(24),
                ),
              ),
            false => const SizedBox.shrink(),
          },
        ),
        actions: [
          CloseButton(
            color: TPColors.white,
            onPressed: () => Get.back(),
            style: const ButtonStyle(
              iconSize: WidgetStatePropertyAll<double>(24),
            ),
          ),
        ],
        title: appBarController.title.value,
        controller: appBarController,
      ),
      body: TPInAppWebView(
        onWebViewCreated: (controller) {
          webViewController.value = controller;
          try {
            controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
          } catch (_) {
            controller.loadData(data: _failedToLoadUrlData(url: url));
          }
        },
        onUpdateVisitedHistory: (_, __, ___) async {
          canGoBack.value = await webViewController.value?.canGoBack() ?? false;
        },
        onTitleChanged: (_, title) {
          appBarController.title.value = switch (forceTitle == null) {
            true => title,
            false => forceTitle,
          };
        },
        onGeolocationPermissionsShowPrompt: (controller, origin) async {
          // should be deal individually (ask for user agreement)
          return GeolocationPermissionShowPromptResponse(origin: origin, allow: true, retain: true);
        },
        onCloseWindow: (_) => Get.back(),
      ),
    );
  }
}

class TPInAppWebView extends StatelessWidget {
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final int? windowId;
  final HeadlessInAppWebView? headlessWebView;
  final InAppWebViewKeepAlive? keepAlive;
  final bool? preventGestureDelay;
  final TextDirection? layoutDirection;
  final InAppWebViewInitialData? initialData;
  final String? initialFile;
  final InAppWebViewSettings? initialSettings;
  final URLRequest? initialUrlRequest;
  final UnmodifiableListView<UserScript>? initialUserScripts;
  final PullToRefreshController? pullToRefreshController;
  final FindInteractionController? findInteractionController;
  final ContextMenu? contextMenu;
  final Function(InAppWebViewController, WebUri?)? onPageCommitVisible;
  final Function(InAppWebViewController, String?)? onTitleChanged;
  final Future<AjaxRequestAction> Function(InAppWebViewController, AjaxRequest)? onAjaxProgress;
  final Future<AjaxRequestAction?> Function(InAppWebViewController, AjaxRequest)? onAjaxReadyStateChange;
  final Function(InAppWebViewController, ConsoleMessage)? onConsoleMessage;
  final Future<bool?> Function(InAppWebViewController, CreateWindowAction)? onCreateWindow;
  final Function(InAppWebViewController)? onCloseWindow;
  final Function(InAppWebViewController)? onWindowFocus;
  final Function(InAppWebViewController)? onWindowBlur;
  final Function(InAppWebViewController, DownloadStartRequest)? onDownloadStartRequest;
  final Future<JsAlertResponse?> Function(InAppWebViewController, JsAlertRequest)? onJsAlert;
  final Future<JsConfirmResponse?> Function(InAppWebViewController, JsConfirmRequest)? onJsConfirm;
  final Future<JsPromptResponse?> Function(InAppWebViewController, JsPromptRequest)? onJsPrompt;
  final Function(InAppWebViewController, WebResourceRequest, WebResourceError)? onReceivedError;
  final Function(InAppWebViewController, WebResourceRequest, WebResourceResponse)? onReceivedHttpError;
  final Function(InAppWebViewController, LoadedResource)? onLoadResource;
  final Future<CustomSchemeResponse?> Function(InAppWebViewController, WebResourceRequest)? onLoadResourceWithCustomScheme;
  final Function(InAppWebViewController, WebUri?)? onLoadStart;
  final Function(InAppWebViewController, WebUri?)? onLoadStop;
  final Function(InAppWebViewController, InAppWebViewHitTestResult)? onLongPressHitTestResult;
  final Future<bool?> Function(InAppWebViewController, WebUri?, PlatformPrintJobController?)? onPrintRequest;
  final Function(InAppWebViewController, int)? onProgressChanged;
  final Future<ClientCertResponse?> Function(InAppWebViewController, URLAuthenticationChallenge)? onReceivedClientCertRequest;
  final Future<HttpAuthResponse?> Function(InAppWebViewController, URLAuthenticationChallenge)? onReceivedHttpAuthRequest;
  final Future<ServerTrustAuthResponse?> Function(InAppWebViewController, URLAuthenticationChallenge)? onReceivedServerTrustAuthRequest;
  final Function(InAppWebViewController, int, int)? onScrollChanged;
  final Function(InAppWebViewController, WebUri?, bool?)? onUpdateVisitedHistory;
  final Function(InAppWebViewController)? onWebViewCreated;
  final Future<AjaxRequest?> Function(InAppWebViewController, AjaxRequest)? shouldInterceptAjaxRequest;
  final Future<FetchRequest?> Function(InAppWebViewController, FetchRequest)? shouldInterceptFetchRequest;
  final Future<NavigationActionPolicy?> Function(InAppWebViewController, NavigationAction)? shouldOverrideUrlLoading;
  final Function(InAppWebViewController)? onEnterFullscreen;
  final Function(InAppWebViewController)? onExitFullscreen;
  final Function(InAppWebViewController, int, int, bool, bool)? onOverScrolled;
  final Function(InAppWebViewController, double, double)? onZoomScaleChanged;
  final Function(InAppWebViewController)? onDidReceiveServerRedirectForProvisionalNavigation;
  final Future<FormResubmissionAction?> Function(InAppWebViewController, WebUri?)? onFormResubmission;
  final Function(InAppWebViewController)? onGeolocationPermissionsHidePrompt;
  final Future<GeolocationPermissionShowPromptResponse?> Function(InAppWebViewController, String)? onGeolocationPermissionsShowPrompt;
  final Future<JsBeforeUnloadResponse?> Function(InAppWebViewController, JsBeforeUnloadRequest)? onJsBeforeUnload;
  final Future<NavigationResponseAction?> Function(InAppWebViewController, NavigationResponse)? onNavigationResponse;
  final Future<PermissionResponse?> Function(InAppWebViewController, PermissionRequest)? onPermissionRequest;
  final Function(InAppWebViewController, Uint8List)? onReceivedIcon;
  final Function(InAppWebViewController, LoginRequest)? onReceivedLoginRequest;
  final Function(InAppWebViewController, PermissionRequest)? onPermissionRequestCanceled;
  final Function(InAppWebViewController)? onRequestFocus;
  final Function(InAppWebViewController, WebUri, bool)? onReceivedTouchIconUrl;
  final Function(InAppWebViewController, RenderProcessGoneDetail)? onRenderProcessGone;
  final Future<WebViewRenderProcessAction?> Function(InAppWebViewController, WebUri?)? onRenderProcessResponsive;
  final Future<WebViewRenderProcessAction?> Function(InAppWebViewController, WebUri?)? onRenderProcessUnresponsive;
  final Future<SafeBrowsingResponse?> Function(InAppWebViewController, WebUri, SafeBrowsingThreat?)? onSafeBrowsingHit;
  final Function(InAppWebViewController)? onWebContentProcessDidTerminate;
  final Future<ShouldAllowDeprecatedTLSAction?> Function(InAppWebViewController, URLAuthenticationChallenge)? shouldAllowDeprecatedTLS;
  final Future<WebResourceResponse?> Function(InAppWebViewController, WebResourceRequest)? shouldInterceptRequest;
  final Future<void> Function(InAppWebViewController, MediaCaptureState?, MediaCaptureState?)? onCameraCaptureStateChanged;
  final Future<void> Function(InAppWebViewController, MediaCaptureState?, MediaCaptureState?)? onMicrophoneCaptureStateChanged;

  const TPInAppWebView({
    super.key,
    this.gestureRecognizers,
    this.windowId,
    this.headlessWebView,
    this.keepAlive,
    this.preventGestureDelay,
    this.layoutDirection,
    this.initialData,
    this.initialFile,
    this.initialSettings,
    this.initialUrlRequest,
    this.initialUserScripts,
    this.pullToRefreshController,
    this.findInteractionController,
    this.contextMenu,
    this.onPageCommitVisible,
    this.onTitleChanged,
    this.onAjaxProgress,
    this.onAjaxReadyStateChange,
    this.onConsoleMessage,
    this.onCreateWindow,
    this.onCloseWindow,
    this.onWindowFocus,
    this.onWindowBlur,
    this.onDownloadStartRequest,
    this.onJsAlert,
    this.onJsConfirm,
    this.onJsPrompt,
    this.onReceivedError,
    this.onReceivedHttpError,
    this.onLoadResource,
    this.onLoadResourceWithCustomScheme,
    this.onLoadStart,
    this.onLoadStop,
    this.onLongPressHitTestResult,
    this.onPrintRequest,
    this.onProgressChanged,
    this.onReceivedClientCertRequest,
    this.onReceivedHttpAuthRequest,
    this.onReceivedServerTrustAuthRequest,
    this.onScrollChanged,
    this.onUpdateVisitedHistory,
    this.onWebViewCreated,
    this.shouldInterceptAjaxRequest,
    this.shouldInterceptFetchRequest,
    this.shouldOverrideUrlLoading,
    this.onEnterFullscreen,
    this.onExitFullscreen,
    this.onOverScrolled,
    this.onZoomScaleChanged,
    this.onDidReceiveServerRedirectForProvisionalNavigation,
    this.onFormResubmission,
    this.onGeolocationPermissionsHidePrompt,
    this.onGeolocationPermissionsShowPrompt,
    this.onJsBeforeUnload,
    this.onNavigationResponse,
    this.onPermissionRequest,
    this.onReceivedIcon,
    this.onReceivedLoginRequest,
    this.onPermissionRequestCanceled,
    this.onRequestFocus,
    this.onReceivedTouchIconUrl,
    this.onRenderProcessGone,
    this.onRenderProcessResponsive,
    this.onRenderProcessUnresponsive,
    this.onSafeBrowsingHit,
    this.onWebContentProcessDidTerminate,
    this.shouldAllowDeprecatedTLS,
    this.shouldInterceptRequest,
    this.onCameraCaptureStateChanged,
    this.onMicrophoneCaptureStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 設定 WebView 的預設設定，啟用地理定位
    final settings = initialSettings ?? InAppWebViewSettings(
      geolocationEnabled: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
    );

    return InAppWebView(
      initialSettings: settings,
      onWebViewCreated: (controller) async {
        await controller.addWebMessageListener(TPWebMessageListener.webMessageListener());

        // 註冊 JavaScript Handlers（更可靠的雙向通訊）
        TPWebMessageListener.registerJavaScriptHandlers(controller);

        // 註冊 WebView 到推送服務
        try {
          if (Get.isRegistered<WebViewPushService>()) {
            Get.find<WebViewPushService>().registerWebView(controller);
            debugPrint('WebView registered to push service');
          }
        } catch (e) {
          debugPrint('Failed to register WebView to push service: $e');
        }

        onWebViewCreated?.call(controller);
      },
      onLoadStop: (controller, url) async {
        // 確保 WebView 完全載入後再註冊（以防 onWebViewCreated 時服務還沒準備好）
        try {
          if (Get.isRegistered<WebViewPushService>()) {
            Get.find<WebViewPushService>().registerWebView(controller);
          }
        } catch (e) {
          debugPrint('Failed to register WebView on load stop: $e');
        }

        // 呼叫原本的 onLoadStop callback
        onLoadStop?.call(controller, url);
      },
      gestureRecognizers: gestureRecognizers,
      windowId: windowId,
      headlessWebView: headlessWebView,
      keepAlive: keepAlive,
      preventGestureDelay: preventGestureDelay,
      layoutDirection: layoutDirection,
      initialData: initialData,
      initialFile: initialFile,
      initialUrlRequest: initialUrlRequest,
      initialUserScripts: initialUserScripts,
      pullToRefreshController: pullToRefreshController,
      findInteractionController: findInteractionController,
      contextMenu: contextMenu,
      onPageCommitVisible: onPageCommitVisible,
      onTitleChanged: onTitleChanged,
      onAjaxProgress: onAjaxProgress,
      onAjaxReadyStateChange: onAjaxReadyStateChange,
      onConsoleMessage: onConsoleMessage,
      onCreateWindow: onCreateWindow,
      onCloseWindow: onCloseWindow,
      onWindowFocus: onWindowFocus,
      onWindowBlur: onWindowBlur,
      onDownloadStartRequest: onDownloadStartRequest,
      onJsAlert: onJsAlert,
      onJsConfirm: onJsConfirm,
      onJsPrompt: onJsPrompt,
      onReceivedError: onReceivedError,
      onReceivedHttpError: onReceivedHttpError,
      onLoadResource: onLoadResource,
      onLoadResourceWithCustomScheme: onLoadResourceWithCustomScheme,
      onLoadStart: onLoadStart,
      // onLoadStop 已在上面處理，包含了 WebView 註冊邏輯
      onWebContentProcessDidTerminate: (controller) {
        // WebView 進程終止時，取消註冊
        try {
          if (Get.isRegistered<WebViewPushService>()) {
            Get.find<WebViewPushService>().unregisterWebView(controller);
            debugPrint('WebView unregistered from push service (terminated)');
          }
        } catch (e) {
          debugPrint('Failed to unregister WebView on terminate: $e');
        }
        onWebContentProcessDidTerminate?.call(controller);
      },
      onLongPressHitTestResult: onLongPressHitTestResult,
      onPrintRequest: onPrintRequest,
      onProgressChanged: onProgressChanged,
      onReceivedClientCertRequest: onReceivedClientCertRequest,
      onReceivedHttpAuthRequest: onReceivedHttpAuthRequest,
      onReceivedServerTrustAuthRequest: onReceivedServerTrustAuthRequest,
      onScrollChanged: onScrollChanged,
      onUpdateVisitedHistory: onUpdateVisitedHistory,
      shouldInterceptAjaxRequest: shouldInterceptAjaxRequest,
      shouldInterceptFetchRequest: shouldInterceptFetchRequest,
      shouldOverrideUrlLoading: shouldOverrideUrlLoading,
      onEnterFullscreen: onEnterFullscreen,
      onExitFullscreen: onExitFullscreen,
      onOverScrolled: onOverScrolled,
      onZoomScaleChanged: onZoomScaleChanged,
      onDidReceiveServerRedirectForProvisionalNavigation: onDidReceiveServerRedirectForProvisionalNavigation,
      onFormResubmission: onFormResubmission,
      onGeolocationPermissionsHidePrompt: onGeolocationPermissionsHidePrompt,
      onGeolocationPermissionsShowPrompt: onGeolocationPermissionsShowPrompt,
      onJsBeforeUnload: onJsBeforeUnload,
      onNavigationResponse: onNavigationResponse,
      onPermissionRequest: onPermissionRequest,
      onReceivedIcon: onReceivedIcon,
      onReceivedLoginRequest: onReceivedLoginRequest,
      onPermissionRequestCanceled: onPermissionRequestCanceled,
      onRequestFocus: onRequestFocus,
      onReceivedTouchIconUrl: onReceivedTouchIconUrl,
      onRenderProcessGone: onRenderProcessGone,
      onRenderProcessResponsive: onRenderProcessResponsive,
      onRenderProcessUnresponsive: onRenderProcessUnresponsive,
      onSafeBrowsingHit: onSafeBrowsingHit,
      // onWebContentProcessDidTerminate 已在上面處理（line 318）
      shouldAllowDeprecatedTLS: shouldAllowDeprecatedTLS,
      shouldInterceptRequest: shouldInterceptRequest,
      onCameraCaptureStateChanged: onCameraCaptureStateChanged,
      onMicrophoneCaptureStateChanged: onMicrophoneCaptureStateChanged,
    );
  }
}

String _failedToLoadUrlData({String? url}) {
  return '''
  <!DOCTYPE html>
  <html>
  <head>
    <title>Failed to load URL</title>
  </head>
  <body>

  <h1>Failed to load url:</h1>

  <h3>${switch (url) {
    null => '(null)',
    String() when url.isEmpty => '(empty)',
    _ => url,
  }}</h3>

  </body>
  </html>
  ''';
}
