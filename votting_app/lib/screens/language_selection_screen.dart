import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'login_screen.dart';



class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final loc = languageProvider.service;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Hero(
                tag: 'logo',
                child: Icon(
                  Icons.language_rounded,
                  size: 80,
                  color: Color(0xFF1E3C72),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                loc.translate('select_language'),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please choose your preferred language\nঅনুগ্রহ করে আপনার পছন্দের ভাষা নির্বাচন করুন",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 50),
              _buildLangButton(
                context,
                "বাংলা (Bangla)",
                "bn",
                languageProvider,
              ),
              const SizedBox(height: 15),
              _buildLangButton(
                context,
                "English",
                "en",
                languageProvider,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3C72),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  loc.translate('continue'),
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(BuildContext context, String text, String code, LanguageProvider langProv) {
    final loc = langProv.service;
    bool isSelected = false; // We will check actual state if needed
    
    return FutureBuilder<String>(
      future: loc.getLanguage(),
      builder: (context, snapshot) {
        bool active = snapshot.data == code;
        return InkWell(
          onTap: () => langProv.setLanguage(code),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF1E3C72).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? const Color(0xFF1E3C72) : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: active ? FontWeight.bold : FontWeight.w500,
                    color: active ? const Color(0xFF1E3C72) : Colors.black87,
                  ),
                ),
                if (active)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF1E3C72),
                  ),
              ],
            ),
          ),
        );
      }
    );
  }
}
