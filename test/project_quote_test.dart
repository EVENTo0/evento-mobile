import 'package:flutter_test/flutter_test.dart';
import 'package:evento_mobile/domain/project_quote.dart';

void main() {
  test('parses EVENTO quotation money and validity', () {
    final quote = ProjectQuoteRecord.fromJson(<String, dynamic>{
      'id': 'quote-1',
      'quote_code': 'EVQ-260811-ABC123',
      'request_id': 'request-1',
      'status': 'sent',
      'total_aed': '945.00',
      'valid_until': '2026-08-18T12:00:00Z',
    });

    expect(quote.id, 'quote-1');
    expect(quote.status, 'sent');
    expect(quote.totalAed, 945.0);
    expect(quote.validUntil, DateTime.parse('2026-08-18T12:00:00Z'));
  });
}
