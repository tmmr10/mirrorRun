import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IapService {
  static const String removeAdsId = 'remove_ads';
  static const String customSkinCreatorId = 'custom_skin_creator';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _removeAdsProduct;
  ProductDetails? _customSkinCreatorProduct;
  void Function(String productId, bool success)? onPurchaseResult;

  Future<void> init() async {
    final available = await _iap.isAvailable();
    debugPrint('>>> IAP available: $available');
    if (!available) return;

    _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdate);

    final response = await _iap.queryProductDetails({removeAdsId, customSkinCreatorId});
    debugPrint('>>> IAP products found: ${response.productDetails.length}');
    debugPrint('>>> IAP not found IDs: ${response.notFoundIDs}');
    for (final product in response.productDetails) {
      debugPrint('>>> IAP product loaded: ${product.id} - ${product.price}');
      if (product.id == removeAdsId) {
        _removeAdsProduct = product;
      } else if (product.id == customSkinCreatorId) {
        _customSkinCreatorProduct = product;
      }
    }
  }

  Future<bool> buyRemoveAds() async {
    debugPrint('>>> IAP buyRemoveAds called, product=${_removeAdsProduct?.id}');
    if (_removeAdsProduct == null) return false;
    final param = PurchaseParam(productDetails: _removeAdsProduct!);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<bool> buyCustomSkinCreator() async {
    debugPrint('>>> IAP buyCustomSkinCreator called, product=${_customSkinCreatorProduct?.id}');
    if (_customSkinCreatorProduct == null) return false;
    final param = PurchaseParam(productDetails: _customSkinCreatorProduct!);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        onPurchaseResult?.call(purchase.productID, true);
      } else if (purchase.status == PurchaseStatus.error) {
        onPurchaseResult?.call(purchase.productID, false);
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
