import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tasks_flutter/model/task_model.dart';

class TaskCreateFormView extends StatefulWidget {
  const TaskCreateFormView({super.key});
  @override
  State<TaskCreateFormView> createState() => _TaskCreateFormViewState();
}

class _TaskCreateFormViewState extends State<TaskCreateFormView> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _image;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final img = await _picker.pickImage(source: ImageSource.camera);

    if (!mounted) return;
    setState(() => _image = img);
  }

  void _save() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) return;
    Navigator.of(context).pop(
      TaskModel(
        title: title,
        description: description,
        imagePath: _image?.path,
      ),
    );
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
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take photo'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final img = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (!mounted) return;
                    setState(() => _image = img);
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Upload image'),
                ),
                const SizedBox(width: 12),
                if (_image != null)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        // ignore: deprecated_member_use
                        File(_image!.path),
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
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
