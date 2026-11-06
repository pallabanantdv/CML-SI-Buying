import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/html_print_document.dart';
import '../../shared/widgets/app_app_bar.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/skeleton/skeleton.dart';

class HtmlPrintPreviewScreen extends StatefulWidget {
  const HtmlPrintPreviewScreen({
    super.key,
    required this.htmlContent,
    required this.title,
    this.baseUrl,
    this.documentId,
    this.cookies = const {},
    this.loadPdf,
    this.embedded = false,
    this.cardOnly = false,
  });
  final bool embedded;
  final bool cardOnly;
  final String htmlContent;
  final String title;
  final Uri? baseUrl;
  final String? documentId;
  final Map<String, String> cookies;
  final Future<Uint8List> Function()? loadPdf;

  @override
  State<HtmlPrintPreviewScreen> createState() => _HtmlPrintPreviewScreenState();
}

class _HtmlPrintPreviewScreenState extends State<HtmlPrintPreviewScreen> {
  WebViewController? _controller;
  String? _error;
  bool _ready = false;
  bool _loading = true;
  bool _exporting = false;
  int _progress = 0;
  int _generation = 0;
  Uint8List? _pdf;
  Timer? _loadTimeout;
  bool get _official =>
      !kIsWeb &&
      const {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform);

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  bool _allowNavigation(String url) {
    final uri = Uri.tryParse(url);
    // The preview is a document, not a browser. Permit only its initial load
    // and fragment links. Subresources are unaffected by this main-frame rule.
    if (url == 'about:blank' || uri?.scheme == 'data') return _loading;
    final base = widget.baseUrl;
    return base != null &&
        uri != null &&
        (_loading || uri.hasFragment) &&
        uri.replace(fragment: '').toString() == base.toString();
  }

