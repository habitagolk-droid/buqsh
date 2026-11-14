import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/home/widgets/banner_widget.dart';
import 'package:six_cash/features/home/widgets/services_grid_widget.dart';
import 'package:six_cash/features/splash/controllers/splash_controller.dart';
import 'package:six_cash/features/wallet/widgets/multi_wallet_cards_widget.dart';

class ThemeOneWidget extends StatelessWidget {
  const ThemeOneWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        return Stack(
          children: [
            Container(
              height: 140.0,
              color: Theme.of(context).primaryColor,
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // 2. بطاقات المحافظ الثلاث وأرصدتها الحقيقية: YER وUSD وSAR
                  MultiWalletCardsWidget(),

                  // 3. البنر الأصلي "BannerWidget"
                  BannerWidget(),

                  // 4. شبكة الخدمات المصغرة 3×3 (9 بطاقات)
                  ServicesGridWidget(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
