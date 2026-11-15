import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/common/widgets/custom_ink_well_widget.dart';
import 'package:six_cash/features/setting/controllers/profile_screen_controller.dart';
import 'package:six_cash/features/wallet/controllers/wallet_controller.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/features/pos/controllers/cashier_wallet_controller.dart';
import 'package:six_cash/helper/price_converter_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/features/wallet/widgets/jaib_wallet_carousel.dart';

class MultiWalletCardsWidget extends StatelessWidget {
  const MultiWalletCardsWidget({Key? key}) : super(key: key);

  String _formatBalance(double balance) {
    return balance
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    if (Get.find<CashierAuthController>().isSessionReady) {
      if (!Get.isRegistered<CashierWalletController>()) {
        return const SizedBox.shrink();
      }
      return GetBuilder<CashierWalletController>(
        builder: (controller) => _buildCashierWalletCard(context, controller),
      );
    }

    if (!Get.isRegistered<WalletController>()) {
      return const SizedBox.shrink();
    }

    return GetBuilder<WalletController>(
      builder: (walletController) {
        if (walletController.isLoading && walletController.wallets.isEmpty) {
          return Container(
            height: 120,
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusSizeLarge),
              color: Theme.of(context).cardColor,
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (walletController.wallets.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeDefault,
            ),
            margin: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeSmall,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusSizeLarge),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          walletController.errorMessage ??
                              'failed_to_fetch_wallets'.tr,
                          style: rubikRegular.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => walletController.getWallets(reload: true),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

            final List<WalletModel> wallets = walletController.wallets;
            final WalletModel? selected =
                walletController.selectedWallet ??
                (wallets.isNotEmpty ? wallets.first : null);

            return JaibWalletCarousel(
              wallets: wallets,
              selected: selected,
              onSelect: walletController.selectWallet,
            );

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusSizeLarge),
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // كرت الرصيد الرئيسي للمحفظة المختارة
                  Padding(
                    padding: const EdgeInsets.all(
                      Dimensions.paddingSizeDefault,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'available_balance'.tr,
                                    style: rubikMedium.copyWith(
                                      color:
                                          ColorResources.getBalanceTextColor(),
                                      fontSize: Dimensions.fontSizeSmall,
                                    ),
                                  ),
                                  if (selected != null &&
                                      selected.isDefault) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'default_wallet'.tr,
                                        style: rubikMedium.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (selected != null)
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    '${selected.currencySymbol} ${_formatBalance(selected.currentBalance)}',
                                    style: rubikBold.copyWith(
                                      fontSize: Dimensions.fontSizeOverLarge,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.color,
                                    ),
                                  ),
                                )
                              else
                                GetBuilder<ProfileController>(
                                  builder: (profileController) {
                                    final bal =
                                        profileController.userInfo?.balance ??
                                        0.0;
                                    return FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(
                                        PriceConverterHelper.convertPrice(bal),
                                        style: rubikBold.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeOverLarge,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.color,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              const SizedBox(height: 2),
                              if (selected != null)
                                Text(
                                  selected.currencyName,
                                  style: rubikMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: ColorResources.getHintColor(),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // أيقونة شارة العملة
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).secondaryHeaderColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            selected?.currencySymbol ?? '﷼',
                            style: rubikBold.copyWith(
                              fontSize: 22,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // شريط التبديل بين المحافظ الثلاث (YER, USD, SAR)
                  if (wallets.isNotEmpty) ...[
                    const Divider(height: 1, thickness: 0.6),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeSmall,
                        vertical: 8,
                      ),
                      child: Row(
                        children: wallets.map((wallet) {
                          final bool isSelected =
                              selected?.currencyCode == wallet.currencyCode;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1)
                                    : Theme.of(context).scaffoldBackgroundColor
                                          .withOpacity(0.6),
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSizeDefault,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: CustomInkWellWidget(
                                onTap: () =>
                                    walletController.selectWallet(wallet),
                                radius: Dimensions.radiusSizeDefault,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        wallet.currencyCode,
                                        style: rubikSemiBold.copyWith(
                                          fontSize: Dimensions.fontSizeDefault,
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Theme.of(
                                                  context,
                                                ).textTheme.titleMedium?.color,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _formatBalance(wallet.currentBalance),
                                          maxLines: 1,
                                          style: rubikMedium.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: isSelected
                                                ? Theme.of(context).primaryColor
                                                : ColorResources.getHintColor(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
  }

  Widget _buildCashierSessionCard(
    BuildContext context,
    CashierAuthController controller,
  ) {
    final fields = controller.sessionInfo?.displayFields ?? const [];

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusSizeLarge),
        color: Theme.of(context).cardColor,
      ),
      child: controller.isSessionInfoLoading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : controller.sessionInfoError != null
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.sessionInfoError!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: rubikRegular.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: controller.retrySessionInfo,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('retry'.tr),
                  ),
                ],
              ),
            )
          : fields.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ColorResources.getGreyColor(),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'cashier_session_no_details'.tr,
                      style: rubikRegular.copyWith(
                        color: ColorResources.getGreyColor(),
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: Dimensions.paddingSizeSmall,
              ),
              itemCount: fields.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: ColorResources.getGreyBaseGray4().withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final field = fields[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: rubikRegular.copyWith(
                            color: ColorResources.getGreyColor(),
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          field.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: rubikMedium.copyWith(
                            color: ColorResources.getBalanceTextColor(),
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCashierWalletCard(
    BuildContext context,
    CashierWalletController controller,
  ) {
    final wallets = controller.displayWallets;
    if (controller.isLoading && wallets.isEmpty) {
      return Container(
        height: 160,
        margin: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSizeLarge),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (wallets.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSizeLarge),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.errorMessage ?? 'failed_to_fetch_wallets'.tr,
                style: rubikRegular.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ),
            IconButton(
              onPressed: controller.fetchCashierWallets,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );
    }

    final selected = controller.selectedCashierWallet ?? wallets.first;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSizeLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'available_balance'.tr,
                        style: rubikMedium.copyWith(
                          color: ColorResources.getBalanceTextColor(),
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${selected.currencySymbol} ${_formatBalance(selected.currentBalance)}',
                          style: rubikBold.copyWith(
                            fontSize: Dimensions.fontSizeOverLarge,
                            color: Theme.of(context).textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      Text(
                        selected.currencyName,
                        style: rubikMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: ColorResources.getHintColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).secondaryHeaderColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    selected.currencySymbol,
                    style: rubikBold.copyWith(
                      fontSize: 22,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: 8,
            ),
            child: Row(
              children: wallets.map((wallet) {
                final isSelected = wallet.currencyCode == selected.currencyCode;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: CustomInkWellWidget(
                      onTap: () => controller.selectCashierWallet(wallet),
                      radius: Dimensions.radiusSizeDefault,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Column(
                          children: [
                            Text(
                              wallet.currencyCode,
                              style: rubikSemiBold.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).textTheme.titleMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 3),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatBalance(wallet.currentBalance),
                                maxLines: 1,
                                style: rubikMedium.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : ColorResources.getHintColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
