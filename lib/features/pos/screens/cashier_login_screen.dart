import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/auth/controllers/auth_controller.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/helper/route_helper.dart';

class CashierLoginScreen extends StatefulWidget {
  const CashierLoginScreen({super.key});

  @override
  State<CashierLoginScreen> createState() => _CashierLoginScreenState();
}

class _CashierLoginScreenState extends State<CashierLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await Get.find<CashierAuthController>().authRepo.clearCustomerSession();
        Get.find<CashierAuthController>().restoreSession();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('cashier_login'.tr)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GetBuilder<CashierAuthController>(
                builder: (controller) {
                  final errorMessage = controller.errorMessage;
                  return AbsorbPointer(
                    absorbing: controller.isLoading,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(
                            labelText: 'cashier_username'.tr,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _submit(controller),
                          decoration: InputDecoration(
                            labelText: 'cashier_password'.tr,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _showPassword
                                  ? 'hide_password'.tr
                                  : 'show_password'.tr,
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            errorMessage,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: controller.isLoading
                              ? null
                              : () => _submit(controller),
                          child: controller.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('login'.tr),
                        ),
                        TextButton(
                          onPressed: controller.isLoading
                              ? null
                              : _openCustomerLogin,
                          child: Text('customer_login'.tr),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(CashierAuthController controller) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      Get.snackbar('cashier_login'.tr, 'cashier_login_failed'.tr);
      return;
    }
    await controller.login(username: username, password: password);
  }

  void _openCustomerLogin() {
    Get.find<CashierAuthController>().deactivateSession();
    final customer = Get.find<AuthController>().getUserData();
    Get.offAllNamed(
      RouteHelper.getLoginRoute(
        countryCode: customer?.countryCode,
        phoneNumber: customer?.phone,
      ),
    );
  }
}
