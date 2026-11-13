import 'dart:async';

import 'package:flutter/material.dart';

/// Requests another page near the bottom, including lists shorter than the
/// viewport. Failed pages wait for an explicit retry rather than looping.
class AppPaginatedList extends StatefulWidget {
  const AppPaginatedList({
    super.key,
    required this.child,
    required this.hasMore,
    required this.loading,
    required this.onLoadMore,
    this.error,
  });

  final Widget child;
  final bool hasMore;
  final bool loading;
  final String? error;
  final Future<void> Function() onLoadMore;

  @override
  State<AppPaginatedList> createState() => _AppPaginatedListState();
}

class _AppPaginatedListState extends State<AppPaginatedList> {
  bool _scheduled = false;
  bool _requestInFlight = false;

  Future<void> _loadMore() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    try {
      await widget.onLoadMore();
    } finally {
      _requestInFlight = false;
    }
  }

  void _check(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical ||
        metrics.extentAfter > 400 ||
        !widget.hasMore ||
        widget.loading ||
        widget.error != null ||
        _scheduled ||
        _requestInFlight) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted &&
          widget.hasMore &&
          !widget.loading &&
          widget.error == null) {
        unawaited(_loadMore());
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) _check(notification.metrics);
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.depth == 0) _check(notification.metrics);
              return false;
            },
            child: widget.child,
          ),
        ),
      ),
      if (widget.hasMore && widget.error != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Text(widget.error!, textAlign: TextAlign.center),
              TextButton(
                onPressed: widget.loading ? null : _loadMore,
                child: const Text('Retry loading more'),
              ),
            ],
          ),
        )
      else if (widget.hasMore && widget.loading)
        const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
    ],
  );
}
