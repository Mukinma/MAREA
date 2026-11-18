enum ReportTarget {
  account('Cuenta'),
  post('Publicación'),
  mission('Misión'),
  showcase('Ficha');

  const ReportTarget(this.label);
  final String label;
}

class ReportReceipt {
  const ReportReceipt({
    required this.id,
    required this.target,
    required this.createdAt,
    required this.reviewed,
    this.targetUnavailable = false,
  });

  final String id;
  final ReportTarget target;
  final DateTime createdAt;
  final bool reviewed, targetUnavailable;

  factory ReportReceipt.fromJson(Map<String, dynamic> json) => ReportReceipt(
    id: json['id'] as String,
    target: ReportTarget.values.byName(json['kind'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    reviewed: json['state'] == 'resolved',
    targetUnavailable: json['target_unavailable'] == true,
  );
}

class ReportedAccount {
  const ReportedAccount({
    required this.id,
    required this.reason,
    required this.reviewed,
    this.targetId,
  });

  final String id, reason;
  final bool reviewed;
  final String? targetId;

  factory ReportedAccount.fromJson(Map<String, dynamic> json) =>
      ReportedAccount(
        id: json['id'] as String,
        targetId: json['target_profile_id'] as String?,
        reason: json['reason'] as String,
        reviewed: json['state'] == 'resolved',
      );
}
