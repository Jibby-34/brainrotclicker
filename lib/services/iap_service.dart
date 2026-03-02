import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

typedef IapPurchaseCallback = void Function(String productId);

class IAPService extends ChangeNotifier {
  // Product IDs — register these in Play Console / App Store Connect
  static const brainsSmall = 'brains_small';
  static const brainsMedium = 'brains_medium';
  static const brainsLarge = 'brains_large';
  static const upgradeSpeedDemon = 'upgrade_speed_demon';
  static const upgradeBrainOverload = 'upgrade_brain_overload';

  static const consumableIds = {brainsSmall, brainsMedium, brainsLarge};
  static const nonConsumableIds = {upgradeSpeedDemon, upgradeBrainOverload};
  static const allProductIds = {
    brainsSmall,
    brainsMedium,
    brainsLarge,
    upgradeSpeedDemon,
    upgradeBrainOverload,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _available = false;
  bool _loading = false;
  Map<String, ProductDetails> _products = {};
  Set<String> _owned = {};
  String? _pendingError;

  bool get available => _available;
  bool get loading => _loading;
  Map<String, ProductDetails> get products => _products;
  Set<String> get ownedNonConsumables => _owned;
  String? get pendingError => _pendingError;

  IapPurchaseCallback? _onSuccess;
  VoidCallback? _onFailed;

  Future<void> initialize({
    required IapPurchaseCallback onSuccess,
    required VoidCallback onFailed,
    required Set<String> alreadyPurchased,
  }) async {
    _onSuccess = onSuccess;
    _onFailed = onFailed;
    _owned = Set.from(alreadyPurchased);

    _available = await _iap.isAvailable();
    if (!_available) {
      notifyListeners();
      return;
    }

    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {
        _onFailed?.call();
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    _loading = true;
    notifyListeners();

    final response = await _iap.queryProductDetails(allProductIds);
    _products = {for (final p in response.productDetails) p.id: p};

    _loading = false;
    notifyListeners();
  }

  Future<void> buy(String productId) async {
    final product = _products[productId];
    if (product == null) return;
    _pendingError = null;

    final param = PurchaseParam(productDetails: product);
    if (consumableIds.contains(productId)) {
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _owned.add(purchase.productID);
          _onSuccess?.call(purchase.productID);
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
          notifyListeners();
        case PurchaseStatus.error:
          _pendingError = purchase.error?.message ?? 'Purchase failed';
          _onFailed?.call();
          notifyListeners();
        case PurchaseStatus.canceled:
          notifyListeners();
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
