class ReceiptModel {
  final String? merchantName;
  final String? invoiceNumber;
  final String? date;
  final String? time;
  final String? gstNumber;
  final String? currency;
  final double? subtotal;
  final double? tax;
  final double? discount;
  final double? total;
  final String? paymentMethod;
  final String? category;
  final String? merchantAddress;
  final String? merchantPhone;
  final List<ReceiptItemModel> items;
  final String? receiptHash;
  final int? fileSize;
  final double? confidenceScore;
  final String? rawText;

  ReceiptModel({
    this.merchantName,
    this.invoiceNumber,
    this.date,
    this.time,
    this.gstNumber,
    this.currency,
    this.subtotal,
    this.tax,
    this.discount,
    this.total,
    this.paymentMethod,
    this.category,
    this.merchantAddress,
    this.merchantPhone,
    required this.items,
    this.receiptHash,
    this.fileSize,
    this.confidenceScore,
    this.rawText,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    // Resolve currency (assume INR by default unless USD or other clearly specified)
    String? resolvedCurrency = json['currency'] as String?;
    if (resolvedCurrency == null || resolvedCurrency.trim().isEmpty) {
      resolvedCurrency = '₹';
    } else {
      final curLower = resolvedCurrency.toLowerCase();
      if (curLower.contains('usd') || resolvedCurrency == '\$') {
        resolvedCurrency = '\$';
      } else if (curLower.contains('inr') || resolvedCurrency == '₹' || curLower.contains('rupee')) {
        resolvedCurrency = '₹';
      }
    }

    return ReceiptModel(
      merchantName: json['merchant_name'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
      gstNumber: json['gst_number'] as String?,
      currency: resolvedCurrency,
      subtotal: parseDouble(json['subtotal']),
      tax: parseDouble(json['tax']),
      discount: parseDouble(json['discount']),
      total: parseDouble(json['total']),
      paymentMethod: json['payment_method'] as String?,
      category: json['category'] as String?,
      merchantAddress: json['merchant_address'] as String?,
      merchantPhone: json['merchant_phone'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ReceiptItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      receiptHash: json['receipt_hash'] as String?,
      fileSize: parseInt(json['file_size']),
      confidenceScore: parseDouble(json['confidence_score']),
      rawText: json['raw_text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_name': merchantName,
      'invoice_number': invoiceNumber,
      'date': date,
      'time': time,
      'gst_number': gstNumber,
      'currency': currency,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'category': category,
      'merchant_address': merchantAddress,
      'merchant_phone': merchantPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'receipt_hash': receiptHash,
      'file_size': fileSize,
      'confidence_score': confidenceScore,
      'raw_text': rawText,
    };
  }

  static double? parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
      // Remove any currency symbol or commas before parsing
      final cleaned = val.replaceAll(RegExp(r'[^\d\.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  static int? parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleaned);
    }
    return null;
  }
}

class ReceiptItemModel {
  final String name;
  final int? quantity;
  final double? unitPrice;
  final double? totalPrice;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final bool? warrantyAvailable;
  final int? warrantyPeriod;
  final String? warrantyUnit;

  ReceiptItemModel({
    required this.name,
    this.quantity,
    this.unitPrice,
    this.totalPrice,
    this.brand,
    this.model,
    this.serialNumber,
    this.warrantyAvailable,
    this.warrantyPeriod,
    this.warrantyUnit,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      name: (json['name'] as String?) ?? 'Unknown Item',
      quantity: parseInt(json['quantity']),
      unitPrice: parseDouble(json['unit_price']),
      totalPrice: parseDouble(json['total_price']),
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serial_number'] as String?,
      warrantyAvailable: json['warranty_available'] as bool?,
      warrantyPeriod: parseInt(json['warranty_period']),
      warrantyUnit: json['warranty_unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'warranty_available': warrantyAvailable,
      'warranty_period': warrantyPeriod,
      'warranty_unit': warrantyUnit,
    };
  }

  static double? parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^\d\.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  static int? parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleaned);
    }
    return null;
  }
}
