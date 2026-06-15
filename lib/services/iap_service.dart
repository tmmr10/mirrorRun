import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IapService {
  static const String removeAdsId = 'remove_ads';
  static const String customSkinCreatorId = 'custom_skin_creator';
  static const String mirrorRunnersProId = 'mirror_runners_pro';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _proProduct;
  void Function(String productId, bool success, bool wasRestored)? onPurchaseResult;

  /// Localized store price for the Pro product (e.g. "$2.99", "2,99 €"),
  /// or null if products haven't loaded yet.
  String? get proPrice => _proProduct?.price;
  bool get proAvailable => _proProduct != null;

  Future<void> init() async {
    final available = await _iap.isAvailable();
    debugPrint('>>> IAP available: $available');
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdate);

    final response = await _iap.queryProductDetails(
      {removeAdsId, customSkinCreatorId, mirrorRunnersProId},
    );
    debugPrint('>>> IAP products found: ${response.productDetails.length}');
    debugPrint('>>> IAP not found IDs: ${response.notFoundIDs}');
    for (final product in response.productDetails) {
      debugPrint('>>> IAP product loaded: ${product.id} - ${product.price}');
      if (product.id == mirrorRunnersProId) {
        _proProduct = product;
      }
    }
  }

  Future<bool> buyPro() async {
    debugPrint('>>> IAP buyPro called, product=${_proProduct?.id}');
    if (_proProduct == null) return false;
    final param = PurchaseParam(productDetails: _proProduct!);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        // Still in progress (e.g. awaiting payment) — wait for a terminal state.
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final wasRestored = purchase.status == PurchaseStatus.restored;
        onPurchaseResult?.call(purchase.productID, true, wasRestored);
      } else if (purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled) {
        // Both must release any "loading" UI; canceled previously fell through.
        onPurchaseResult?.call(purchase.productID, false, false);
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase).catchError((e) {
          debugPrint('>>> completePurchase failed: $e');
        });
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
