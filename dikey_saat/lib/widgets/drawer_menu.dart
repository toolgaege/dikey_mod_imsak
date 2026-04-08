import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../screens/vertical_clock_page.dart';
import '../screens/home_page.dart';
import '../services/storage_service.dart';

class DrawerMenu extends StatefulWidget {
  final bool isTestMode;
  final Function(bool) onTestModeChanged;

  const DrawerMenu({
    super.key,
    required this.isTestMode,
    required this.onTestModeChanged,
  });

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  final StorageService _storageService = StorageService();
  String _defaultPage = 'home';

  @override
  void initState() {
    super.initState();
    _loadDefaultPage();
  }

  Future<void> _loadDefaultPage() async {
    final page = await _storageService.getDefaultPage();
    if (mounted) {
      setState(() {
        _defaultPage = page;
      });
    }
  }

  Future<void> _saveDefaultPage(String pageName) async {
    await _storageService.saveDefaultPage(pageName);
    if (mounted) {
      setState(() {
        _defaultPage = pageName;
      });

      // Hemen yeni sayfaya yönlendir
      if (pageName == 'vertical_clock') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VerticalClockPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Premium Header (Fixed at Top)
          Container(
            padding:
                const EdgeInsets.only(top: 60, bottom: 30, left: 16, right: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF001144), Color(0xFF0033AA)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.mosque, color: Colors.white, size: 40),
                const SizedBox(height: 15),
                Text(
                  'SULTAN MESCİDİ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                          offset: const Offset(1, 1)),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 1,
                  width: double.infinity,
                  color: Colors.white.withOpacity(0.3),
                ),
                const Text(
                  'AYARLAR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 8,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // 2. Scrollable Menu Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildMenuSectionTitle('Hızlı Erişim'),
                _buildNavigationItem(
                  icon: Icons.access_time_filled,
                  title: 'Dikey Saat Sayfası',
                  isSelected: _defaultPage == 'vertical_clock',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VerticalClockPage()),
                    );
                  },
                ),
                _buildNavigationItem(
                  icon: Icons.dashboard,
                  title: 'Ana Sayfa (Vakitler)',
                  isSelected: _defaultPage == 'home',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                ),

                const SizedBox(height: 24),
                _buildMenuSectionTitle('Açılış Sayfası Seçimi'),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _buildRadioTile(
                        title: 'Namaz Vakitleri ile başlasın',
                        value: 'home',
                        groupValue: _defaultPage,
                        onChanged: (v) =>
                            v != null ? _saveDefaultPage(v) : null,
                      ),
                      const SizedBox(height: 4),
                      _buildRadioTile(
                        title: 'Dikey Saat ile başlasın',
                        value: 'vertical_clock',
                        groupValue: _defaultPage,
                        onChanged: (v) =>
                            v != null ? _saveDefaultPage(v) : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Test Mode Section
                _buildMenuSectionTitle('Geliştirici'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: widget.isTestMode
                          ? AppColors.weatherText
                          : Colors.white10,
                      width: 1,
                    ),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Test Modu',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white),
                    ),
                    subtitle: Text(
                      widget.isTestMode
                          ? 'Tarih değiştirme aktif'
                          : 'Gerçek tarih kullanılıyor',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.white.withOpacity(0.5)),
                    ),
                    value: widget.isTestMode,
                    activeColor: AppColors.weatherText,
                    onChanged: widget.onTestModeChanged,
                  ),
                ),
                if (widget.isTestMode) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.weatherText.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.weatherText, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sağ alttaki takvim butonuyla tarih değiştirebilirsiniz',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.white.withOpacity(0.7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 3. Footer (Fixed at Bottom)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Versiyon 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.white.withOpacity(0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 10, top: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.weatherText,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.weatherText.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.weatherText.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon,
            color: isSelected ? AppColors.weatherText : Colors.white70,
            size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.white : Colors.white70,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle,
                color: AppColors.weatherText, size: 18)
            : null,
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return RadioListTile<String>(
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.white : Colors.white70,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      value: value,
      groupValue: groupValue,
      activeColor: AppColors.weatherText,
      dense: true,
      onChanged: onChanged,
    );
  }
}
