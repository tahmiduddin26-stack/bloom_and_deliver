import '../models/flower.dart';

/// Wholesale is a planning choice: small enough not to replace the market.
const wholesaleUnlockDay = 3;
const wholesalePackSize = 5;
const wholesaleMaxPacksPerDay = 4;

int wholesaleUnitPrice(Flower flower) =>
    (flower.cost * 0.7).round().clamp(1, flower.cost - 1);

int wholesalePackPrice(Flower flower) =>
    wholesaleUnitPrice(flower) * wholesalePackSize;

int wholesalePendingStems(Map<String, int> pending) =>
    pending.values.fold(0, (total, qty) => total + qty);
