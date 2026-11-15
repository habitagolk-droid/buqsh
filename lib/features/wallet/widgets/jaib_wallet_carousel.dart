import 'package:flutter/material.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/helper/price_converter_helper.dart';
import 'package:six_cash/util/styles.dart';

const Color _walletPrimary = Color(0xFF0C4A40);
const Color _walletDark = Color(0xFF08332D);
const Color _walletSecondary = Color(0xFF278D5B);
const Color _walletLime = Color(0xFFD4E157);
const Color _walletGrey = Color(0xFF9AA2AD);

class JaibWalletCarousel extends StatefulWidget {
  final List<WalletModel> wallets;
  final WalletModel? selected;
  final ValueChanged<WalletModel> onSelect;
  const JaibWalletCarousel({super.key, required this.wallets, required this.selected, required this.onSelect});
  @override State<JaibWalletCarousel> createState() => _JaibWalletCarouselState();
}

class _JaibWalletCarouselState extends State<JaibWalletCarousel> {
  late final PageController _controller;
  int _index = 0;
  bool _showBalance = true;

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

  String _balance(WalletModel wallet) => PriceConverterHelper.convertPrice(wallet.currentBalance).replaceFirst(RegExp(r'\s*\$'), '');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.wallets.length,
            onPageChanged: (value) {
              setState(() => _index = value);
              widget.onSelect(widget.wallets[value]);
            },
            itemBuilder: (context, index) => _card(widget.wallets[index], index == _index),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.wallets.length, (index) {
          final active = index == _index;
          return AnimatedContainer(duration: const Duration(milliseconds: 180), width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(color: active ? _walletLime : _walletGrey, shape: BoxShape.circle, border: active ? Border.all(color: _walletPrimary, width: 1) : null));
        })),
      ],
    );
  }

  Widget _card(WalletModel wallet, bool active) {
    final title = wallet.currencyCode.toUpperCase() == 'YER' ? 'ريال يمني' : wallet.currencyName;
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: active ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_walletSecondary, _walletPrimary, _walletDark]) : const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF303030)]),
        boxShadow: const [BoxShadow(color: Color(0x42000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('حساب', style: rubikMedium.copyWith(color: Colors.white, fontSize: 14)), Text(title, style: rubikBold.copyWith(color: Colors.white, fontSize: 18))]),
          const SizedBox(height: 8),
          Text(_showBalance ? _balance(wallet) : '••••••', textAlign: TextAlign.center, style: rubikBold.copyWith(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const Spacer(),
          const Center(child: Text('••••', style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4))),
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('•• ${wallet.currencyCode}', style: rubikBold.copyWith(color: Colors.white, fontSize: 14)), Text('VISA', style: rubikBold.copyWith(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 18)), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints.tightFor(width: 28, height: 28), onPressed: () => setState(() => _showBalance = !_showBalance), icon: Icon(_showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white, size: 24))]),
        ],
      ),
    );
  }
}
