import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/history/controllers/transaction_history_controller.dart';
import 'package:six_cash/features/history/domain/models/transaction_model.dart';
import 'package:six_cash/features/history/utils/transaction_formatting.dart';
import 'package:six_cash/features/home/widgets/services_grid_widget.dart';
import 'package:six_cash/features/home/widgets/banner_widget.dart';
import 'package:six_cash/features/home/widgets/layered_service_icon.dart';
import 'package:six_cash/features/wallet/controllers/wallet_controller.dart';
import 'package:six_cash/features/pos/controllers/cashier_wallet_controller.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/features/splash/controllers/splash_controller.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/styles.dart';

class ClientHomeDashboardWidget extends StatefulWidget {
  final bool cashierMode;
  const ClientHomeDashboardWidget({Key? key, this.cashierMode = false}) : super(key: key);

  @override
  State<ClientHomeDashboardWidget> createState() =>
      _ClientHomeDashboardWidgetState();
}

class _ClientHomeDashboardWidgetState extends State<ClientHomeDashboardWidget> {
  static const _primary = Color(0xFF278D5B);
  static const _dark = Color(0xFF0A3A2A);
  static const _background = Color(0xFFF4F5F7);
  static const _soft = Color(0xFFF0F1F4);
  static const _alert = Color(0xFFE8F5E9);

  final PageController _walletPageController = PageController(
    viewportFraction: 0.88,
  );
  bool _showAlert = true;
  bool _hideBalances = false;
  int _walletIndex = 0;
  int _recentFilter = 0;
  String _recentQuery = '';

  @override
  void dispose() {
    _walletPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showAlert) _buildAlertBanner(),
          _buildWalletSection(),
          _buildRestoredBanner(),
          _buildSectionTitle('الخدمات'),
          const ServicesGridWidget(),
          _buildTransactionsSection(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _alert,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            onPressed: () => setState(() => _showAlert = false),
            icon: const Icon(Icons.close_rounded, size: 20, color: _primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'محفظتك جاهزة وآمنة للاستخدام',
              textAlign: TextAlign.center,
              style: rubikBold.copyWith(fontSize: 13, color: _primary),
            ),
          ),
          const Icon(Icons.notifications_none_rounded, size: 20, color: _primary),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    if (!Get.isRegistered<WalletController>()) return const SizedBox.shrink();

