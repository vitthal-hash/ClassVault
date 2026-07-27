import 'package:flutter/material.dart';

import '../core/models/subject.dart';
import '../core/services/subject_service.dart';

/// Lets the person set the short code used for Lecture Upload IDs in
/// Phase 7 (e.g. "DBMS" -> DBMS_T_005). Optional — subjects created from
/// the timetable have no code until this is set.
class EditSubjectCodeSheet extends StatefulWidget {
  const EditSubjectCodeSheet({super.key, required this.subject});

  final Subject subject;

  static Future<void> show(BuildContext context, Subject subject) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditSubjectCodeSheet(subject: subject),
    );
  }

  @override
  State<EditSubjectCodeSheet> createState() => _EditSubjectCodeSheetState();
}

class _EditSubjectCodeSheetState extends State<EditSubjectCodeSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.subject.code ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await SubjectService.instance.updateCode(widget.subject, _controller.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Subject Code',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Used to generate lecture IDs later, e.g. DBMS_T_005. '
            'Leave blank to clear it.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Code',
              hintText: 'e.g. DBMS',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
