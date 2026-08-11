import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/project_quote.dart';
import '../../domain/project_request.dart';
import '../../domain/project_workflow.dart';
import '../../domain/request_live_detail.dart';

abstract interface class ProjectRequestRepository {
  Future<ProjectRequestRecord> create({
    required String type,
    required String title,
    required String details,
    String? sourceProjectId,
  });

  Future<List<ProjectRequestRecord>> listMine();
  Future<ProjectRequestRecord?> getById(String id);
  Future<RequestAnalysisRecord?> getAnalysis(String requestId);
  Future<List<RequestEventRecord>> getEvents(String requestId);
  Future<ProjectWorkflowRecord?> getWorkflow(String requestId);
  Future<ProjectQuoteRecord?> getQuote(String requestId);
  Future<void> requestAnalysis(String requestId);
  Future<void> startWorkflow(String requestId);
  Future<void> approveScope(String requestId);
  Future<void> acceptQuote(String quoteId);
}

class BackendNotConfiguredException implements Exception {
  const BackendNotConfiguredException();

  @override
  String toString() => 'EVENTO backend is not configured.';
}

class AuthenticationRequiredException implements Exception {
  const AuthenticationRequiredException();

  @override
  String toString() => 'Sign in before creating or reading project requests.';
}

class SupabaseProjectRequestRepository implements ProjectRequestRepository {
  SupabaseProjectRequestRepository(this.client);

  final SupabaseClient client;

  static const String _columns =
      'id,request_code,project_type,title,details,status,created_at,source_project_id';

  User get _user {
    final User? user = client.auth.currentUser;
    if (user == null) throw const AuthenticationRequiredException();
    return user;
  }

  @override
  Future<ProjectRequestRecord> create({
    required String type,
    required String title,
    required String details,
    String? sourceProjectId,
  }) async {
    final User user = _user;
    final Map<String, dynamic> row = await client
        .from('project_requests')
        .insert(<String, dynamic>{
          'user_id': user.id,
          'project_type': type,
          'title': title.trim(),
          'details': details.trim(),
          'source_project_id': sourceProjectId,
        })
        .select(_columns)
        .single();
    return ProjectRequestRecord.fromJson(row);
  }

  @override
  Future<List<ProjectRequestRecord>> listMine() async {
    _user;
    final List<dynamic> rows = await client
        .from('project_requests')
        .select(_columns)
        .order('created_at', ascending: false)
        .limit(50);
    return rows
        .cast<Map<String, dynamic>>()
        .map(ProjectRequestRecord.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ProjectRequestRecord?> getById(String id) async {
    _user;
    final Map<String, dynamic>? row = await client
        .from('project_requests')
        .select(_columns)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : ProjectRequestRecord.fromJson(row);
  }

  @override
  Future<RequestAnalysisRecord?> getAnalysis(String requestId) async {
    _user;
    final Map<String, dynamic>? row = await client
        .from('request_analyses')
        .select(
          'complexity,summary,summary_ar,proposed_scope,proposed_scope_ar,risks,risks_ar,engine_version,updated_at',
        )
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : RequestAnalysisRecord.fromJson(row);
  }

  @override
  Future<List<RequestEventRecord>> getEvents(String requestId) async {
    _user;
    final List<dynamic> rows = await client
        .from('project_request_events')
        .select('status,note,note_ar,created_at')
        .eq('request_id', requestId)
        .order('created_at');
    return rows
        .cast<Map<String, dynamic>>()
        .map(RequestEventRecord.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ProjectWorkflowRecord?> getWorkflow(String requestId) async {
    _user;
    final Map<String, dynamic>? row = await client
        .from('project_workflows')
        .select(
          'request_id,current_stage,progress_percent,estimated_price_aed,scope_approved_at,updated_at',
        )
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : ProjectWorkflowRecord.fromJson(row);
  }

  @override
  Future<ProjectQuoteRecord?> getQuote(String requestId) async {
    _user;
    final Map<String, dynamic>? row = await client
        .from('project_quotes')
        .select('id,quote_code,request_id,status,total_aed,valid_until')
        .eq('request_id', requestId)
        .maybeSingle();
    return row == null ? null : ProjectQuoteRecord.fromJson(row);
  }

  @override
  Future<void> requestAnalysis(String requestId) async {
    _user;
    await client.functions.invoke(
      'analyze-request',
      body: <String, dynamic>{'request_id': requestId},
    );
  }

  Future<void> _transitionWorkflow(String requestId, String action) async {
    _user;
    await client.functions.invoke(
      'workflow-transition',
      body: <String, dynamic>{
        'request_id': requestId,
        'action': action,
      },
    );
  }

  @override
  Future<void> startWorkflow(String requestId) =>
      _transitionWorkflow(requestId, 'start');

  @override
  Future<void> approveScope(String requestId) =>
      _transitionWorkflow(requestId, 'approve');

  @override
  Future<void> acceptQuote(String quoteId) async {
    _user;
    await client.functions.invoke(
      'quote-action',
      body: <String, dynamic>{
        'action': 'accept',
        'quote_id': quoteId,
      },
    );
  }
}
