import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_repo.dart';
import 'package:six_cash/features/pos/controllers/cashier_wallet_controller.dart';
import 'package:six_cash/features/pos/screens/cashier_login_screen.dart';
import 'package:six_cash/features/wallet/widgets/multi_wallet_cards_widget.dart';
import 'package:six_cash/helper/route_helper.dart';

void main() {
  late _FakeCashierAuthRepo repo;

  setUp(() {
    Get.testMode = true;
    Get.reset();
    repo = _FakeCashierAuthRepo()..customerToken = 'customer-token';
  });

  tearDown(() {
    Get.reset();
  });

  Future<CashierAuthController> createController(WidgetTester tester) async {
    Get.put(CashierWalletController(authRepo: repo));
    final controller = Get.put(
      CashierAuthController(authRepo: repo),
      permanent: true,
    );
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: RouteHelper.cashierLogin,
        getPages: [
          GetPage(name: RouteHelper.cashierLogin, page: () => const SizedBox()),
          GetPage(
            name: RouteHelper.navbar,
            page: () => const Scaffold(body: MultiWalletCardsWidget()),
          ),
        ],
      ),
    );
    return controller;
  }

  testWidgets('login activates cashier and isolates session', (tester) async {
    final controller = await createController(tester);

    final success = await controller.login(
      username: 'cashier',
      password: 'test-password',
    );
    await tester.pumpAndSettle();

    expect(success, isTrue);
    expect(controller.isSessionReady, isTrue);
    expect(repo.cashierToken, 'cashier-token');
    expect(repo.customerToken, isNull);
  });

  testWidgets('login stores returned cashier session details', (tester) async {
    repo.infoResponse = const Response(
      statusCode: 200,
      body: {
        'data': {'cashier_name': 'Cashier A', 'branch': 'North'},
      },
    );
    final controller = await createController(tester);

    final success = await controller.login(
      username: 'cashier',
      password: 'test-password',
    );
    await tester.pumpAndSettle();

    expect(success, isTrue);
    expect(controller.sessionInfo?.fields, {
      'cashier_name': 'Cashier A',
      'branch': 'North',
    });
    expect(controller.isSessionInfoLoading, isFalse);
    expect(controller.sessionInfoError, isNull);
  });

  testWidgets('session details can be retried after an API failure', (
    tester,
  ) async {
    final controller = await createController(tester);
    await controller.login(username: 'cashier', password: 'test-password');
    await tester.pumpAndSettle();

    repo.infoResponse = const Response(statusCode: 500);
    await controller.retrySessionInfo();

    expect(controller.sessionInfoError, isNotNull);
    expect(controller.isSessionInfoLoading, isFalse);

    repo.infoResponse = const Response(
      statusCode: 200,
      body: {
        'content': {'branch': 'South'},
      },
    );
    await controller.retrySessionInfo();

    expect(controller.sessionInfoError, isNull);
    expect(controller.sessionInfo?.displayFields.single.value, 'South');
    expect(controller.isSessionInfoLoading, isFalse);
  });

  testWidgets('session info loading state resets after a request', (
    tester,
  ) async {
    final controller = await createController(tester);
    await controller.login(username: 'cashier', password: 'test-password');
    await tester.pumpAndSettle();

    final completer = Completer<Response>();
    repo.infoCompleter = completer;
    final retry = controller.retrySessionInfo();
    await tester.pump();

    expect(controller.isSessionInfoLoading, isTrue);

    completer.complete(
      const Response(statusCode: 200, body: {'branch': 'West'}),
    );
    await retry;
    await tester.pump();

    expect(controller.isSessionInfoLoading, isFalse);
    expect(controller.sessionInfo?.displayFields.single.value, 'West');
  });

  testWidgets('cashier session card shows an empty state without details', (
    tester,
  ) async {
    final controller = await createController(tester);
    await controller.login(username: 'cashier', password: 'test-password');
    await tester.pumpAndSettle();

    expect(find.text('cashier_session_no_details'.tr), findsOneWidget);
  });

  testWidgets('cashier session card shows details and retries after errors', (
    tester,
  ) async {
    repo.infoResponse = const Response(
      statusCode: 200,
      body: {
        'data': {'cashier_name': 'Cashier A'},
      },
    );
    final controller = await createController(tester);
    await controller.login(username: 'cashier', password: 'test-password');
    await tester.pumpAndSettle();

    expect(find.text('Cashier A'), findsOneWidget);

    repo.infoResponse = const Response(statusCode: 500);
    await controller.retrySessionInfo();
    await tester.pumpAndSettle();

    expect(find.text(controller.sessionInfoError!), findsOneWidget);
    expect(find.text('retry'.tr), findsOneWidget);

    repo.infoResponse = const Response(
      statusCode: 200,
      body: {
        'content': {'branch': 'South'},
      },
    );
    await tester.tap(find.text('retry'.tr));
    await tester.pumpAndSettle();

    expect(find.text('South'), findsOneWidget);
    expect(controller.sessionInfoError, isNull);
  });

  testWidgets('cashier session card shows loading indicator while retrying', (
    tester,
  ) async {
    final controller = await createController(tester);
    await controller.login(username: 'cashier', password: 'test-password');
    await tester.pumpAndSettle();

    final completer = Completer<Response>();
    repo.infoCompleter = completer;
    final retry = controller.retrySessionInfo();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const Response(statusCode: 200, body: {'branch': 'West'}),
    );
    await retry;
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('West'), findsOneWidget);
  });

  testWidgets('cashier login screen renders with no optional error message', (
    tester,
  ) async {
    final controller = Get.put(
      CashierAuthController(authRepo: repo),
      permanent: true,
    );

    await tester.pumpWidget(const GetMaterialApp(home: CashierLoginScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.errorMessage, isNull);
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets(
    'expired cashier token is removed without entering customer flow',
    (tester) async {
      repo
        ..cashierToken = 'expired-cashier-token'
        ..activeRole = 'cashier'
        ..infoResponse = const Response(
          statusCode: 401,
          body: {'message': 'expired'},
        );
      final controller = await createController(tester);

      await Future.wait([
        controller.restoreSession(),
        controller.restoreSession(),
      ]);
      await tester.pumpAndSettle();

      expect(repo.infoCallCount, 1);
      expect(repo.cashierToken, isNull);
      expect(repo.customerToken, 'customer-token');
      expect(controller.isSessionReady, isFalse);
      expect(Get.currentRoute, RouteHelper.cashierLogin);
    },
  );

  testWidgets('connection failure keeps cashier token for retry', (
    tester,
  ) async {
    repo
      ..cashierToken = 'cashier-token'
      ..activeRole = 'cashier'
      ..infoResponse = const Response(statusCode: 1);
    final controller = await createController(tester);

    await controller.restoreSession();

    expect(repo.cashierToken, 'cashier-token');
    expect(repo.customerToken, 'customer-token');
    expect(controller.isSessionReady, isFalse);
    expect(Get.currentRoute, RouteHelper.cashierLogin);
  });

  testWidgets('does not restore cashier session when a customer is active', (
    tester,
  ) async {
    repo
      ..cashierToken = 'stale-cashier-token'
      ..customerToken = 'customer-token'
      ..activeRole = 'customer';
    final controller = await createController(tester);

    await controller.restoreSession();
    await tester.pumpAndSettle();

    expect(repo.infoCallCount, 0);
    expect(repo.cashierToken, 'stale-cashier-token');
    expect(controller.isSessionReady, isFalse);
    expect(Get.currentRoute, RouteHelper.cashierLogin);
  });

  testWidgets('role switch invalidates an in-flight cashier restore', (
    tester,
  ) async {
    repo
      ..cashierToken = 'cashier-token'
      ..activeRole = 'cashier';
    final controller = await createController(tester);
    final completer = Completer<Response>();
    repo.infoCompleter = completer;

    final restore = controller.restoreSession();
    await tester.pump();
    await controller.clearSessionForRoleSwitch();
    completer.complete(
      const Response(statusCode: 200, body: {'branch': 'North'}),
    );
    await restore;
    await tester.pumpAndSettle();

    expect(repo.cashierToken, isNull);
    expect(controller.isSessionReady, isFalse);
    expect(Get.currentRoute, RouteHelper.cashierLogin);
  });

  testWidgets('cashier logout clears only cashier session', (tester) async {
    repo.cashierToken = 'cashier-token';
    final controller = await createController(tester);

    await controller.logout();
    await tester.pumpAndSettle();

    expect(repo.cashierToken, isNull);
    expect(repo.customerToken, 'customer-token');
    expect(controller.isSessionReady, isFalse);
    expect(Get.currentRoute, RouteHelper.cashierLogin);
  });

  testWidgets('current shift handles the normal no-open-shift response', (
    tester,
  ) async {
    final controller = await createController(tester);

    await controller.fetchCurrentShift();

    expect(controller.currentShift, isNull);
    expect(controller.shiftError, isNull);
    expect(controller.isShiftLoading, isFalse);
  });

  testWidgets('403 while fetching shift logs the cashier out', (tester) async {
    repo
      ..cashierToken = 'cashier-token'
      ..currentShiftResponse = const Response(statusCode: 403);
    final controller = await createController(tester);

    await controller.fetchCurrentShift();
    Get.closeCurrentSnackbar();
    await tester.pumpAndSettle();

    expect(repo.cashierToken, isNull);
    expect(controller.currentShift, isNull);
    expect(Get.currentRoute, RouteHelper.cashierLogin);
  });

  testWidgets('opening shift sends terminal_number and updates current shift', (
    tester,
  ) async {
    repo.openShiftResponse = const Response(
      statusCode: 200,
      body: {
        'status': true,
        'data': {'shift_number': 'SH-TEST', 'status': 'open'},
      },
    );
    final controller = await createController(tester);

    final success = await controller.openShift(
      terminalNumber: 'MERCH-TEST-01',
      openingBalance: 12,
    );

    expect(success, isTrue);
    expect(repo.openedTerminalNumber, 'MERCH-TEST-01');
    expect(repo.openingBalance, 12);
    expect(controller.currentShift?['shift_number'], 'SH-TEST');
    Get.closeCurrentSnackbar();
    await tester.pumpAndSettle();
  });

  testWidgets('closing shift sends closing balance and clears current shift', (
    tester,
  ) async {
    repo.currentShiftResponse = const Response(
      statusCode: 200,
      body: {
        'data': {'shift_number': 'SH-TEST', 'status': 'open'},
      },
    );
    final controller = await createController(tester);
    await controller.fetchCurrentShift();

    final success = await controller.closeShift(closingBalance: 25);

    expect(success, isTrue);
    expect(repo.closingBalance, 25);
    expect(controller.currentShift, isNull);
    Get.closeCurrentSnackbar();
    await tester.pumpAndSettle();
  });
}

class _FakeCashierAuthRepo implements CashierAuthRepo {
  String? cashierToken;
  String? customerToken;
  String? activeRole;
  int infoCallCount = 0;
  Response loginResponse = const Response(
    statusCode: 200,
    body: {'token': 'cashier-token'},
  );
  Response infoResponse = const Response(statusCode: 200, body: {});
  Response currentShiftResponse = const Response(statusCode: 404);
  Response openShiftResponse = const Response(
    statusCode: 200,
    body: {
      'data': {'shift_number': 'SH-DEFAULT', 'status': 'open'},
    },
  );
  Response closeShiftResponse = const Response(statusCode: 200);
  Completer<Response>? infoCompleter;
  String? openedTerminalNumber;
  double? openingBalance;
  double? closingBalance;

  @override
  Future<void> clearCustomerSession() async {
    customerToken = null;
  }

  @override
  void updateApiClient(String token) {}

  @override
  Future<void> saveActiveRole() async {
    activeRole = 'cashier';
  }

  @override
  Future<bool> canRestoreSession() async =>
      activeRole == null || activeRole == 'cashier';

  @override
  Future<bool> updateFcmToken(String authToken) async => true;

  @override
  Future<Response> getCashierWallets(String token) async =>
      const Response(statusCode: 200, body: {});

  @override
  Future<Response> login({
    required String username,
    required String password,
  }) async {
    return loginResponse;
  }

  @override
  Future<Response> getInfo(String token) async {
    infoCallCount++;
    if (infoCompleter != null) return infoCompleter!.future;
    return infoResponse;
  }

  @override
  Future<Response> getCurrentShift() async => currentShiftResponse;

  @override
  Future<Response> openShift({
    required String terminalNumber,
    required double openingBalance,
  }) async {
    openedTerminalNumber = terminalNumber;
    this.openingBalance = openingBalance;
    return openShiftResponse;
  }

  @override
  Future<Response> closeShift({required double closingBalance}) async {
    this.closingBalance = closingBalance;
    return closeShiftResponse;
  }

  @override
  Future<String?> getToken() async => cashierToken;

  @override
  Future<void> saveToken(String token) async {
    cashierToken = token;
  }

  @override
  Future<void> removeToken() async {
    cashierToken = null;
    if (activeRole == 'cashier') activeRole = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
