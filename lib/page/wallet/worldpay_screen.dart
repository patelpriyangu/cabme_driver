import 'dart:convert';
import 'dart:developer';

import 'package:uniqcars_driver/constant/logdata.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/themes/app_them_data.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class WorldpayScreen extends StatefulWidget {
  final String checkoutId;
  final String amount;
  final String currency;
  final bool isSandbox;

  const WorldpayScreen({
    super.key,
    required this.checkoutId,
    required this.amount,
    required this.currency,
    required this.isSandbox,
  });

  @override
  State<WorldpayScreen> createState() => _WorldpayScreenState();
}

class _WorldpayScreenState extends State<WorldpayScreen> {
  WebViewController controller = WebViewController();
  bool isLoading = true;
  bool isProcessing = false;

  // Map currency symbols to ISO 4217 codes for Worldpay API
  static const _currencySymbolToCode = {
    '£': 'GBP', '\$': 'USD', '€': 'EUR', '¥': 'JPY', '₹': 'INR',
    '₦': 'NGN', 'R': 'ZAR', 'A\$': 'AUD', 'C\$': 'CAD', '₺': 'TRY',
    '₽': 'RUB', '﷼': 'SAR', 'د.إ': 'AED', 'RM': 'MYR', '₱': 'PHP',
    'Ksh': 'KES', 'GH₵': 'GHS', 'Fr': 'XOF', 'FCFA': 'XAF',
  };

  String get _currencyCode {
    final input = widget.currency.trim();
    if (RegExp(r'^[A-Z]{3}$').hasMatch(input)) return input;
    return _currencySymbolToCode[input] ?? 'GBP';
  }

  @override
  void initState() {
    super.initState();
    initController();
  }

