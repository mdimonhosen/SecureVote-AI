import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final loc = languageProvider.service;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(loc.translate('settings'), style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E3C72),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("Appearance"),
          _buildSettingItem(
            Icons.language_rounded,
            loc.translate('select_language'),
            trailing: DropdownButton<String>(
              value: languageProvider.currentLanguage,
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'bn', child: Text("বাংলা")),
                DropdownMenuItem(value: 'en', child: Text("English")),
              ],
              onChanged: (val) {
                if (val != null) languageProvider.setLanguage(val);
              },
            ),
          ),
          _buildSettingItem(Icons.dark_mode_outlined, "Dark Mode", trailing: Switch(value: false, onChanged: (v) {})),
          
          const SizedBox(height: 30),
          _buildSectionHeader("Account"),
          _buildSettingItem(Icons.lock_outline_rounded, "Privacy Policy", onTap: () {}),
          _buildSettingItem(Icons.help_outline_rounded, "Help & Support", onTap: () {}),
          _buildSettingItem(
            Icons.logout_rounded,
            loc.translate('logout'),
            textColor: Colors.red,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          
          const SizedBox(height: 50),
          Center(
            child: Text(
              "App Version 1.0.0",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {Widget? trailing, VoidCallback? onTap, Color? textColor}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: textColor ?? const Color(0xFF1E3C72)),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontSize: 16, color: textColor ?? Colors.black87, fontWeight: FontWeight.w500),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}
