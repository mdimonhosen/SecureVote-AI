import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/localization_service.dart';
import '../data/bd_locations.dart';
import '../main.dart';

class VoterManagementScreen extends StatefulWidget {
  const VoterManagementScreen({super.key});

  @override
  State<VoterManagementScreen> createState() => _VoterManagementScreenState();
}

class _VoterManagementScreenState extends State<VoterManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedDivision;
  String? _selectedDistrict;
  String? _selectedUpazila;
  int _selectedRole = 0; // 0 for Voter, 1 for Admin

  bool _isLoading = false;

  Future<void> _pickCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      setState(() => _isLoading = true);
      File file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
      
      // Assume first row is header: full_name,voter_id,phone,division,district,upazila
      for (var i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < 6) continue;
        
        await SupabaseService.client.from('voters').upsert({
          'voter_id': row[1].toString(),
          'full_name': row[0].toString(),
          'phone_number': row[2].toString(),
          'division': row[3].toString(),
          'district': row[4].toString(),
          'upazila': row[5].toString(),
          'thana': row[5].toString(), // Thana often same as Upazila for simplified model
        });
      }
      
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CSV Imported Successfully")));
      }
    }
  }

  Future<void> _manualAdd() async {
    if (_nameController.text.isEmpty || _idController.text.isEmpty || _selectedUpazila == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
       return;
    }

     setState(() => _isLoading = true);
     try {
       await SupabaseService.client.from('voters').upsert({
          'voter_id': _idController.text,
          'full_name': _nameController.text,
          'phone_number': _phoneController.text,
          'division': _selectedDivision,
          'district': _selectedDistrict,
          'upazila': _selectedUpazila,
          'thana': _selectedUpazila,
          'user_type': _selectedRole,
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Voter Added Successfully")));
          _nameController.clear();
          _idController.clear();
          _phoneController.clear();
        }
     } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
     } finally {
       setState(() => _isLoading = false);
     }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Voter Management", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3C72),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCSVSection(),
                const SizedBox(height: 40),
                Text(
                  "Manual Voter Add",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildTextField(_nameController, "Full Name", Icons.person_outline),
                const SizedBox(height: 15),
                _buildTextField(_idController, "Voter ID", Icons.badge_outlined),
                const SizedBox(height: 15),
                _buildTextField(_phoneController, "Phone Number", Icons.phone_outlined),
                const SizedBox(height: 25),
                
                // Location Selection
                _buildDropdown("Division", BDLocations.divisions, _selectedDivision, (val) {
                  setState(() {
                    _selectedDivision = val;
                    _selectedDistrict = null;
                    _selectedUpazila = null;
                  });
                }),
                const SizedBox(height: 15),
                if (_selectedDivision != null)
                  _buildDropdown("District", BDLocations.getDistricts(_selectedDivision!), _selectedDistrict, (val) {
                    setState(() {
                      _selectedDistrict = val;
                      _selectedUpazila = null;
                    });
                  }),
                const SizedBox(height: 15),
                if (_selectedDistrict != null)
                  _buildDropdown("Upazila/Thana", BDLocations.getUpazilas(_selectedDivision!, _selectedDistrict!), _selectedUpazila, (val) {
                    setState(() {
                      _selectedUpazila = val;
                    });
                  }),
                const SizedBox(height: 15),
                _buildDropdown("User Role", ["Voter", "Admin"], _selectedRole == 0 ? "Voter" : "Admin", (val) {
                  setState(() {
                    _selectedRole = val == "Admin" ? 1 : 0;
                  });
                }),

                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _manualAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3C72),
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Register Voter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildCSVSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3C72).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E3C72).withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.upload_file_rounded, size: 50, color: Color(0xFF1E3C72)),
          const SizedBox(height: 15),
          Text(
            "Bulk Import via CSV",
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "Format: Name, VoterID, Phone, Division, District, Upazila",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _pickCSV,
            icon: const Icon(Icons.file_upload),
            label: const Text("Select CSV File"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1E3C72),
              side: const BorderSide(color: Color(0xFF1E3C72)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E3C72)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      initialValue: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }
}
