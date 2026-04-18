import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/localization_service.dart';
import '../main.dart';
import 'home_screen.dart';

class CandidateSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> voter;
  const CandidateSelectionScreen({super.key, required this.voter});

  @override
  State<CandidateSelectionScreen> createState() => _CandidateSelectionScreenState();
}

class _CandidateSelectionScreenState extends State<CandidateSelectionScreen> {
  List<Map<String, dynamic>> _candidates = [];
  bool _isLoading = true;
  String? _selectedCandidateId;

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    // For demo, we use a fixed election ID or fetch the first active one
    // In a real app, this would come from the Home screen
    String electionId = "national-2026"; // Placeholder, would fetch from DB
    
    try {
      // Mock candidates if DB is empty for demo
      final results = await supabase.getCandidates(electionId);
      if (results.isEmpty) {
        _candidates = [
          {'id': 'c1', 'name': 'Sheikh Hasina', 'party': 'Awami League', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/e/e0/Sheikh_Hasina_%282023%29.jpg'},
          {'id': 'c2', 'name': 'Khaleda Zia', 'party': 'BNP', 'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d7/Begum_Khaleda_Zia.jpg/220px-Begum_Khaleda_Zia.jpg'},
          {'id': 'c3', 'name': 'GM Quader', 'party': 'Jatiya Party', 'image_url': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS_G9nBwBvQx1w_u9R7vR5A_B_z_Z_Z_Z_Z_A&usqp=CAU'},
        ];
      } else {
        _candidates = results;
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitVote() async {
    if (_selectedCandidateId == null) return;

    setState(() => _isLoading = true);
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    final loc = Provider.of<LanguageProvider>(context, listen: false).service;

    try {
      // In real DB, we'd use the real election ID
      await supabase.submitVote(widget.voter['voter_id'], _selectedCandidateId!, "national-2026");
      
      if (mounted) {
        _showSuccessDialog(loc);
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(LocalizationService loc) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('vote_success')),
        content: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen(voter: {
                  ...widget.voter,
                  'has_voted': true,
                })),
                (route) => false,
              );
            },
            child: Text(loc.translate('continue')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LanguageProvider>(context).service;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(loc.translate('candidates'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3C72),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = _candidates[index];
                      bool isSelected = _selectedCandidateId == candidate['id'];

                      return GestureDetector(
                        onTap: () => setState(() => _selectedCandidateId = candidate['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1E3C72) : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                  ? const Color(0xFF1E3C72).withOpacity(0.1)
                                  : Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  candidate['image_url'] ?? 'https://via.placeholder.com/150',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 80, height: 80, color: Colors.grey.shade200,
                                    child: const Icon(Icons.person, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      candidate['name'],
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      candidate['party'] ?? 'Independent',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Color(0xFF1E3C72), size: 30),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: _selectedCandidateId == null ? null : _submitVote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3C72),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      loc.translate('vote'),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
