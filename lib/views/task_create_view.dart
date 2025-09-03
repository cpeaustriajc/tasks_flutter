import 'package:flutter/material.dart';

class TaskCreateResult {
  final String title;
  final String description;
  TaskCreateResult({required this.title, required this.description});
}

class TaskCreateFormView extends StatefulWidget {
  const TaskCreateFormView({super.key});
  @override
  State<TaskCreateFormView> createState() => _TaskCreateFormViewState();
}

class _TaskCreateFormViewState extends State<TaskCreateFormView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) return;
    Navigator.of(
      context,
    ).pop(TaskCreateResult(title: title, description: description));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
