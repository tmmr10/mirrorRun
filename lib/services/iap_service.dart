import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IapService {
  static const String removeAdsId = 'remove_ads';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _removeAdsProduct;
  void Function(bool success)? onPurchaseResult;

  Future<void> init() async {
    final available = await _iap.isAvailable();
    debugPrint('>>> IAP available: $available');
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdate);

    final response = await _iap.queryProductDetails({removeAdsId});
    debugPrint('>>> IAP products found: ${response.productDetails.length}');
    debugPrint('>>> IAP not found IDs: ${response.notFoundIDs}');
    if (response.productDetails.isNotEmpty) {
      _removeAdsProduct = response.productDetails.first;
      debugPrint('>>> IAP product loaded: ${_removeAdsProduct!.id} - ${_removeAdsProduct!.price}');
    }
  }

  Future<bool> buyRemoveAds() async {
    debugPrint('>>> IAP buyRemoveAds called, product=${_removeAdsProduct?.id}');
    if (_removeAdsProduct == null) return false;
    final param = PurchaseParam(productDetails: _removeAdsProduct!);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID == removeAdsId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          onPurchaseResult?.call(true);
        } else if (purchase.status == PurchaseStatus.error) {
          onPurchaseResult?.call(false);
        }
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
