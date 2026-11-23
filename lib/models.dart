import 'dart:math';

const statuses = <String>[
  'Submitted',
  'Received',
  'In process',
  'Documents requested',
  'Interview scheduled',
  'Approved',
  'Rejected',
  'Dispatched',
  'Collected',
];

const visaTypes = <String>[
  'Tourist',
  'Business',
  'Medical',
  'Student',
  'Work',
  'Transit',
  'Other',
];

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String fmtDateTime(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${fmtDate(d)}, $h:$m';
}

String ago(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}

class StatusEvent {
  final DateTime at;
  final String status;
  final String note;
  final bool changed;

  StatusEvent({required this.at, required this.status, this.note = '', this.changed = true});

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'status': status,
        'note': note,
        'changed': changed,
      };

  factory StatusEvent.fromJson(Map<String, dynamic> j) => StatusEvent(
        at: DateTime.parse(j['at'] as String),
        status: j['status'] as String,
        note: (j['note'] ?? '') as String,
        changed: (j['changed'] ?? true) as bool,
      );
}

class VisaCase {
  final String id;
  String applicant;
  String country;
  String visaType;
  String reference;
  String portalUrl;
  DateTime submittedOn;
  List<StatusEvent> history;

  VisaCase({
    required this.id,
    required this.applicant,
    required this.country,
    required this.visaType,
    required this.reference,
    required this.portalUrl,
    required this.submittedOn,
    required this.history,
  });

  static String newId() => '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(9999)}';

  String get status => history.isEmpty ? 'Submitted' : history.last.status;
  DateTime? get lastChecked => history.isEmpty ? null : history.last.at;

  bool get isFinal => const ['Approved', 'Rejected', 'Collected'].contains(status);
  bool get needsAttention => const ['Documents requested', 'Interview scheduled'].contains(status);

  Map<String, dynamic> toJson() => {
        'id': id,
        'applicant': applicant,
        'country': country,
        'visaType': visaType,
        'reference': reference,
        'portalUrl': portalUrl,
        'submittedOn': submittedOn.toIso8601String(),
        'history': history.map((e) => e.toJson()).toList(),
      };

  factory VisaCase.fromJson(Map<String, dynamic> j) => VisaCase(
        id: j['id'] as String,
        applicant: j['applicant'] as String,
        country: j['country'] as String,
        visaType: j['visaType'] as String,
        reference: j['reference'] as String,
        portalUrl: (j['portalUrl'] ?? '') as String,
        submittedOn: DateTime.parse(j['submittedOn'] as String),
        history: ((j['history'] ?? []) as List)
            .map((e) => StatusEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
