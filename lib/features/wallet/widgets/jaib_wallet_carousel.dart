import 'package:flutter/material.dart';
import 'package:six_cash/core/theme/buqsh_design.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/util/styles.dart';

const Color _walletPrimary = Color(0xFF0C4A40);
const Color _walletDark = Color(0xFF08332D);
const Color _walletLime = Color(0xFFD4E157);
const Color _walletGrey = Color(0xFF9AA2AD);
const Color _walletText = Color(0xFF1E1E1E);

class JaibWalletCarousel extends StatefulWidget {
  final List<WalletModel> wallets;
  final WalletModel? selected;
  final ValueChanged<WalletModel> onSelect;

  const JaibWalletCarousel({
    super.key,
    required this.wallets,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<JaibWalletCarousel> createState() => _JaibWalletCarouselState();
}

class _JaibWalletCarouselState extends State<JaibWalletCarousel> {
  late final PageController _controller;
  int _index = 0;
  // Security default: balances remain hidden until the user explicitly reveals them.
  bool _showBalance = false;

  @override
  void initState() {
    super.initState();
    _index = widget.selected == null ? 0 : widget.wallets.indexOf(widget.selected!);
    if (_index < 0) _index = 0;
    _controller = PageController(viewportFraction: .88, initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatBalance(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\.)'),
      (match) => '${match[1]},',
    );
  }

  String _walletCode(int index, WalletModel wallet) {
    final code = wallet.currencyCode.trim().toUpperCase();
    return code.isEmpty ? 'YER' : code;
  }

  String _walletName(int index, WalletModel wallet) {
    switch (_walletCode(index, wallet)) {
      case 'YER':
        return 'محفظة الريال اليمني';
      case 'USD':
        return 'محفظة الدولار';
      default:
        return wallet.currencyName;
    }
  }

  String _walletNumber(int index, WalletModel wallet) {
    return '••${wallet.id.toString().padLeft(4, '0')}';
  }

  String _amount(int index, WalletModel wallet) {
    final code = _walletCode(index, wallet);
    final suffix = code == 'USD' ? '\$' : 'ر.ي';
    return '${_formatBalance(wallet.currentBalance)} $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.wallets.length > 3 ? 3 : widget.wallets.length;
    if (count == 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: count,
            onPageChanged: (value) {
              setState(() => _index = value);
              widget.onSelect(widget.wallets[value]);
            },
            itemBuilder: (context, index) => _card(widget.wallets[index], index == _index, index),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            final active = index == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? _walletLime : _walletGrey,
                shape: BoxShape.circle,
                border: active ? Border.all(color: _walletPrimary, width: 1) : null,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _card(WalletModel wallet, bool active, int index) {
    final code = _walletCode(index, wallet);
    final isDollar = code == 'USD';
    final darkText = active && isDollar;
    final foreground = darkText ? _walletText : Colors.white;
    final gradient = active ? BqWalletGradient.forCurrency(code) : const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF303030)]);

    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: const [BoxShadow(color: Color(0x42000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('حساب', style: rubikMedium.copyWith(color: foreground, fontSize: 14)),
            Text(_walletName(index, wallet), style: rubikBold.copyWith(color: foreground, fontSize: 18)),
          ]),
          const SizedBox(height: 8),
          Text(_showBalance ? _amount(index, wallet) : '••••••', textAlign: TextAlign.center, style: rubikBold.copyWith(color: isDollar ? _walletLime : foreground, fontSize: 22, fontWeight: FontWeight.w900)),
          const Spacer(),
          Center(child: Text(code, style: TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.w800))),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_walletNumber(index, wallet), textDirection: TextDirection.ltr, style: rubikBold.copyWith(color: foreground, fontSize: 14)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: code == 'YER' ? _walletLime : (darkText ? _walletPrimary : Colors.white.withOpacity(.16)), borderRadius: BorderRadius.circular(8)), child: Text(code, style: TextStyle(color: code == 'YER' ? _walletPrimary : foreground, fontSize: 11, fontWeight: FontWeight.w900))),
            InkWell(
              onTap: () => setState(() => _showBalance = !_showBalance),
              borderRadius: BorderRadius.circular(99),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: foreground, size: 24),
                  const SizedBox(width: 3),
                  Text(_showBalance ? 'إخفاء' : 'إظهار', style: TextStyle(color: foreground, fontSize: 10, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
