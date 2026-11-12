import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:webview_flutter/webview_flutter.dart';

import '../models/html_print_document.dart';
import '../../shared/widgets/app_app_bar.dart';
import '../../shared/widgets/app_error_widget.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/skeleton/skeleton.dart';

class InvoiceHtmlPrintPreviewScreen extends StatefulWidget {
  const InvoiceHtmlPrintPreviewScreen({
    super.key,
    required this.htmlContent,
    required this.title,
    this.baseUrl,
    this.documentId,
    this.cookies = const {},
    this.loadPdf,
    this.embedded = false,
    this.allowDownload = false,
    this.pdfMarginMm = 0,
  }) : assert(pdfMarginMm >= 0);

  /// Preserve the invoice's desktop print layout and let WebView fit it to
  /// the screen, with pinch zoom available for reading small text.
  // static String prepareHtml(String response) {
  //   final html = HtmlPrintDocument.extractHtml(response).replaceAll(
  //     RegExp(
  //       r'<meta\b[^>]*\bname\s*=\s*["\x27]viewport["\x27][^>]*>',
  //       caseSensitive: false,
  //     ),
  //     '',
  //   );
  //   // return html.replaceFirst(
  //   //   RegExp(r'</head\s*>', caseSensitive: false),
  //   //   '<meta name="viewport" content="width=980, user-scalable=yes">'
  //   //   '<style>'
  //   //   '.print-toolbar,.action-banner,.page-head,.printview-header'
  //   //   '{display:none!important;}'
  //   //   'html,body{margin:0!important;padding:0!important;background:white!important;}'
  //   //   '.print-format-gutter{margin:0!important;padding:0!important;background:white!important;}'
  //   //   '.print-format{margin:0 auto!important;box-shadow:none!important;}'
  //   //   '</style></head>',
  //   // );

  //   return html.replaceFirst(
  //     RegExp(r'</head\s*>', caseSensitive: false),
  //     '<meta name="viewport" content="width=980, user-scalable=yes">'
  //     '<style>'
  //     '.print-toolbar,.action-banner,.page-head,.printview-header'
  //     '{display:none!important;}'
  //     'html,body{margin:0!important;padding:0!important;background:red!important;}'
  //     '.print-format-gutter{margin:8px!important;padding:8px!important;background:red!important;}'
  //     '.print-format{margin:8px auto!important;padding:8px!important;background:white!important;box-shadow:none!important;}'
  //     '</style></head>',
  //   );
  // }

  static String prepareHtml(String response) {
    var html = HtmlPrintDocument.extractHtml(response);

    // Remove existing viewport meta tags.
    html = html.replaceAll(
      RegExp(
        r'<meta\b[^>]*\bname\s*=\s*["\x27]viewport["\x27][^>]*>',
        caseSensitive: false,
      ),
      '',
    );

    const customStyles = '''
<meta name="viewport"
      content="width=980, user-scalable=yes">

<style id="custom-print-style">
  html {
    margin: 0 !important;
    padding: 0 !important;
    background: red !important;
  }

  body {
    margin: 0 !important;
    padding: 8px !important;
    background: red !important;
    min-height: 100vh !important;
    box-sizing: border-box !important;
  }

  .print-toolbar,
  .action-banner,
  .page-head,
  .printview-header {
    display: none !important;
  }

  .print-format-gutter {
    margin: 0 !important;
    padding: 0 !important;
    background: transparent !important;
  }

  .print-format {
    margin: 0 auto !important;
    padding: 8px !important;
    background: white !important;
    box-shadow: none !important;
    box-sizing: border-box !important;
  }
</style>
''';

    // Insert styles at the end of head if available.
    final headEnd = RegExp(r'</head\s*>', caseSensitive: false);

    if (headEnd.hasMatch(html)) {
      return html.replaceFirst(headEnd, '$customStyles</head>');
    }

    // If no head exists, insert a complete head.
    final htmlStart = RegExp(r'<html\b[^>]*>', caseSensitive: false);

    if (htmlStart.hasMatch(html)) {
      return html.replaceFirstMapped(
        htmlStart,
        (match) => '${match.group(0)}<head>$customStyles</head>',
      );
    }

    // Handle HTML fragments.
    return '''
<!DOCTYPE html>
<html>
<head>
$customStyles
</head>
<body>
$html
</body>
</html>
''';
  }

  /// Additional white inset inside every PDF page, in millimetres.
  final double pdfMarginMm;
  final bool allowDownload;
  final bool embedded;
  final String htmlContent;
  final String title;
  final Uri? baseUrl;
  final String? documentId;
  final Map<String, String> cookies;
  final Future<Uint8List> Function()? loadPdf;

  @override
  State<InvoiceHtmlPrintPreviewScreen> createState() =>
      _InvoiceHtmlPrintPreviewScreenState();
}

