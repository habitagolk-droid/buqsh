import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/images.dart';

const Color _jaibDrawerPrimary = Color(0xFF0C4A40);
const Color _jaibDrawerDark = Color(0xFF08332D);
const Color _jaibDrawerSecondary = Color(0xFF278D5B);
const Color _jaibDrawerLime = Color(0xFFD4E157);
const Color _jaibDrawerBg = Color(0xFFF4F5F7);
const Color _jaibDrawerText = Color(0xFF1E1E1E);

class JaibClientDrawer extends StatelessWidget {
  const JaibClientDrawer({super.key});

  void _go(String route) {
    Get.back();
    Get.toNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _jaibDrawerBg,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                children: [
                  _group('الحساب', [
                    _item(Icons.edit_outlined, 'تعديل الملف الشخصي', () => _go(RouteHelper.getEditProfileRoute())),
                    _item(Icons.history_rounded, 'سجل العمليات', () => _go(RouteHelper.history)),
                    _item(Icons.pending_actions_outlined, 'العمليات المعلقة', () => _go(RouteHelper.requestedMoney), badge: '2'),
                  ]),
                  _group('التحويلات', [
                    _item(Icons.send_outlined, 'إرسال أموال', () => _go(RouteHelper.getSendMoneyRoute(fromEdit: false))),
                    _item(Icons.swap_horiz_rounded, 'تحويل بين المحافظ', () => _go(RouteHelper.getWalletTransferRoute())),
                    _item(Icons.account_balance_wallet_outlined, 'المحافظ', () => _go(RouteHelper.walletTransfer)),
                  ]),
                  _group('الأمان', [
                    _item(Icons.security_outlined, 'الأمان والخصوصية', () => _go(RouteHelper.profile)),
                    _item(Icons.lock_outline_rounded, 'تغيير PIN', () => _go(RouteHelper.getChangePinRoute())),
                    _item(Icons.fingerprint_rounded, 'المصادقة الحيوية', () => _go(RouteHelper.profile)),
                  ]),
                  _group('التطبيق', [
                    _item(Icons.language_rounded, 'اللغة', () => _go(RouteHelper.getChoseLanguageRoute())),
                    _item(Icons.brightness_6_outlined, 'المظهر الليلي', () => _go(RouteHelper.themeAndLanguage)),
                    _item(Icons.qr_code_2_rounded, 'رمز QR الخاص بي', _showQr),
                  ]),
                  _group('الدعم', [
                    _item(Icons.support_agent_rounded, 'اتصل بنا', () => _go(RouteHelper.getSupportRoute())),
                    _item(Icons.chat_bubble_outline_rounded, 'المساعدة', () => _go(RouteHelper.getSupportRoute())),
                    _item(Icons.quiz_outlined, 'الأسئلة الشائعة', () => _go(RouteHelper.faq)),
                    _item(Icons.info_outline_rounded, 'من نحن', () => _go(RouteHelper.aboutUs)),
                    _item(Icons.description_outlined, 'الشروط والأحكام', () => _go(RouteHelper.terms)),
                    _item(Icons.privacy_tip_outlined, 'الخصوصية', () => _go(RouteHelper.privacy)),
                  ]),
                  const SizedBox(height: 8),
                  _item(Icons.logout_rounded, 'تسجيل الخروج', _confirmLogout, danger: true),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('بُقش • آمن وسريع', style: TextStyle(color: Color(0xFF9AA2AD), fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_jaibDrawerSecondary, _jaibDrawerPrimary, _jaibDrawerDark]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 29, backgroundColor: _jaibDrawerLime, child: Image.asset(Images.avatar, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أحمد الحداد', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('•• 4582  •  +967 777 123 456', textDirection: TextDirection.ltr, style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(onPressed: _showQr, icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _go(RouteHelper.getEditProfileRoute()),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('تعديل الملف'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: _jaibDrawerLime), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _group(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(8, 10, 8, 4), child: Text(title, style: const TextStyle(color: _jaibDrawerPrimary, fontSize: 12, fontWeight: FontWeight.w800))),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap, {String? badge, bool danger = false}) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(icon, color: danger ? Colors.red : _jaibDrawerPrimary, size: 21),
      title: Text(title, style: TextStyle(color: danger ? Colors.red : _jaibDrawerText, fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: badge == null ? const Icon(Icons.chevron_left_rounded, color: Color(0xFF9AA2AD), size: 18) : Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: const BoxDecoration(color: _jaibDrawerLime, shape: BoxShape.circle), child: Text(badge, style: const TextStyle(color: _jaibDrawerPrimary, fontWeight: FontWeight.w800))),
    );
  }

  void _confirmLogout() {
    Get.back();
    Get.dialog(AlertDialog(
      title: const Text('تسجيل الخروج'),
      content: const Text('هل تريد تسجيل الخروج من الحساب؟'),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('إلغاء')),
        TextButton(onPressed: () => Get.offAllNamed(RouteHelper.splash), child: const Text('خروج', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  void _showQr() {
    Get.back();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('رمز QR الخاص بي', style: TextStyle(color: _jaibDrawerPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Image.asset(Images.qrCode, width: 220, height: 220),
              const SizedBox(height: 8),
              const Text('يمكنك مشاركة هذا الرمز لاستقبال الأموال', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF7A838E), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
