import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/localization_service.dart';

import '../main.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'face_capture_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>? voter;
  const HomeScreen({super.key, this.voter});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _HomeDashboard(voter: widget.voter),
      const ResultsScreen(),
      const _ProfileTab(), // Simplified profile in home for now
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LanguageProvider>(context).service;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1E3C72),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(),
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: loc.translate('home')),
            BottomNavigationBarItem(icon: const Icon(Icons.bar_chart_rounded), label: loc.translate('results')),
            BottomNavigationBarItem(icon: const Icon(Icons.person_rounded), label: loc.translate('profile')),
            BottomNavigationBarItem(icon: const Icon(Icons.settings_rounded), label: loc.translate('settings')),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  final Map<String, dynamic>? voter;
  const _HomeDashboard({this.voter});

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LanguageProvider>(context).service;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, loc),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Active Elections",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                _buildElectionCard(context, loc),
                const SizedBox(height: 25),
                Text(
                  "Instructions",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildInstructionItem(Icons.face_retouching_natural, "Keep your face steady and aligned."),
                _buildInstructionItem(Icons.light_mode_rounded, "Ensure you are in a well-lit area."),
                _buildInstructionItem(Icons.security_rounded, "One person, one vote. Fraud detection is active."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LocalizationService loc) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3C72),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello, ${voter?['full_name'] ?? 'Guest'}",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                voter != null ? "Voter ID: ${voter!['voter_id']}" : "Welcome to the Digital Ballot",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionCard(BuildContext context, LocalizationService loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "LIVE",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "National General Election 2026",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Ends in: 04d 12h 30m",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              if (voter == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please login to cast your vote.")),
                );
                return;
              }
              if (voter!['has_voted'] == true) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.translate('has_voted'))),
                );
                return;
              }

              // Request Camera Permission Just-in-Time
              var status = await Permission.camera.status;
              if (status.isDenied) {
                status = await Permission.camera.request();
              }

              if (status.isGranted) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FaceCaptureScreen(voter: voter!)),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Camera permission is required for face verification.")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3C72),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              loc.translate('start_voting'),
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1E3C72)),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Profile Tab - Coming Soon"));
  }
}
