// Read projections of EVENTO ONE v1. No legacy request, customer or payment state is created.
Map<String, dynamic> readObject(Object? value) {
  if (value is! Map<String, dynamic>)
    throw const FormatException('Expected an object');
  return value;
}

String readString(Object? value) {
  if (value is! String || value.isEmpty)
    throw const FormatException('Expected nonempty text');
  return value;
}

String readUuid(Object? value) {
  final id = readString(value);
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(id)) {
    throw const FormatException('Expected an EVENTO ONE identifier');
  }
  return id.toLowerCase();
}

int readMinor(Object? value) {
  if (value is! int || value < 0)
    throw const FormatException('Expected integer minor units');
  return value;
}

String? readOptionalUuid(Object? value) =>
    value == null ? null : readUuid(value);
DateTime readTimestamp(Object? value) {
  final text = readString(value);
  final time = DateTime.tryParse(text);
  if (time == null || !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(text)) {
    throw const FormatException('Expected an offset timestamp');
  }
  return time.toUtc();
}

String readDate(Object? value) {
  final text = readString(value);
  final date = DateTime.tryParse(text);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
      date == null ||
      date.toIso8601String().substring(0, 10) != text) {
    throw const FormatException('Expected an ISO date');
  }
  return text;
}

String? readOptionalDate(Object? value) =>
    value == null ? null : readDate(value);
String readStatus(Object? value, Set<String> allowed) {
  final status = readString(value);
  if (!allowed.contains(status))
    throw const FormatException('Unsupported EVENTO ONE status');
  return status;
}

String readCurrency(Object? value) {
  final currency = readString(value);
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency))
    throw const FormatException('Invalid currency code');
  return currency;
}

class OneOrganization {
  OneOrganization.fromJson(Map<String, dynamic> row)
    : id = readUuid(row['id']),
      displayName = readString(row['displayName']),
      role = readStatus(row['role'], {
        'OWNER',
        'ADMIN',
        'MANAGER',
        'STAFF',
        'VIEWER',
      }),
      currencyCode = readCurrency(row['currencyCode']),
      locale = readStatus(row['locale'], {'en', 'ar'}),
      timezone = readString(row['timezone']);
  final String id, displayName, role, currencyCode, locale, timezone;
}

class OneContext {
  OneContext.fromJson(Map<String, dynamic> row)
    : actorId = readUuid(readObject(row['actor'])['id']),
      organizations = _organizations(row['organizations']);
  final String actorId;
  final List<OneOrganization> organizations;
  static List<OneOrganization> _organizations(Object? value) {
    if (value is! List)
      throw const FormatException('Expected organization list');
    return List<OneOrganization>.unmodifiable(
      value.map((row) => OneOrganization.fromJson(readObject(row))),
    );
  }
}

class OneBookingSummary {
  OneBookingSummary.fromJson(Map<String, dynamic> row)
    : id = readUuid(row['id']),
      organizationId = readUuid(row['organizationId']),
      customerId = readUuid(row['customerId']),
      serviceId = readUuid(row['serviceId']),
      scheduledStart = readTimestamp(row['scheduledStart']),
      scheduledEnd = readTimestamp(row['scheduledEnd']),
      status = readStatus(row['status'], {
        'PENDING',
        'CONFIRMED',
        'COMPLETED',
        'CANCELLED',
        'NO_SHOW',
      }) {
    if (!scheduledEnd.isAfter(scheduledStart))
      throw const FormatException('Invalid booking interval');
  }
  final String id, organizationId, customerId, serviceId, status;
  final DateTime scheduledStart, scheduledEnd;
}

class OneQuotationSummary {
  OneQuotationSummary.fromJson(Map<String, dynamic> row)
    : id = readUuid(row['id']),
      organizationId = readUuid(row['organizationId']),
      customerId = readUuid(row['customerId']),
      bookingId = readOptionalUuid(row['bookingId']),
      quoteNumber = readString(row['quoteNumber']),
      status = readStatus(row['status'], {
        'DRAFT',
        'SENT',
        'ACCEPTED',
        'REJECTED',
        'EXPIRED',
        'CANCELLED',
      }),
      currency = readCurrency(row['currency']),
      totalMinor = readMinor(row['totalMinor']),
      validUntil = readOptionalDate(row['validUntil']);
  final String id, organizationId, customerId, quoteNumber, status, currency;
  final String? bookingId, validUntil;
  final int totalMinor;
}

class OneInvoiceSummary {
  OneInvoiceSummary.fromJson(Map<String, dynamic> row)
    : id = readUuid(row['id']),
      organizationId = readUuid(row['organizationId']),
      customerId = readUuid(row['customerId']),
      quotationId = readOptionalUuid(row['quotationId']),
      invoiceNumber = readString(row['invoiceNumber']),
      status = readStatus(row['status'], {'DRAFT', 'ISSUED', 'VOID'}),
      currency = readCurrency(row['currency']),
      issueDate = readDate(row['issueDate']),
      dueDate = readOptionalDate(row['dueDate']),
      totalMinor = readMinor(row['totalMinor']),
      amountPaidMinor = readMinor(row['amountPaidMinor']),
      amountDueMinor = readMinor(row['amountDueMinor']) {
    if (amountPaidMinor + amountDueMinor != totalMinor ||
        (dueDate != null && dueDate!.compareTo(issueDate) < 0)) {
      throw const FormatException('Invalid authoritative invoice projection');
    }
  }
  final String id,
      organizationId,
      customerId,
      invoiceNumber,
      status,
      currency,
      issueDate;
  final String? quotationId, dueDate;
  final int totalMinor, amountPaidMinor, amountDueMinor;
}
