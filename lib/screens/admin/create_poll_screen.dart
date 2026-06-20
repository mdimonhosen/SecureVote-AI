import 'dart:io';
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';

// Helper class to manage Name, Description, AND Image for each candidate
class CandidateField {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController descCtrl = TextEditingController();
  XFile? imageFile; // CHANGED: Using XFile instead of File so it works on Web!

  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
  }
}

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker(); 
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _accessCodeController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _isPrivate = false;

  final List<CandidateField> _candidates = [
    CandidateField(),
    CandidateField(),
  ];

  void _addCandidateField() {
    setState(() {
      _candidates.add(CandidateField());
    });
  }

  void _removeCandidateField(int index) {
    if (_candidates.length > 2) {
      setState(() {
        _candidates[index].dispose();
        _candidates.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A poll must have at least 2 candidates.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
      );
    }
  }

  // Function to pick an image
  Future<void> _pickImage(int index) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _candidates[index].imageFile = pickedFile; // Store as XFile
      });
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _submitPoll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select start and end dates.'), backgroundColor: AppColors.error));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date must be after start date.'), backgroundColor: AppColors.error));
      return;
    }
    if (_isPrivate && _accessCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide an access code for the private poll.'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;

      // 1. Insert the Poll
      final pollResponse = await _supabase.from('polls').insert({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'start_date': _startDate!.toIso8601String(),
        'end_date': _endDate!.toIso8601String(),
        'is_private': _isPrivate,
        'access_code_hash': _isPrivate ? _accessCodeController.text.trim() : null,
        'created_by': userId,
      }).select('id').single();

      final String newPollId = pollResponse['id'];

      // 2. Prepare and Upload Candidates
      final List<Map<String, dynamic>> candidatesToInsert = [];
      
      for (var candidate in _candidates) {
        if (candidate.nameCtrl.text.trim().isNotEmpty) {
          String? uploadedImageUrl;

          // WEB & MOBILE FIX: Read file as bytes so the browser doesn't crash
          if (candidate.imageFile != null) {
            final fileExt = candidate.imageFile!.name.split('.').last;
            final fileName = 'candidate_${DateTime.now().millisecondsSinceEpoch}_${candidate.nameCtrl.text.trim().replaceAll(" ", "_")}.$fileExt';
            
            // Convert to bytes for cross-platform safety
            final imageBytes = await candidate.imageFile!.readAsBytes();
            
            await _supabase.storage.from('candidate_images').uploadBinary(
              fileName, 
              imageBytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );
            
            uploadedImageUrl = _supabase.storage.from('candidate_images').getPublicUrl(fileName);
          }

          candidatesToInsert.add({
            'poll_id': newPollId,
            'name': candidate.nameCtrl.text.trim(),
            'description': candidate.descCtrl.text.trim(),
            'image_url': uploadedImageUrl,
          });
        }
      }

      // 3. Insert all Candidates
      if (candidatesToInsert.isNotEmpty) {
        await _supabase.from('candidates').insert(candidatesToInsert);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Poll created successfully!'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _accessCodeController.dispose();
    for (var candidate in _candidates) {
      candidate.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Poll', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poll Details
              const Text('Poll Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(hintText: 'e.g., General Election 2026', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(hintText: 'Describe what this vote is for...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Private Poll Toggle
              CheckboxListTile(
                title: const Text('Private Poll (requires access code)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                value: _isPrivate,
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? value) {
                  setState(() {
                    _isPrivate = value ?? false;
                  });
                },
              ),
              
              if (_isPrivate) ...[
                const SizedBox(height: 8),
                const Text('Access Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _accessCodeController,
                  decoration: InputDecoration(
                    hintText: 'Enter Access Code (e.g., 111)', 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => _isPrivate && val!.isEmpty ? 'Required for private polls' : null,
                ),
              ],
              const SizedBox(height: 24),

              // Date Pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(true),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_startDate == null ? 'Start Date' : '${_startDate!.day}/${_startDate!.month} ${_startDate!.hour}:${_startDate!.minute.toString().padLeft(2,'0')}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDateTime(false),
                      icon: const Icon(Icons.event_busy, size: 18),
                      label: Text(_endDate == null ? 'End Date' : '${_endDate!.day}/${_endDate!.month} ${_endDate!.hour}:${_endDate!.minute.toString().padLeft(2,'0')}'),
                    ),
                  ),
                ],
              ),
              const Divider(height: 40, thickness: 2),

              // Dynamic Candidates List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Candidates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  TextButton.icon(
                    onPressed: _addCandidateField,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  )
                ],
              ),
              const SizedBox(height: 10),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _candidates.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Number Circle
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                        ),
                        const SizedBox(width: 12),
                        
                        // Image Picker Box
                        GestureDetector(
                          onTap: () => _pickImage(index),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade400),
                              // WEB FIX: Displays the image dynamically whether on Web or Mobile
                              image: _candidates[index].imageFile != null
                                  ? DecorationImage(
                                      image: kIsWeb 
                                          ? NetworkImage(_candidates[index].imageFile!.path)
                                          : FileImage(File(_candidates[index].imageFile!.path)) as ImageProvider,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _candidates[index].imageFile == null
                                ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 24)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Text Fields (Name & Description)
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _candidates[index].nameCtrl,
                                decoration: InputDecoration(hintText: 'Candidate Name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                validator: (val) => val!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _candidates[index].descCtrl,
                                decoration: InputDecoration(hintText: 'Candidate Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                              ),
                            ],
                          ),
                        ),
                        
                        // Delete Button
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                          onPressed: () => _removeCandidateField(index),
                        )
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
              CustomButton(
                text: 'Launch Poll',
                isLoading: _isLoading,
                onPressed: _submitPoll,
              ),
            ],
          ),
        ),
      ),
    );
  }
}