  String _buildCheckoutHtml() {
    final sdkBaseUrl = widget.isSandbox
        ? 'https://try.access.worldpay.com'
        : 'https://access.worldpay.com';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Worldpay Payment</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #f5f5f5;
      padding: 20px;
    }
    .container {
      max-width: 400px;
      margin: 0 auto;
      background: #fff;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    h2 {
      text-align: center;
      color: #1b1b6f;
      margin-bottom: 24px;
      font-size: 20px;
    }
    .form-group {
      margin-bottom: 16px;
    }
    label {
      display: block;
      font-size: 14px;
      font-weight: 600;
      color: #333;
      margin-bottom: 6px;
    }
    .field-container {
      border: 1px solid #ddd;
      border-radius: 8px;
      padding: 0;
      background: #fafafa;
      height: 48px;
      position: relative;
      overflow: hidden;
    }
    .field-container iframe {
      width: 100% !important;
      height: 100% !important;
      border: none !important;
    }
    .field-container.focused {
      border-color: #1b1b6f;
      box-shadow: 0 0 0 2px rgba(27,27,111,0.1);
    }
    .field-container.valid {
      border-color: #4caf50;
    }
    .field-container.invalid {
      border-color: #f44336;
    }
    .row {
      display: flex;
      gap: 12px;
      width: 100%;
    }
    .row .form-group {
      flex: 1;
      min-width: 0;
    }
    #pay-btn {
      width: 100%;
      padding: 14px;
      background: #1b1b6f;
      color: #fff;
      border: none;
      border-radius: 8px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      margin-top: 8px;
    }
    #pay-btn:disabled {
      background: #ccc;
      cursor: not-allowed;
    }
    #pay-btn:hover:not(:disabled) {
      background: #2a2a8f;
    }
    .error-msg {
      color: #f44336;
      font-size: 13px;
      margin-top: 8px;
      text-align: center;
      display: none;
    }
    .processing {
      text-align: center;
      color: #666;
      font-size: 14px;
      margin-top: 8px;
    }
    .amount-display {
      text-align: center;
      font-size: 28px;
      font-weight: 700;
      color: #1b1b6f;
      margin-bottom: 24px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h2>Worldpay Payment</h2>
    <div class="amount-display">${widget.currency} ${widget.amount}</div>
    <form id="card-form">
      <div class="form-group">
        <label>Card Number</label>
        <div class="field-container" id="card-pan"></div>
      </div>
      <div class="row">
        <div class="form-group">
          <label>Expiry Date</label>
          <div class="field-container" id="card-expiry"></div>
        </div>
        <div class="form-group">
          <label>CVV</label>
          <div class="field-container" id="card-cvv"></div>
        </div>
      </div>
      <button type="submit" id="pay-btn" disabled>Pay Now</button>
      <div class="error-msg" id="error-msg"></div>
      <div class="processing" id="processing" style="display:none;">Processing payment...</div>
    </form>
  </div>

  <script src="$sdkBaseUrl/access-checkout/v2/checkout.js"></script>
  <script>
    (function() {
      var form = document.getElementById('card-form');
      var payBtn = document.getElementById('pay-btn');
      var errorMsg = document.getElementById('error-msg');
      var processing = document.getElementById('processing');
      var checkoutId = '${widget.checkoutId}';

      var styles = {
        "default": {
          "color": "#333",
          "font-size": "16px"
        },
        "valid": {
          "color": "#4caf50"
        },
        "invalid": {
          "color": "#f44336"
        }
      };

      var accessibility = {
        ariaLabel: {
          cardNumber: "Card number",
          expiryDate: "Expiry date",
          cvc: "CVC"
        },
        title: {
          cardNumber: "Card number",
          expiryDate: "Expiry date in format MM/YY",
          cvc: "CVC"
        },
        lang: "en-GB"
      };

      var acceptedCardBrands = ["amex", "diners", "discover", "jcb", "maestro", "mastercard", "visa"];

      Worldpay.checkout.init(
        {
          id: checkoutId,
          form: "#card-form",
          fields: {
            pan: {
              selector: "#card-pan",
              placeholder: "4444 3333 2222 1111"
            },
            expiry: {
              selector: "#card-expiry",
              placeholder: "MM/YY"
            },
            cvv: {
              selector: "#card-cvv",
              placeholder: "123"
            }
          },
          styles: styles,
          accessibility: accessibility,
          acceptedCardBrands: acceptedCardBrands,
          enablePanFormatting: true
        },
        function (error, checkout) {
          if (error) {
            flutterJSChannel.postMessage(JSON.stringify({type: 'error', message: error.message || 'Initialization failed'}));
            return;
          }

          payBtn.disabled = false;

          form.addEventListener('submit', function (event) {
            event.preventDefault();
            payBtn.disabled = true;
            errorMsg.style.display = 'none';
            processing.style.display = 'block';

            checkout.generateSessions(function (error, sessions) {
              if (error) {
                payBtn.disabled = false;
                processing.style.display = 'none';
                errorMsg.textContent = error.message || 'Failed to process card details';
                errorMsg.style.display = 'block';
                return;
              }

              flutterJSChannel.postMessage(JSON.stringify({
                type: 'session',
                sessionHref: sessions.card
              }));
            });
          });
        }
      );
    })();
  </script>
</body>
</html>
''';
  }

  void initController() {
    final html = _buildCheckoutHtml();
    final sdkBaseUrl = widget.isSandbox
        ? 'https://try.access.worldpay.com'
        : 'https://access.worldpay.com';

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'flutterJSChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJSMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: ((url) {
            setState(() {
              isLoading = false;
            });
          }),
          onNavigationRequest: (NavigationRequest navigation) async {
            log("Worldpay URL :: ${navigation.url}");
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(html, baseUrl: sdkBaseUrl);
  }

  Future<void> _handleJSMessage(String message) async {
    try {
      final data = jsonDecode(message);
      if (data['type'] == 'session') {
        final sessionHref = data['sessionHref'];
        showLog("Worldpay Session :: $sessionHref");
        await _authorizePayment(sessionHref);
      } else if (data['type'] == 'error') {
        showLog("Worldpay Error :: ${data['message']}");
        Get.back(result: false);
      }
    } catch (e) {
      showLog("Worldpay JS Parse Error :: $e");
      Get.back(result: false);
    }
  }

  Future<void> _authorizePayment(String sessionHref) async {
    if (isProcessing) return;
    setState(() {
      isProcessing = true;
    });

    try {
      final transactionRef = 'UNIQ-${DateTime.now().millisecondsSinceEpoch}';
      final bodyParams = {
        'sessionHref': sessionHref,
        'amount': double.parse(widget.amount),
        'currency': _currencyCode,
        'transactionReference': transactionRef,
      };

      showLog("Worldpay Auth Request :: URL: ${API.worldpayAuthorize}");
      showLog("Worldpay Auth Request :: Body: ${jsonEncode(bodyParams)}");

      final response = await http.post(
        Uri.parse(API.worldpayAuthorize),
        headers: API.headers,
        body: jsonEncode(bodyParams),
      );

      showLog("Worldpay Auth Response :: Status: ${response.statusCode}");
      showLog("Worldpay Auth Response :: Body: ${response.body}");

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        Get.back(result: true);
      } else {
        final errorMsg = responseData['error'] ?? 'Payment failed (${response.statusCode})';
        showLog("Worldpay Payment Failed :: $errorMsg");
        _showErrorAndGoBack(errorMsg);
      }
    } catch (e) {
      showLog("Worldpay Auth Error :: $e");
      _showErrorAndGoBack("Connection error: $e");
    }
  }

  void _showErrorAndGoBack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    Future.delayed(const Duration(seconds: 2), () {
      Get.back(result: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showMyDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppThemeData.primaryDefault,
          centerTitle: false,
          title: Text(
            'Worldpay Payment',
            style: TextStyle(color: Colors.white),
          ),
          leading: GestureDetector(
            onTap: () {
              _showMyDialog();
            },
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            WebViewWidget(controller: controller),
            Visibility(
              visible: isLoading,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Payment'.tr),
          content: SingleChildScrollView(
            child: Text("cancelPayment?".tr),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel'.tr,
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Get.back();
                Get.back(result: false);
              },
            ),
            TextButton(
              child: Text(
                'Continue'.tr,
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }
}
