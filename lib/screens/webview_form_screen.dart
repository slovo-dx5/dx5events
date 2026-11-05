import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../dioServices/dioPostService.dart';
import '../services/activity_logger.dart';

/// Shows a hosted HTML form and saves what it submits, together with the
/// attendee's details, to Directus `app_webview_links_data`.
///
/// Bridge contract (see docs/features/webview-forms.md):
/// - App → page: `window.DX5_USER` is set and a `dx5:ready` event fired once
///   the page has loaded.
/// - Page → app: `DX5Form.postMessage(JSON.stringify({type: 'submit', data}))`
///   or `{type: 'close'}`.
/// - App → page: `window.dx5OnSubmitResult(ok)` after a submit is saved
///   (true) or failed (false; the page stays open so the user can retry).
class WebViewFormScreen extends StatefulWidget {
  final String url;
  final String title;
  final Map<String, dynamic> userDetails;

  /// Activity log entry written after a successful submit, if any.
  final String? activityAction;
  final String? eventId;

  /// Shown as "Use in-app form" when the page fails to load.
  final VoidCallback? onFallback;

  const WebViewFormScreen({
    super.key,
    required this.url,
    required this.userDetails,
    this.title = 'Form',
    this.activityAction,
    this.eventId,
    this.onFallback,
  });

  @override
  State<WebViewFormScreen> createState() => _WebViewFormScreenState();
}

class _WebViewFormScreenState extends State<WebViewFormScreen> {
  late final WebViewController _controller;
  late final String _host;

  bool _loading = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _host = Uri.parse(widget.url).host;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('DX5Form', onMessageReceived: _onMessage)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            _injectUser();
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            // Stay on the form's own site; anything else opens outside.
            if (uri.host == _host || uri.isScheme('about') || uri.isScheme('data')) {
              return NavigationDecision.navigate;
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            debugPrint('[WebViewForm] ${error.errorCode} ${error.description}');
            // Sub-resource failures (an image, a font) are not fatal.
            if (error.isForMainFrame == false) return;
            if (mounted) {
              setState(() {
                _loading = false;
                _loadError = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Watches the page's own submit requests so forms that don't call the
  /// bridge still reach Directus. Today: the CIO Africa survey app
  /// (surveys.cioafrica.co), which saves through the Supabase RPC
  /// `submit_survey_response`. The page keeps saving to its own backend;
  /// this only mirrors a submit that succeeded. supabase-js looks `fetch` up
  /// on every call, so wrapping it after load is enough. Idempotent.
  static const String _captureScript = r'''
(function () {
  if (window.__dx5CaptureInstalled || !window.fetch) return;
  window.__dx5CaptureInstalled = true;
  var origFetch = window.fetch;
  window.fetch = function (input, init) {
    var url = typeof input === 'string' ? input : (input && input.url) || '';
    var method = ((init && init.method) || (input && input.method) || 'GET').toUpperCase();
    var p = origFetch.apply(this, arguments);
    if (method === 'POST' && /\/rest\/v1\/rpc\/submit_survey_response(\?|$)/.test(url)) {
      p.then(function (res) {
        if (!res.ok) return;
        var body = {};
        try { body = JSON.parse((init && init.body) || '{}'); } catch (e) {}
        DX5Form.postMessage(JSON.stringify({
          type: 'submit',
          captured: true,
          data: {
            source: 'cioafrica_survey',
            survey_slug: body.p_slug || null,
            response: body.p_response_data || null,
            time_seconds: body.p_time_seconds || null,
            completion_status: body.p_completion_status || null,
            respondent_email: body.p_respondent_email || null
          }
        }));
      }).catch(function () {});
    }
    return p;
  };
})();
''';

  Future<void> _injectUser() async {
    final user = jsonEncode(widget.userDetails);
    try {
      await _controller.runJavaScript(
        'window.isFlutterApp = true;'
        'window.DX5_USER = $user;'
        "window.dispatchEvent(new CustomEvent('dx5:ready', {detail: window.DX5_USER}));",
      );
      await _controller.runJavaScript(_captureScript);
    } catch (e) {
      debugPrint('[WebViewForm] could not inject scripts ($e)');
    }
  }

  void _onMessage(JavaScriptMessage message) {
    Map<String, dynamic> msg;
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map<String, dynamic>) return;
      msg = decoded;
    } catch (_) {
      debugPrint('[WebViewForm] ignoring non-JSON message');
      return;
    }
    switch (msg['type']) {
      case 'submit':
        final raw = msg['data'];
        final data = raw is Map<String, dynamic> ? raw : {'value': raw};
        if (msg['captured'] == true) {
          _saveCaptured(data);
        } else {
          _submit(data);
        }
        break;
      case 'close':
        if (mounted) Navigator.of(context).pop();
        break;
    }
  }

  Future<void> _submit(Map<String, dynamic> data) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await DioPostService().sendWebviewFormData(
        link: widget.url,
        userDetails: {
          ...widget.userDetails,
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
        },
        data: data,
      );
      if (widget.activityAction != null) {
        ActivityLogger.instance.log(
          action: widget.activityAction!,
          eventId: widget.eventId,
          targetType: 'webview_form',
          targetId: widget.url,
        );
      }
      await _reportResult(true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you! Your response has been submitted.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('[WebViewForm] submit failed ($e)');
      await _reportResult(false);
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit. Check your internet and try again.')),
      );
    }
  }

  /// A submit the page already saved to its own backend (see
  /// [_captureScript]). The user has seen the page's thank-you, so a Directus
  /// failure is retried here rather than handed back to them.
  Future<void> _saveCaptured(Map<String, dynamic> data) async {
    if (_submitting) return;
    _submitting = true;
    final userDetails = {
      ...widget.userDetails,
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    };
    var saved = false;
    for (var attempt = 0; attempt < 3 && !saved; attempt++) {
      if (attempt > 0) await Future.delayed(Duration(seconds: 2 * attempt));
      try {
        await DioPostService().sendWebviewFormData(
          link: widget.url,
          userDetails: userDetails,
          data: data,
        );
        saved = true;
      } catch (e) {
        debugPrint('[WebViewForm] captured save attempt ${attempt + 1} failed ($e)');
      }
    }
    if (saved && widget.activityAction != null) {
      ActivityLogger.instance.log(
        action: widget.activityAction!,
        eventId: widget.eventId,
        targetType: 'webview_form',
        targetId: widget.url,
      );
    }
    // Let the page's own thank-you screen show before closing.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your feedback!')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _reportResult(bool ok) async {
    try {
      await _controller.runJavaScript(
        'window.dx5OnSubmitResult && window.dx5OnSubmitResult($ok);',
      );
    } catch (_) {}
  }

  void _retry() {
    setState(() {
      _loadError = null;
      _loading = true;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), elevation: 0),
      body: _loadError != null
          ? _buildError()
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (_submitting)
                  const ModalBarrier(dismissible: false, color: Colors.black26),
                if (_submitting) const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            const Text(
              "We couldn't load this form.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _retry, child: const Text('Retry')),
            if (widget.onFallback != null)
              TextButton(
                onPressed: widget.onFallback,
                child: const Text('Use in-app form'),
              ),
          ],
        ),
      ),
    );
  }
}
