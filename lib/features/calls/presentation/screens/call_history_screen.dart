import 'package:crushhour/design_system/tokens/breakpoints.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:crushhour/features/calls/domain/models/call.dart';
import 'package:crushhour/features/calls/domain/repositories/call_manager_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/l10n/generated/app_localizations.dart';

typedef CallHistoryLoader =
    Future<List<Call>> Function(String userId, {int limit, DateTime? before});

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({
    super.key,
    this.pageSize = 20,
    this.callHistoryLoader,
    this.userIdOverride,
  });

  final int pageSize;
  final CallHistoryLoader? callHistoryLoader;
  final String? userIdOverride;

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  late final ScrollController _scrollController;
  late final _callService = context.read<CallManagerRepository>();

  List<Call> _calls = const <Call>[];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  CallHistoryLoader get _historyLoader =>
      widget.callHistoryLoader ??
      (String userId, {int limit = 20, DateTime? before}) {
        return _callService.getCallHistory(
          userId,
          limit: limit,
          before: before,
        );
      };

  String? get _userId =>
      widget.userIdOverride ?? context.read<AuthBloc>().state.user?.id;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    final l10n = AppLocalizations.of(context);
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
        _error = l10n.callHistoryLoginRequired;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _calls = const <Call>[];
      _hasMore = true;
    });

    try {
      final result = await _historyLoader(userId, limit: widget.pageSize);
      setState(() {
        _calls = result;
        _hasMore = result.length >= widget.pageSize;
      });
      _maybePrefetchMore();
    } catch (_) {
      setState(() {
        _error = l10n.callHistoryLoadError;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refresh() async {
    await _loadInitial();
  }

  Future<void> _loadMore() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty || _calls.isEmpty) return;
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final oldest = _calls.last.createdAt.subtract(
        const Duration(microseconds: 1),
      );
      final nextPage = await _historyLoader(
        userId,
        limit: widget.pageSize,
        before: oldest,
      );
      final existingIds = _calls.map((c) => c.id).toSet();
      final deduped = nextPage
          .where((c) => !existingIds.contains(c.id))
          .toList();

      setState(() {
        _calls = <Call>[..._calls, ...deduped];
        _hasMore = nextPage.length >= widget.pageSize;
      });
      _maybePrefetchMore();
    } catch (_) {
      // Keep existing data; surface one-line non-blocking feedback.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).unableToLoadMoreCall),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _maybePrefetchMore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isLoading || _isLoadingMore || !_hasMore) return;
      if (!_scrollController.hasClients) return;

      if (_scrollController.position.maxScrollExtent <= 0) {
        _loadMore();
      }
    });
  }

  List<Object> _groupCalls(List<Call> calls, AppLocalizations l10n) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));

    final today = <Call>[];
    final yesterday = <Call>[];
    final thisWeek = <Call>[];
    final earlier = <Call>[];

    for (final call in calls) {
      final created = call.createdAt;
      if (!created.isBefore(todayStart)) {
        today.add(call);
      } else if (!created.isBefore(yesterdayStart)) {
        yesterday.add(call);
      } else if (!created.isBefore(weekStart)) {
        thisWeek.add(call);
      } else {
        earlier.add(call);
      }
    }

    final grouped = <Object>[];
    if (today.isNotEmpty) {
      grouped.add(_HistoryHeader(l10n.callHistoryToday));
      grouped.addAll(today.map((c) => _HistoryItem(c)));
    }
    if (yesterday.isNotEmpty) {
      grouped.add(_HistoryHeader(l10n.callHistoryYesterday));
      grouped.addAll(yesterday.map((c) => _HistoryItem(c)));
    }
    if (thisWeek.isNotEmpty) {
      grouped.add(_HistoryHeader(l10n.callHistoryThisWeek));
      grouped.addAll(thisWeek.map((c) => _HistoryItem(c)));
    }
    if (earlier.isNotEmpty) {
      grouped.add(_HistoryHeader(l10n.callHistoryEarlier));
      grouped.addAll(earlier.map((c) => _HistoryItem(c)));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).callHistory)),
      body: LayoutBuilder(
        builder: (context, constraints) => Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: DsBreakpoints.contentMaxWidth(constraints.maxWidth),
            ),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: DsColors.error, fontSize: 14),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadInitial,
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_calls.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 180),
            const Icon(Icons.call_outlined, size: 64, color: DsColors.ink500),
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.callHistoryEmptyTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.callHistoryEmptyDesc,
                style: const TextStyle(color: DsColors.ink500),
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _groupCalls(_calls, l10n);
    final itemCount = grouped.length + (_isLoadingMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        key: const Key('call_history_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= grouped.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = grouped[index];
          if (item is _HistoryHeader) {
            return Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 8),
              child: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DsColors.ink500,
                ),
              ),
            );
          }

          return _CallTile(call: (item as _HistoryItem).call);
        },
      ),
    );
  }
}

class _HistoryHeader {
  const _HistoryHeader(this.label);

  final String label;
}

class _HistoryItem {
  const _HistoryItem(this.call);

  final Call call;
}

class _CallTile extends StatelessWidget {
  const _CallTile({required this.call});

  final Call call;

  bool get _isMissed =>
      call.status == CallStatus.missed ||
      call.endReason == CallEndReason.missed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title =
        call.receiverName ?? call.callerName ?? l10n.callUnknownName;
    final subtitleParts = <String>[
      _isMissed ? l10n.callHistoryStatusMissed : _statusLabel(call, l10n),
      if (call.duration != null && call.duration! > 0)
        l10n.callHistoryDuration(call.durationDisplay),
    ];

    return ListTile(
      key: Key('call_history_tile_${call.id}'),
      leading: CircleAvatar(
        backgroundColor: _isMissed
            ? DsColors.error.withValues(alpha: 0.12)
            : DsColors.primary.withValues(alpha: 0.12),
        child: Icon(
          call.type == CallType.video ? Icons.videocam : Icons.call,
          color: _isMissed ? DsColors.error : DsColors.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _isMissed ? DsColors.error : null,
        ),
      ),
      subtitle: Text(
        subtitleParts.join(' • '),
        key: Key('call_history_status_${call.id}'),
        style: TextStyle(color: _isMissed ? DsColors.error : DsColors.ink500),
      ),
      trailing: Text(
        _timeAgo(call.createdAt),
        style: const TextStyle(
          fontSize: 12,
          color: DsColors.ink500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _statusLabel(Call call, AppLocalizations l10n) {
    switch (call.status) {
      case CallStatus.initiating:
      case CallStatus.ringing:
        return l10n.callHistoryStatusRinging;
      case CallStatus.ongoing:
      case CallStatus.ended:
        return l10n.callHistoryStatusCompleted;
      case CallStatus.missed:
        return l10n.callHistoryStatusMissed;
      case CallStatus.declined:
        return l10n.callHistoryStatusDeclined;
      case CallStatus.failed:
        return l10n.callHistoryStatusFailed;
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
