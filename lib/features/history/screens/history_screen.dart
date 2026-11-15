import 'package:six_cash/common/widgets/custom_app_bar_widget.dart';
import 'package:six_cash/features/history/controllers/transaction_history_controller.dart';
import 'package:six_cash/features/history/domain/models/transaction_model.dart';
import 'package:six_cash/features/history/widgets/transaction_type_button_widget.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/history/widgets/transaction_list_widget.dart';

class HistoryScreen extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();
  final Transactions? transactions;
  HistoryScreen({Key? key, this.transactions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.find<TransactionHistoryController>().setIndex(0);
    return Scaffold(
      appBar: CustomAppbarWidget(title: 'history'.tr, onlyTitle: true),
      body: SafeArea(
        child: RefreshIndicator(
          backgroundColor: Theme.of(context).primaryColor,
          onRefresh: () async {
            await Get.find<TransactionHistoryController>().getTransactionData(1,reload: true);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            slivers: [

              SliverPersistentHeader(
                  pinned: true,
                  delegate: SliverDelegate(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                        height: 112,
                        child: GetBuilder<TransactionHistoryController>(builder: (historyController) {
                          return Column(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                decoration: InputDecoration(hintText: 'بحث في العمليات', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 32,
                              child: ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                scrollDirection: Axis.horizontal,
                                children: [
                                  TransactionTypeButtonWidget(text: 'الكل', index: 0, transactionHistoryList: historyController.transactionList),
                                  const SizedBox(width: 8),
                                  TransactionTypeButtonWidget(text: 'وارد', index: 4, transactionHistoryList: historyController.receivedMoneyList),
                                  const SizedBox(width: 8),
                                  TransactionTypeButtonWidget(text: 'صادر', index: 1, transactionHistoryList: historyController.sendMoneyList),
                                  const SizedBox(width: 8),
                                  TransactionTypeButtonWidget(text: 'فواتير', index: 7, transactionHistoryList: historyController.paymentList),
                                ],
                              ),
                            ),
                          ]);
                        }),
                      ))),
              SliverToBoxAdapter(
                child: Scrollbar(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: TransactionListWidget(scrollController: _scrollController,isHome: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  SliverDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 112;

  @override
  double get minExtent => 112;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != 112 || oldDelegate.minExtent != 112 || child != oldDelegate.child;
  }
}
