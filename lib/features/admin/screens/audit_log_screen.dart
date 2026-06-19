import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import '../data/audit_log_entry.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditLogEntry> _logs = const [];
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAuditLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit logs'),
        actions: [
          IconButton(
            tooltip: 'Refresh audit logs',
            onPressed: _isLoading ? null : _loadAuditLogs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAuditLogs,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Audit logs are read-only summaries returned by the backend. The mobile app does not create or modify audit records.',
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const _AuditStateMessage(
                icon: Icons.hourglass_empty,
                title: 'Loading audit logs',
                message: 'Fetching safe backend audit summaries.',
                showProgress: true,
              )
            else if (_errorMessage != null)
              _AuditStateMessage(
                icon: Icons.lock_outline,
                title: 'Audit logs unavailable',
                message: _errorMessage!,
              )
            else if (_logs.isEmpty)
              const _AuditStateMessage(
                icon: Icons.receipt_long_outlined,
                title: 'No audit logs returned',
                message: 'The backend returned an empty audit log list.',
              )
            else ...[
              Text(
                '${_logs.length} audit entries',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final log in _logs) _AuditLogCard(log: log),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await GamelanScope.of(context).fetchAuditLogs();
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<List<AuditLogEntry>>(:final value):
        setState(() {
          _logs = value;
          _isLoading = false;
        });
      case Failure<List<AuditLogEntry>>(:final message):
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
    }
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});

  final AuditLogEntry log;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: 'Audit event',
              child: const Icon(Icons.receipt_long_outlined),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Type: ${log.eventType}'),
                  Text('Actor: ${log.safeActorLabel}'),
                  Text('Target: ${log.targetLabel}'),
                  Text('Occurred: ${_formatDateTime(log.occurredAt)}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditStateMessage extends StatelessWidget {
  const _AuditStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            if (showProgress)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 40),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Not returned';
  }
  final local = value.toLocal();
  final date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
