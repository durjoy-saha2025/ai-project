import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart' show store;
import 'models.dart';

Color statusColor(String s) {
  switch (s) {
    case 'Approved':
    case 'Collected':
    case 'Dispatched':
      return const Color(0xFF2ECC8F);
    case 'Rejected':
      return const Color(0xFFFF5C7A);
    case 'Documents requested':
    case 'Interview scheduled':
      return const Color(0xFFFFB547);
    case 'In process':
    case 'Received':
      return const Color(0xFF3D8BFF);
    default:
      return const Color(0xFF8E6BFF);
  }
}

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

// ───────────────────────── Home ─────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cases = store.cases;
        final active = cases.where((c) => !c.isFinal).length;
        final approved = cases.where((c) => c.status == 'Approved' || c.status == 'Collected').length;
        final attention = cases.where((c) => c.needsAttention).length;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Visa Tracker', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const EditScreen())),
            icon: const Icon(Icons.add),
            label: const Text('Add visa'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Row(children: [
                _stat(context, 'Active', active, const Color(0xFF3D8BFF)),
                const SizedBox(width: 10),
                _stat(context, 'Need action', attention, const Color(0xFFFFB547)),
                const SizedBox(width: 10),
                _stat(context, 'Approved', approved, const Color(0xFF2ECC8F)),
              ]),
              const SizedBox(height: 20),
              if (cases.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Column(children: [
                    Icon(Icons.flight_takeoff, size: 64, color: Colors.white38),
                    SizedBox(height: 12),
                    Text('No visa applications yet', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 6),
                    Text('Tap "Add visa" to start tracking.',
                        style: TextStyle(color: Colors.white54)),
                  ]),
                ),
              for (final c in cases) _caseCard(context, c),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(BuildContext context, String label, int n, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$n', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _caseCard(BuildContext context, VisaCase c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => DetailScreen(id: c.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${c.country} · ${c.visaType}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              StatusChip(c.status),
            ]),
            const SizedBox(height: 6),
            Text(c.applicant, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.tag, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(c.reference,
                      style: const TextStyle(color: Colors.white54, fontSize: 12))),
              const Icon(Icons.update, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                c.lastChecked == null ? 'Not checked' : 'Updated ${ago(c.lastChecked!)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── Add / Edit ─────────────────────────

class EditScreen extends StatefulWidget {
  final VisaCase? existing;
  const EditScreen({super.key, this.existing});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _applicant;
  late final TextEditingController _country;
  late final TextEditingController _reference;
  late final TextEditingController _url;
  late String _type;
  late String _status;
  late DateTime _submitted;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _applicant = TextEditingController(text: e?.applicant ?? '');
    _country = TextEditingController(text: e?.country ?? '');
    _reference = TextEditingController(text: e?.reference ?? '');
    _url = TextEditingController(text: e?.portalUrl ?? '');
    _type = e?.visaType ?? visaTypes.first;
    _status = 'Submitted';
    _submitted = e?.submittedOn ?? DateTime.now();
  }

  @override
  void dispose() {
    _applicant.dispose();
    _country.dispose();
    _reference.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _submitted,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _submitted = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final e = widget.existing;
    var url = _url.text.trim();
    if (url.isNotEmpty && !url.startsWith('http')) url = 'https://$url';
    if (e == null) {
      await store.upsert(VisaCase(
        id: VisaCase.newId(),
        applicant: _applicant.text.trim(),
        country: _country.text.trim(),
        visaType: _type,
        reference: _reference.text.trim(),
        portalUrl: url,
        submittedOn: _submitted,
        history: [StatusEvent(at: DateTime.now(), status: _status, note: 'Application added')],
      ));
    } else {
      e.applicant = _applicant.text.trim();
      e.country = _country.text.trim();
      e.visaType = _type;
      e.reference = _reference.text.trim();
      e.portalUrl = url;
      e.submittedOn = _submitted;
      await store.upsert(e);
    }
    if (mounted) Navigator.pop(context);
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Add visa application' : 'Edit application')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
                controller: _applicant,
                decoration: const InputDecoration(labelText: 'Applicant name'),
                validator: _required),
            const SizedBox(height: 12),
            TextFormField(
                controller: _country,
                decoration: const InputDecoration(labelText: 'Country (e.g. India)'),
                validator: _required),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Visa type'),
              items: [for (final t in visaTypes) DropdownMenuItem(value: t, child: Text(t))],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _reference,
                decoration: const InputDecoration(labelText: 'Application / reference number'),
                validator: _required),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'Official status-check website (optional)',
                  helperText: 'Paste the official portal link to open it in one tap'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Submission date'),
                child: Text(fmtDate(_submitted)),
              ),
            ),
            if (isNew) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Current status'),
                items: [for (final s in statuses) DropdownMenuItem(value: s, child: Text(s))],
                onChanged: (v) => setState(() => _status = v ?? _status),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(isNew ? 'Save' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Detail ─────────────────────────

class DetailScreen extends StatelessWidget {
  final String id;
  const DetailScreen({super.key, required this.id});

  Future<void> _openPortal(BuildContext context, VisaCase c) async {
    if (c.portalUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No portal link saved. Tap edit to add one.')));
      return;
    }
    final ok = await launchUrl(Uri.parse(c.portalUrl), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }

  void _updateSheet(BuildContext context, VisaCase c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151B30),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => UpdateSheet(caseId: c.id, current: c.status),
    );
  }

  Future<void> _delete(BuildContext context, VisaCase c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this application?'),
        content: const Text('Its status history will be removed from this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await store.remove(c.id);
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = store.byId(id);
        if (c == null) return const Scaffold(body: SizedBox());
        final events = c.history.reversed.toList();
        return Scaffold(
          appBar: AppBar(
            title: Text(c.country),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => EditScreen(existing: c))),
              ),
              IconButton(
                  icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, c)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    StatusChip(c.status),
                    const SizedBox(height: 12),
                    _row('Applicant', c.applicant),
                    _row('Visa type', c.visaType),
                    _row('Reference', c.reference),
                    _row('Submitted', fmtDate(c.submittedOn)),
                    _row('Last update',
                        c.lastChecked == null ? '-' : fmtDateTime(c.lastChecked!)),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openPortal(context, c),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open official status page'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateSheet(context, c),
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Update status'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await store.addEvent(
                          c.id,
                          StatusEvent(
                              at: DateTime.now(),
                              status: c.status,
                              note: 'Checked, no change',
                              changed: false));
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Checked, no change'),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              const Text('History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final e in events)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(e.changed ? Icons.circle : Icons.circle_outlined,
                      size: 14, color: statusColor(e.status)),
                  title: Text(e.status),
                  subtitle: Text(
                      e.note.isEmpty ? fmtDateTime(e.at) : '${fmtDateTime(e.at)}\n${e.note}'),
                  isThreeLine: e.note.isNotEmpty,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 100, child: Text(k, style: const TextStyle(color: Colors.white54))),
          Expanded(child: Text(v)),
        ]),
      );
}

class UpdateSheet extends StatefulWidget {
  final String caseId;
  final String current;
  const UpdateSheet({super.key, required this.caseId, required this.current});

  @override
  State<UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<UpdateSheet> {
  late String _status = widget.current;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Update status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _status,
          decoration: const InputDecoration(labelText: 'New status'),
          items: [for (final s in statuses) DropdownMenuItem(value: s, child: Text(s))],
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              await store.addEvent(
                widget.caseId,
                StatusEvent(
                  at: DateTime.now(),
                  status: _status,
                  note: _note.text.trim(),
                  changed: _status != widget.current,
                ),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ),
      ]),
    );
  }
}
