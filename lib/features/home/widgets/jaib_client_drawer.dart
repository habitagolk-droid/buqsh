import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/images.dart';

const Color _primary = Color(0xFF0C4A40);
const Color _primaryDark = Color(0xFF08332D);
const Color _secondary = Color(0xFF278D5B);
const Color _lime = Color(0xFFD4E157);
const Color _limeSoft = Color(0x59D4E157);
const Color _background = Color(0xFFF4F5F7);
const Color _darkText = Color(0xFF1E1E1E);
const Color _grey = Color(0xFF9AA2AD);

/// Drawer-only settings. The existing authentication flow remains untouched.
class JaibAuthSettings {
  static bool biometricEnabled = true;
  static bool twoFactorEnabled = false;
  static bool darkMode = false;
}

class JaibClientDrawer extends StatefulWidget {
  const JaibClientDrawer({super.key});

  @override
  State<JaibClientDrawer> createState() => _JaibClientDrawerState();
}

class _JaibClientDrawerState extends State<JaibClientDrawer> {
  void _go(String route) {
    Get.back();
    Get.toNamed(route);
  }

  void _setSetting(VoidCallback update) {
    setState(update);
    showCustomSnackBarHelper('تم التحديث ✅', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    final dark = JaibAuthSettings.darkMode;
    return Drawer(
      backgroundColor: dark ? const Color(0xFF1E2224) : _background,
      child: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _header(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                  children: [
                    _group('الحساب', [
                      _item(Icons.person_outline_rounded, 'تعديل معلوماتك وبياناتك', () => _go(RouteHelper.getEditProfileRoute())),
                      _item(Icons.receipt_long_outlined, 'سجل العمليات / كشف الحساب', () => _go(RouteHelper.history)),
                      _item(Icons.hourglass_empty_rounded, 'الطلبات المعلقة', () => _go(RouteHelper.requestedMoney), badge: '2'),
                    ]),
                    _group('التحويلات', [
                      _item(Icons.send_rounded, 'إرسال طلب تحويل / دفع', () => _go(RouteHelper.getSendMoneyRoute(fromEdit: false))),
                      _item(Icons.speed_rounded, 'سقف التحويل / أقصى حد', () => _go(RouteHelper.profile), progress: true),
                    ]),
                    _group('الأمان', [
                      _item(Icons.shield_outlined, 'إعدادات الأمان', () => _go(RouteHelper.profile)),
                      _item(Icons.key_rounded, 'تغيير الرقم السري', () => _go(RouteHelper.getChangePinRoute())),
                      _item(Icons.smartphone_rounded, 'التحقق بخطوتين', () => _setSetting(() => JaibAuthSettings.twoFactorEnabled = !JaibAuthSettings.twoFactorEnabled), toggle: JaibAuthSettings.twoFactorEnabled),
                      _item(Icons.fingerprint_rounded, 'الدخول بالبصمة', () => _setSetting(() => JaibAuthSettings.biometricEnabled = !JaibAuthSettings.biometricEnabled), toggle: JaibAuthSettings.biometricEnabled),
                    ]),
                    _group('التطبيق', [
                      _item(Icons.language_rounded, 'لغة التطبيق', () => _go(RouteHelper.getChoseLanguageRoute()), badge: 'العربية'),
                      _item(Icons.nightlight_outlined, 'الوضع الليلي', () => _setSetting(() => JaibAuthSettings.darkMode = !JaibAuthSettings.darkMode), toggle: dark),
                      _item(Icons.lock_outline_rounded, 'قفل / إلغاء الحساب نهائيًا', _confirmAccountAction),
                    ]),
                    _group('الدعم', [
                      _item(Icons.headset_mic_outlined, 'خدمة العملاء 24/7', () => _go(RouteHelper.getSupportRoute()), trailing: const Icon(Icons.call_outlined, color: _primary, size: 19)),
                      _item(Icons.help_outline_rounded, 'الأسئلة الشائعة', () => _go(RouteHelper.faq)),
                      _item(Icons.info_outline_rounded, 'من نحن', () => _go(RouteHelper.aboutUs)),
                      _item(Icons.description_outlined, 'الشروط والأحكام', () => _go(RouteHelper.terms)),
                      _item(Icons.lock_outline_rounded, 'الخصوصية', () => _go(RouteHelper.privacy)),
                    ]),
                    _group('خروج', [
                      _item(Icons.logout_rounded, 'تسجيل الخروج', _confirmLogout, danger: true),
                    ]),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: dark ? const Color(0xFF293033) : _background, borderRadius: BorderRadius.circular(12)),
                      child: const Text('جيب باي v2.4  •  آمن • سريع • بدون رسوم', textAlign: TextAlign.center, style: TextStyle(color: _grey, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_secondary, _primary, _primaryDark]),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 57,
                height: 57,
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(color: _lime, shape: BoxShape.circle),
                child: CircleAvatar(backgroundColor: _primary, backgroundImage: AssetImage(Images.avatar)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('أحمد الحداد', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('•• 4582', textDirection: TextDirection.ltr, style: TextStyle(color: Colors.white, fontSize: 11)),
                    Text('+967 777 123 456', textDirection: TextDirection.ltr, style: TextStyle(color: Colors.white, fontSize: 11)),
                    SizedBox(height: 4),
                    Row(children: [Icon(Icons.verified_rounded, color: _lime, size: 13), SizedBox(width: 3), DecoratedBox(decoration: BoxDecoration(color: _lime, borderRadius: BorderRadius.all(Radius.circular(5))), child: Padding(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text('توثيق', style: TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.w800))))]),
                  ],
                ),
              ),
              Column(
                children: [
                  _headerButton(Icons.qr_code_rounded, _showQr),
                  const SizedBox(height: 6),
                  _headerButton(Icons.close_rounded, () => Get.back()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ghostButton(Icons.edit_outlined, 'تعديل الملف', () => _go(RouteHelper.getEditProfileRoute()))),
              const SizedBox(width: 8),
              Expanded(child: _ghostButton(Icons.qr_code_rounded, 'رمز QR', _showQr)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(width: 34, height: 34, decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 20)),
      );

  Widget _ghostButton(IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: _lime), padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      );

  Widget _group(String title, List<Widget> items) {
    final dark = JaibAuthSettings.darkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(6, 8, 6, 5), child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), decoration: BoxDecoration(color: _limeSoft, borderRadius: BorderRadius.circular(99)), child: Text(title, style: const TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w900)))),
        Container(
          decoration: BoxDecoration(color: dark ? const Color(0xFF293033) : Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(children: items),
        ),
        const Divider(height: 8, color: Color(0xFFEEF1F4)),
      ],
    );
  }

  Widget _item(IconData icon, String title, VoidCallback onTap, {String? badge, bool? toggle, bool danger = false, bool progress = false, Widget? trailing}) {
    final Widget? itemTrailing = trailing ?? _buildTrailing(toggle, badge, onTap);
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      onTap: onTap,
      leading: Icon(icon, color: danger ? const Color(0xFFB3261E) : _primary, size: 19),
      title: Text(title, style: TextStyle(color: danger ? const Color(0xFFB3261E) : _darkText, fontSize: 13, fontWeight: FontWeight.w700)),
      subtitle: progress ? ClipRRect(borderRadius: BorderRadius.circular(99), child: const LinearProgressIndicator(value: .64, minHeight: 5, backgroundColor: Color(0xFFE7ECEA), valueColor: AlwaysStoppedAnimation(_secondary))) : null,
      trailing: itemTrailing,
    );
  }

  Widget? _buildTrailing(bool? toggle, String? badge, VoidCallback onTap) {
    if (toggle != null) {
      return Switch(
        value: toggle,
        onChanged: (_) => onTap(),
        activeColor: _primary,
      );
    }
    if (badge != null) {
      return Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
        child: Text(
          badge,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
        ),
      );
    }
    return const Icon(Icons.chevron_left_rounded, color: _grey, size: 18);
  }

  void _showQr() {
    Get.back();
    Get.dialog(Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('رمز QR الخاص بي', style: TextStyle(color: _primary, fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 14), Image.asset(Images.qrCode, width: 220, height: 220), const SizedBox(height: 8), const Text('مشاركة الرمز لاستقبال الأموال', style: TextStyle(color: _grey, fontSize: 12))])));
  }

  void _confirmAccountAction() {
    Get.back();
    Get.dialog(AlertDialog(title: const Text('قفل أو إلغاء الحساب'), content: const Text('هل تريد متابعة هذا الإجراء؟'), actions: [TextButton(onPressed: Get.back, child: const Text('إلغاء')), TextButton(onPressed: Get.back, child: const Text('متابعة', style: TextStyle(color: Color(0xFFB3261E))))]));
  }

  void _confirmLogout() {
    Get.back();
    Get.dialog(AlertDialog(title: const Text('تسجيل الخروج'), content: const Text('هل تريد تسجيل الخروج من الحساب؟'), actions: [TextButton(onPressed: Get.back, child: const Text('إلغاء')), TextButton(onPressed: () => Get.offAllNamed(RouteHelper.splash), child: const Text('خروج', style: TextStyle(color: Color(0xFFB3261E))))]));
  }
}
