import 'dart:async';

import 'package:evento_mobile/data/one/one_member_gateway.dart';
import 'package:evento_mobile/domain/one/read_models.dart';

const orgA = '11111111-1111-4111-8111-111111111111';
const orgB = '22222222-2222-4222-8222-222222222222';
const actor = '33333333-3333-4333-8333-333333333333';
const record = '44444444-4444-4444-8444-444444444444';
const customer = '55555555-5555-4555-8555-555555555555';
const service = '66666666-6666-4666-8666-666666666666';

Map<String, dynamic> contextBody({
  List<String> organizations = const [orgA, orgB],
}) => {
  'apiVersion': '1',
  'actor': {'id': actor},
  'organizations': organizations
      .map(
        (id) => {
          'id': id,
          'displayName': id == orgA
              ? 'Synthetic Studio A'
              : 'Synthetic Studio B',
          'role': id == orgA ? 'VIEWER' : 'MANAGER',
          'currencyCode': 'AED',
          'locale': 'ar',
          'timezone': 'Asia/Dubai',
        },
      )
      .toList(),
};

Map<String, dynamic> booking(String org) => {
  'id': record,
  'organizationId': org,
  'customerId': customer,
  'serviceId': service,
  'scheduledStart': '2026-12-01T10:00:00Z',
  'scheduledEnd': '2026-12-01T11:00:00Z',
  'status': 'CONFIRMED',
};
Map<String, dynamic> quotation(String org) => {
  'id': record,
  'organizationId': org,
  'customerId': customer,
  'quoteNumber': org == orgA ? 'SYNTHETIC-Q-A' : 'SYNTHETIC-Q-B',
  'status': 'ACCEPTED',
  'currency': 'AED',
  'totalMinor': 10500,
  'validUntil': '2026-12-31',
};
Map<String, dynamic> invoice(String org) => {
  'id': record,
  'organizationId': org,
  'customerId': customer,
  'invoiceNumber': org == orgA ? 'SYNTHETIC-INV-A' : 'SYNTHETIC-INV-B',
  'status': 'ISSUED',
  'currency': 'AED',
  'issueDate': '2026-09-28',
  'dueDate': '2026-12-31',
  'totalMinor': 10500,
  'amountPaidMinor': 5000,
  'amountDueMinor': 5500,
};
Map<String, dynamic> collection(String resource, String org) => {
  'apiVersion': '1',
  'organizationId': org,
  'resource': resource,
  'limit': 50,
  'scope': 'bounded_snapshot',
  'items': [
    switch (resource) {
      'bookings' => booking(org),
      'quotations' => quotation(org),
      _ => invoice(org),
    },
  ],
};
OneMemberSnapshot snapshot(String org) => OneMemberSnapshot(
  bookings: [OneBookingSummary.fromJson(booking(org))],
  quotations: [OneQuotationSummary.fromJson(quotation(org))],
  invoices: [OneInvoiceSummary.fromJson(invoice(org))],
);

/// Test fixture only. It does not claim Supabase Auth/RLS evidence.
class FakeOneGateway implements OneMemberGateway {
  final events = StreamController<void>.broadcast(sync: true);
  int signIns = 0, signOuts = 0, contexts = 0;
  final reads = <String>[];
  OneContext resultContext = OneContext.fromJson(contextBody());
  Future<OneMemberSnapshot> Function(String)? onRead;
  Object? loginError;
  @override
  Stream<void> get invalidations => events.stream;
  @override
  Future<void> signIn(String email, String password) async {
    signIns++;
    if (loginError != null) throw loginError!;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
  }

  @override
  Future<OneContext> context() async {
    contexts++;
    return resultContext;
  }

  @override
  Future<OneMemberSnapshot> read(String organizationId) {
    reads.add(organizationId);
    return onRead?.call(organizationId) ??
        Future.value(snapshot(organizationId));
  }

  @override
  Future<void> close() async {
    await events.close();
  }
}