  Future<void> _initialize() async {
    final generation = ++_generation;
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 45), () {
      if (mounted && generation == _generation && _loading) {
        setState(
          () => _error = 'The document took too long to load. Please retry.',
        );
      }
    });
    try {
      var html = HtmlPrintDocument.extractHtml(widget.htmlContent);
      if (widget.cardOnly) {
        // Block document scripts even though native code measures the card.
        html = html
            .replaceFirst(
              RegExp(r'<head[^>]*>', caseSensitive: false),
              '<head><meta http-equiv="Content-Security-Policy" '
              'content="script-src \'none\'; object-src \'none\'">',
            )
            .replaceAll(
              RegExp(
                r'<meta[^>]+name=["\x27]viewport[\s\S]*?>',
                caseSensitive: false,
              ),
              '<meta name="viewport" content="width=device-width, initial-scale=1">',
            );
      }
      if (_official) {
        final controller = _controller ?? WebViewController();
        await controller.setJavaScriptMode(
          widget.cardOnly
              ? JavaScriptMode.unrestricted
              : JavaScriptMode.disabled,
        );
        await controller.setBackgroundColor(Colors.white);
        await controller.enableZoom(true);
        await controller.setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (mounted && generation == _generation) {
                setState(() => _progress = progress);
              }
            },
            onPageFinished: (_) async {
              if (widget.cardOnly && mounted && generation == _generation) {
                await controller.runJavaScript(_fitCardScript);
              }
              if (mounted && generation == _generation) {
                _loadTimeout?.cancel();
                setState(() => _loading = false);
              }
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame == true &&
                  mounted &&
                  generation == _generation) {
                setState(
                  () => _error = 'Unable to render the document. Please retry.',
                );
              }
            },
            onHttpError: (error) {
              // Failed images and stylesheets must not hide the document.
              if (widget.baseUrl != null &&
                  error.request?.uri == widget.baseUrl &&
                  mounted &&
                  generation == _generation) {
                setState(
                  () => _error =
                      'Unable to load the print document. Please retry.',
                );
              }
            },
            onNavigationRequest: (request) =>
                !request.isMainFrame || _allowNavigation(request.url)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent,
          ),
        );
        if (widget.baseUrl != null) {
          final manager = WebViewCookieManager();
          for (final cookie in widget.cookies.entries) {
            await manager.setCookie(
              WebViewCookie(
                name: cookie.key,
                value: cookie.value,
                domain: widget.baseUrl!.host,
                path: '/',
              ),
            );
          }
        }
        if (!mounted || generation != _generation) return;
        _controller = controller;
        setState(() {
          _ready = true;
        });
        html = html.replaceFirst(
          RegExp(r'<head[^>]*>', caseSensitive: false),
          '<head>'
          '<meta name="viewport" '
          'content="width=device-width, initial-scale=1.0, '
          'maximum-scale=1.0, user-scalable=no">',
        );
        await controller.loadHtmlString(
          html,
          baseUrl: widget.baseUrl?.toString(),
        );
      } else {
        if (!mounted || generation != _generation) return;
        setState(() {
          _error = widget.cardOnly
              ? 'Supplier card preview is available on Android, iOS and macOS.'
              : 'HTML preview is available on Android, iOS and macOS. You can still print or export the PDF from the toolbar.';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = 'Unable to open the print preview. Please retry.',
        );
      }
    }
  }

  // Keep server styling and images, remove printview chrome, and fit the
  // document's actual dimensions to both available width and height.
  //   static const _fitCardScript = r'''
  // (() => {
  //   const card = document.querySelector('.print-format') || document.body;
  //   document.querySelectorAll('.print-toolbar, .action-banner, .page-break + .print-toolbar')
  //     .forEach(el => el.style.setProperty('display', 'none', 'important'));
  //   let node = card;
  //   while (node.parentElement) {
  //     const parent = node.parentElement;
  //     Array.from(parent.children).forEach(el => {
  //       if (el !== node && !['STYLE', 'LINK', 'SCRIPT', 'HEAD'].includes(el.tagName))
  //         el.style.setProperty('display', 'none', 'important');
  //     });
  //     if (parent !== document.documentElement) {
  //       parent.style.setProperty('margin', '0', 'important');
  //       parent.style.setProperty('padding', '0', 'important');
  //       parent.style.setProperty('min-height', '0', 'important');
  //       parent.style.setProperty('background', 'white', 'important');
  //     }
  //     node = parent;
  //   }
  //   document.documentElement.style.overflow = 'hidden';
  //   document.body.style.overflow = 'hidden';
  //   const fit = () => {
  //     card.style.transform = 'none';
  //     card.style.setProperty('margin', '0', 'important');
  //     card.style.setProperty('position', 'absolute', 'important');
  //     card.style.transformOrigin = 'top left';
  //     const width = Math.max(card.scrollWidth, card.getBoundingClientRect().width);
  //     const height = Math.max(card.scrollHeight, card.getBoundingClientRect().height);
  //     const scale = Math.min((innerWidth - 24) / width, (innerHeight - 24) / height, 1);
  //     card.style.transform = 'scale(' + scale + ')';
  //     card.style.left = Math.max(12, (innerWidth - width * scale) / 2) + 'px';
  //     card.style.top = '12px';
  //   };
  //   fit();
  //   window.addEventListener('resize', fit);
  //   if (document.fonts) document.fonts.ready.then(fit);
  //   card.querySelectorAll('img').forEach(img => img.addEventListener('load', fit));
  // })();
  // ''';

  static const _fitCardScript = r'''
(() => {
  const card = document.querySelector('.print-format') || document.body;

  document.querySelectorAll(
    '.print-toolbar, .action-banner, .page-break + .print-toolbar'
  ).forEach(el => {
    el.style.setProperty('display', 'none', 'important');
  });

  const root = document.documentElement;
  const body = document.body;

  // Remove browser default spacing and background.
  [root, body].forEach(el => {
    el.style.setProperty('margin', '0', 'important');
    el.style.setProperty('padding', '0', 'important');
    el.style.setProperty('overflow-x', 'hidden', 'important');
    el.style.setProperty('background', '#ffffff', 'important');
  });

  // Remove spacing from parent containers.
  let node = card;

  while (node.parentElement) {
    const parent = node.parentElement;

    if (parent !== root) {
      parent.style.setProperty('margin', '0', 'important');
      parent.style.setProperty('padding', '0', 'important');
      parent.style.setProperty('border', '0', 'important');
      parent.style.setProperty('box-shadow', 'none', 'important');
      parent.style.setProperty('background', '#ffffff', 'important');
    }

    node = parent;
  }

  // Reset card styles before measuring.
  card.style.setProperty('position', 'absolute', 'important');
  card.style.setProperty('left', '0', 'important');
  card.style.setProperty('top', '0', 'important');
  card.style.setProperty('margin', '0', 'important');
  card.style.setProperty('max-width', 'none', 'important');
  card.style.setProperty('transform-origin', 'top left', 'important');

  const fit = () => {
    card.style.setProperty('transform', 'none', 'important');

    const width = Math.max(
      card.scrollWidth,
      card.offsetWidth,
      card.getBoundingClientRect().width,
      1
    );

    const height = Math.max(
      card.scrollHeight,
      card.offsetHeight,
      card.getBoundingClientRect().height,
      1
    );

    const viewportWidth = document.documentElement.clientWidth;

    // Scale based on width, preserving aspect ratio.
    const scale = viewportWidth / width;

    card.style.setProperty(
      'transform',
      'scale(' + scale + ')',
      'important'
    );

    card.style.setProperty('left', '0px', 'important');
    card.style.setProperty('top', '0px', 'important');

    // Allow the document to occupy the scaled card height.
    body.style.setProperty(
      'height',
      (height * scale) + 'px',
      'important'
    );
  };

  requestAnimationFrame(fit);

  window.addEventListener('resize', fit);

  if (document.fonts) {
    document.fonts.ready.then(fit);
  }

  card.querySelectorAll('img').forEach(img => {
    if (!img.complete) {
      img.addEventListener('load', fit);
    }
  });
})();
''';

  void _refresh() {
    if (_loading && _error == null) return;
    setState(() {
      _error = null;
      _loading = true;
      _ready = false;
      _progress = 0;
    });
    unawaited(_initialize());
  }

  Future<void> _export(bool share) async {
    if (_exporting || widget.loadPdf == null) return;
    setState(() => _exporting = true);
    try {
      final bytes = _pdf ??= await widget.loadPdf!();
      if (!mounted) return;
      if (share) {
        final name = (widget.documentId ?? 'document').replaceAll(
          RegExp(r'[^\w-]'),
          '_',
        );
        await Printing.sharePdf(bytes: bytes, filename: '$name.pdf');
      } else {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: widget.title,
        );
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'PDF export failed: $error',
          type: AppMessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  void dispose() {
    ++_generation;
    _loadTimeout?.cancel();
    // WebViewWidget owns the native platform-view lifecycle. Async callbacks
    // are invalidated above; the controller does not provide dispose().
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded
        ? null
        : AppAppBar(
            title: Text(
              widget.embedded ? 'Preview' : widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh preview',
                onPressed: _loading && _error == null ? null : _refresh,
                icon: const Icon(Icons.refresh),
              ),
              if (widget.loadPdf != null) ...[
                IconButton(
                  tooltip: 'Print',
                  onPressed: _exporting ? null : () => _export(false),
                  icon: const Icon(Icons.print_outlined),
                ),
                IconButton(
                  tooltip: 'Save or share PDF',
                  onPressed: _exporting ? null : () => _export(true),
                  icon: const Icon(Icons.ios_share),
                ),
              ],
            ],
          ),
    body: SafeArea(
      top: !widget.embedded,
      bottom: !widget.embedded,
      child: _error != null
          ? AppErrorWidget(message: _error!, onRetry: _refresh)
          : Column(
              children: [
                if (!widget.embedded && widget.documentId != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(widget.documentId!),
                  ),
                if (_exporting) const LinearProgressIndicator(),

                Expanded(
                  child: Stack(
                    children: [
                      if (_ready)
                        Positioned.fill(
                          // child: WebViewWidget(controller: _controller!),
                          child: SizedBox(
                            width: double.infinity,
                            height: 200,
                            child: WebViewWidget(controller: _controller!),
                          ),
                        ),
                      if (_loading)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Colors.white,
                            child: SkeletonShimmer(
                              label: 'Loading print preview ($_progress%)...',
                              child: const Padding(
                                padding: EdgeInsets.all(24),
                                child: SkeletonInfoRows(count: 8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    ),
  );
}