    return GetBuilder<WalletController>(
      builder: (controller) {
        final wallets = controller.wallets;
        if (controller.isLoading && wallets.isEmpty) {
          return const SizedBox(
            height: 230,
            child: Center(child: CircularProgressIndicator(color: _primary)),
          );
        }
        if (wallets.isEmpty) {
          return Container(
            height: 120,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: _primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.errorMessage ?? 'تعذر تحميل المحافظ',
                    style: rubikRegular.copyWith(color: _dark, fontSize: 13),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.getWallets(reload: true),
                  icon: const Icon(Icons.refresh_rounded, color: _primary),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _walletPageController,
                itemCount: wallets.length,
                onPageChanged: (index) {
                  setState(() => _walletIndex = index);
                  controller.selectWallet(wallets[index]);
                },
                itemBuilder: (context, index) => _buildWalletCard(wallets[index], index),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                wallets.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _walletIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _walletIndex ? _primary : Colors.grey[400],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCashierWalletSection() {
    if (!Get.isRegistered<CashierWalletController>()) return const SizedBox.shrink();
    return GetBuilder<CashierWalletController>(
      builder: (controller) {
        final wallets = controller.displayWallets;
        if (controller.isLoading && wallets.isEmpty) {
          return const SizedBox(height: 230, child: Center(child: CircularProgressIndicator(color: _primary)));
        }
        if (wallets.isEmpty) {
          return Container(
            height: 120,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_outlined, color: _primary),
              const SizedBox(width: 10),
              Expanded(child: Text(controller.errorMessage ?? 'تعذر تحميل محافظ الكاشير', style: rubikRegular.copyWith(color: _dark, fontSize: 13))),
              IconButton(onPressed: () => controller.fetchCashierWallets(), icon: const Icon(Icons.refresh_rounded, color: _primary)),
            ]),
          );
        }
        return Column(children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _walletPageController,
              itemCount: wallets.length,
              onPageChanged: (index) { setState(() => _walletIndex = index); controller.selectCashierWallet(wallets[index]); },
              itemBuilder: (context, index) => _buildWalletCard(wallets[index], index),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(wallets.length, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 180), margin: const EdgeInsets.symmetric(horizontal: 3),
            width: index == _walletIndex ? 16 : 6, height: 6,
            decoration: BoxDecoration(color: index == _walletIndex ? _primary : Colors.grey[400], borderRadius: BorderRadius.circular(6)),
          ))),
        ]);
      },
    );
  }

  Widget _buildWalletCard(WalletModel wallet, int index) {
    final balance = wallet.currentBalance
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    final isLightCard = index == 2 || wallet.currencyCode.toUpperCase() == 'USD';
    final foreground = isLightCard ? _dark : Colors.white;
    final accent = index == 1 ? const Color(0xFFD4E157) : (isLightCard ? _primary : Colors.white);
    final gradient = index == 1
        ? const [Color(0xFF1E1E1E), _dark]
        : isLightCard
            ? const [Colors.white, Color(0xFFE8F5E9)]
            : const [_primary, _dark];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: gradient,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x180A3A2A), blurRadius: 12, offset: Offset(0, 5)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المحفظة', style: rubikRegular.copyWith(color: foreground.withOpacity(.70), fontSize: 14)),
                Text(
                  wallet.isDefault ? 'المحفظة الافتراضية' : wallet.currencyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: rubikBold.copyWith(color: foreground, fontSize: 16),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _hideBalances ? '••••••••' : '$balance ${wallet.currencySymbol}',
              textAlign: TextAlign.right,
              style: rubikBold.copyWith(color: foreground, fontSize: 24),
            ),
            const SizedBox(height: 2),
            Text(
              wallet.currencyCode,
              textAlign: TextAlign.right,
              style: rubikRegular.copyWith(color: foreground.withOpacity(.70), fontSize: 12),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                  onPressed: () => setState(() => _hideBalances = !_hideBalances),
                  icon: Icon(
                    _hideBalances ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 24,
                    color: accent,
                  ),
                ),
                Row(
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return InkWell(
      onTap: () => showCustomSnackBarHelper('coming_soon'.tr),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.router_outlined, size: 32, color: _dark),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('كروت الشبكات', style: rubikBold.copyWith(color: _primary, fontSize: 16)),
                Text('صارت في الجيب', style: rubikRegular.copyWith(color: _dark, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestoredBanner() {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        // Customer banners are not requested with a cashier token. Keep the
        // same visual slot until a cashier banner source is provided.
        final bannerEnabled = !widget.cashierMode &&
            (splashController.configModel?.systemFeature?.bannerStatus ?? false);
        if (bannerEnabled) return const BannerWidget();
        return Container(
          height: 120,
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withOpacity(.12)),
          ),
          child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.image_outlined, size: 34, color: _primary.withOpacity(.65)),
                    Positioned(
                      right: 14,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _dark.withOpacity(.92),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'بنر ترويجي',
                          style: rubikMedium.copyWith(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(title, textAlign: TextAlign.right, style: rubikBold.copyWith(color: _dark, fontSize: 18)),
    );
  }

  Widget _buildTransactionsSection() {
    // Do not render customer transaction data for a cashier session. The
    // cashier history remains available through its dedicated screen/API.
    if (widget.cashierMode || !Get.isRegistered<TransactionHistoryController>()) return const SizedBox.shrink();
    return GetBuilder<TransactionHistoryController>(
      builder: (controller) {
        final source = controller.transactionList.where((item) {
          final title = getTransactionTitle(item.transactionType).toLowerCase();
          final queryMatches = _recentQuery.trim().isEmpty || title.contains(_recentQuery.trim().toLowerCase());
          final credit = (item.credit ?? 0) > 0;
          final type = item.transactionType ?? '';
          final filterMatches = _recentFilter == 0 || (_recentFilter == 1 && credit) || (_recentFilter == 2 && !credit) || (_recentFilter == 3 && type.contains('payment'));
          return queryMatches && filterMatches;
        }).toList();
        final items = source.take(6).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('آخر العمليات', style: rubikBold.copyWith(color: _dark, fontSize: 18)),
                  Row(children: [
                    SizedBox(
                      width: 136,
                      height: 38,
                      child: TextField(
                        textDirection: TextDirection.rtl,
                        onChanged: (value) => setState(() => _recentQuery = value),
                        textAlign: TextAlign.right,
                        style: rubikRegular.copyWith(fontSize: 12, color: _dark),
                        decoration: InputDecoration(
                          hintText: 'بحث...',
                          hintStyle: rubikRegular.copyWith(fontSize: 11, color: Colors.grey[500]),
                          suffixIcon: const Icon(Icons.search_rounded, size: 18),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Get.toNamed(RouteHelper.history),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: Text('الكل', style: rubikMedium.copyWith(color: Colors.grey[600], fontSize: 12)),
                    ),
                  ]),
                ],
              ),
            ),
            SizedBox(
              height: 34,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [_recentFilterChip('الكل', 0), _recentFilterChip('وارد', 1), _recentFilterChip('صادر', 2), _recentFilterChip('فواتير', 3)]),
              ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text('لا توجد عمليات حديثة', textAlign: TextAlign.right, style: rubikRegular.copyWith(color: Colors.grey[600], fontSize: 13)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (_, index) => _buildTransactionCard(items[index]),
              ),
          ],
        );
      },
    );
  }

  Widget _recentFilterChip(String label, int index) {
    final selected = _recentFilter == index;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _recentFilter = index),
        labelStyle: rubikMedium.copyWith(color: selected ? Colors.white : Colors.grey[700], fontSize: 11),
        selectedColor: const Color(0xFF1E1E1E),
        backgroundColor: Colors.white,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
    );
  }

  Widget _buildTransactionCard(Transactions item) {
    final credit = (item.credit ?? 0) > 0;
    final amount = item.formatAmount();
    final title = getTransactionTitle(item.transactionType);
    final pending = (item.transactionType ?? '').toLowerCase().contains('pending');
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: credit ? const Color(0xFFE4F3EA) : const Color(0xFFF2F6D8), shape: BoxShape.circle),
            child: LayeredServiceIcon(kind: credit ? 0 : 1, small: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: rubikBold.copyWith(color: _dark, fontSize: 14)),
                const SizedBox(height: 2),
                Text(formatTransactionDate(item.createdAt), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: rubikRegular.copyWith(color: Colors.grey[600], fontSize: 11)),
              ],
            ),
          ),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
              '${credit ? '+' : '-'} $amount',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: rubikBold.copyWith(color: credit ? _primary : _dark, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: (pending ? const Color(0xFFD4E157) : _primary).withOpacity(.18), borderRadius: BorderRadius.circular(20)), child: Text(pending ? 'قيد التنفيذ' : 'ناجح', style: rubikMedium.copyWith(fontSize: 10, color: pending ? _dark : _primary))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