class _InvoiceHtmlPrintPreviewScreenState
    extends State<InvoiceHtmlPrintPreviewScreen> {
  WebViewController? _controller;
  String? _error;
  bool _ready = false;
  bool _loading = true;
  bool _exporting = false;
  int _progress = 0;
  int _generation = 0;
  Uint8List? _pdf;
  Future<Uint8List>? _pdfRequest;
  final _zoomController = TransformationController();
  bool get _usePdf => widget.loadPdf != null;

  Future<Uint8List> _loadPdf() => _pdfRequest ??= () async {
    final generation = _generation;
    var bytes = await widget.loadPdf!();
    if (widget.pdfMarginMm > 0) {
      // Add space to the PDF page itself so the server template retains
      // its original dimensions and text size inside the new margins.
      const dpi = 300.0;
      final document = pw.Document();
      var pageCount = 0;
      await for (final page in Printing.raster(bytes, dpi: dpi)) {
        final contentWidth = page.width * PdfPageFormat.inch / dpi;
        final contentHeight = page.height * PdfPageFormat.inch / dpi;
        final margin = widget.pdfMarginMm * PdfPageFormat.mm;
        final width = contentWidth + margin * 2;
        final height = contentHeight + margin * 2;
        final image = pw.MemoryImage(await page.toPng());
        document.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(width, height),
            margin: pw.EdgeInsets.all(margin),
            build: (_) => pw.Image(
              image,
              width: contentWidth,
              height: contentHeight,
              fit: pw.BoxFit.contain,
            ),
          ),
        );
        pageCount++;
      }
      if (pageCount == 0) throw StateError('The print document has no pages.');
      bytes = await document.save();
    }
    if (mounted && generation == _generation) _pdf = bytes;
    return bytes;
  }();
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

  @override
  void didUpdateWidget(covariant InvoiceHtmlPrintPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfMarginMm != widget.pdfMarginMm ||
        oldWidget.documentId != widget.documentId ||
        oldWidget.htmlContent != widget.htmlContent ||
        oldWidget.loadPdf != widget.loadPdf) {
      _refresh();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Hot reload preserves State, including the previously generated PDF.
    if (_usePdf) _refresh();
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
    if (_usePdf) {
      setState(() => _loading = false);
      return;
    }
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
      html = InvoiceHtmlPrintPreviewScreen.prepareHtml(html);
      if (_official) {
        final controller = _controller ?? WebViewController();
        await controller.setJavaScriptMode(JavaScriptMode.disabled);
        await controller.setBackgroundColor(Colors.red);
        await controller.enableZoom(true);
        await controller.setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (mounted && generation == _generation) {
                setState(() => _progress = progress);
              }
            },
            onPageFinished: (_) async {
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
        await controller.loadHtmlString(
          html,
          baseUrl: widget.baseUrl?.toString(),
        );
      } else {
        if (!mounted || generation != _generation) return;
        setState(() {
          _error = 'Invoice preview is available on Android, iOS and macOS. You can still print or export the PDF from the toolbar.';
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

  void _refresh() {
    if (_loading && _error == null) return;
    setState(() {
      _error = null;
      _loading = true;
      _ready = false;
      _progress = 0;
      _pdf = null;
      _pdfRequest = null;
      _zoomController.value = Matrix4.identity();
    });
    unawaited(_initialize());
  }

  Future<void> _export(bool share) async {
    if (_exporting || widget.loadPdf == null) return;
    setState(() => _exporting = true);
    try {
      final bytes = _pdf ?? await _loadPdf();
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
          dynamicLayout: false,
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

  Future<void> _download() async {
    if (_exporting || widget.loadPdf == null) return;
    setState(() => _exporting = true);
    try {
      final bytes = _pdf ?? await _loadPdf();
      if (!mounted) return;
      final name = (widget.documentId ?? 'document').replaceAll(
        RegExp(r'[^\w-]'),
        '_',
      );
      final path = await FilePicker.saveFile(
        dialogTitle: 'Download PDF',
        fileName: '$name.pdf',
        mimeType: 'application/pdf',
        bytes: bytes,
      );
      if (mounted && path != null) {
        AppSnackbar.show(
          context,
          'PDF downloaded successfully',
          type: AppMessageType.success,
        );
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.show(
          context,
          'Unable to download PDF: $error',
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
    _zoomController.dispose();
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
                  tooltip: widget.allowDownload
                      ? 'Share PDF'
                      : 'Save or share PDF',
                  onPressed: _exporting ? null : () => _export(true),
                  icon: const Icon(Icons.ios_share),
                ),
                if (widget.allowDownload)
                  IconButton(
                    tooltip: 'Download PDF',
                    onPressed: _exporting ? null : _download,
                    icon: const Icon(Icons.download_outlined),
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
                if (_usePdf)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Pinch to zoom • Double-tap to zoom or reset'),
                  ),

                Expanded(
                  child: _usePdf
                      ? PdfPreview.builder(
                          key: ValueKey(_generation),
                          build: (_) => _loadPdf(),
                          useActions: false,
                          canChangePageFormat: false,
                          canChangeOrientation: false,
                          canDebug: false,
                          dynamicLayout: false,
                          pagesBuilder: (context, pages) => GestureDetector(
                            onDoubleTap: () {
                              final zoomed =
                                  _zoomController.value.getMaxScaleOnAxis() > 1;
                              _zoomController.value = zoomed
                                  ? Matrix4.identity()
                                  : Matrix4.diagonal3Values(2.5, 2.5, 1);
                            },
                            child: InteractiveViewer(
                              transformationController: _zoomController,
                              minScale: 1,
                              maxScale: 5,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    for (final page in pages)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Image(
                                          image: page.image,
                                          width: double.infinity,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          loadingWidget: const SkeletonShimmer(
                            label: 'Loading document preview...',
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: SkeletonInfoRows(count: 8),
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          previewPageMargin: const EdgeInsets.only(bottom: 12),
                          onError: (context, error) => AppErrorWidget(
                            message:
                                'Unable to display the document. Please retry.',
                            onRetry: _refresh,
                          ),
                        )
                      : Stack(
                          children: [
                            if (_ready)
                              Positioned.fill(
                                child: ColoredBox(
                                  color: Colors.red,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: WebViewWidget(
                                      controller: _controller!,
                                    ),
                                  ),
                                ),
                              ),

                            if (_loading)
                              Positioned.fill(
                                child: ColoredBox(
                                  color: Colors.white,
                                  child: SkeletonShimmer(
                                    label:
                                        'Loading print preview ($_progress%)...',
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
