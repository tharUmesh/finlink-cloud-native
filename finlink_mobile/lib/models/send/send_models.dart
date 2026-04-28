class SendRequest {
  const SendRequest({
    required this.receiverAddress,
    required this.amount,
    this.note,
    this.idempotencyKey,
  });

  final String receiverAddress;
  final double amount;
  final String? note;
  final String? idempotencyKey;
}

class SendResult {
  const SendResult({
    required this.transactionId,
    this.raw = const {},
  });

  final String transactionId;
  final Map<String, dynamic> raw;
}
