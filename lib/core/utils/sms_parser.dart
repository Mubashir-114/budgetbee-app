import 'dart:convert';
import 'package:crypto/crypto.dart';

class ParsedSmsTransaction {
  final double amount;
  final String type; // "income" | "expense"
  final String merchant;
  final String bank;
  final DateTime date;
  final String? referenceNumber;
  final String smsHash;
  final String messageBody;
  final String sender;
  final String category;

  ParsedSmsTransaction({
    required this.amount,
    required this.type,
    required this.merchant,
    required this.bank,
    required this.date,
    this.referenceNumber,
    required this.smsHash,
    required this.messageBody,
    required this.sender,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'type': type,
      'merchant': merchant,
      'bank': bank,
      'date': date.toIso8601String(),
      'reference': referenceNumber,
      'sms_hash': smsHash,
      'message': messageBody,
      'sender': sender,
      'category': category,
    };
  }

  factory ParsedSmsTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedSmsTransaction(
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      merchant: json['merchant'] as String,
      bank: json['bank'] as String,
      date: DateTime.parse(json['date'] as String),
      referenceNumber: json['reference'] as String?,
      smsHash: json['sms_hash'] as String,
      messageBody: json['message'] as String,
      sender: json['sender'] as String,
      category: json['category'] as String,
    );
  }
}

class SmsParser {
  // Regex to extract amount. Supports e.g. Rs 500, Rs. 500, INR 1,500.00
  static final RegExp _amountRegex = RegExp(
    r'(?:Rs\.?|INR)\s*([0-9,]+(?:\.[0-9]+)?)',
    caseSensitive: false,
  );

  // Regex to extract reference/transaction ID (UPI, UTR, Ref, Txn ID)
  static final RegExp _refRegex = RegExp(
    r'(?:Ref(?:\s*No)?\.?\s*|UPI\s*ref(?:\s*no)?\s*|UTR\s*|Txn\s*ID\s*|Ref\s*:?\s*)([0-9a-zA-Z]+)',
    caseSensitive: false,
  );

  // Keywords indicating debit (expense)
  static final List<String> _debitKeywords = [
    'debited', 'transferred', 'paid', 'spent', 'withdrawn', 'withdrawal', 'sent', 'spent at', 'card purchase', 'payment successful'
  ];

  // Keywords indicating credit (income)
  static final List<String> _creditKeywords = [
    'credited', 'received', 'deposited', 'added', 'salary'
  ];

  /// Generates a unique SHA-256 hash for duplicate detection
  static String generateSmsHash(String sender, int timestampMs, String body) {
    final input = "${sender.trim()}_${timestampMs}_${body.trim()}";
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Parses a raw SMS into a ParsedSmsTransaction if it is a transaction message.
  /// Returns null if the SMS is not recognized as a transaction.
  static ParsedSmsTransaction? parseSms({
    required String sender,
    required String body,
    required DateTime date,
  }) {
    final bodyLower = body.toLowerCase();
    
    // 1. Basic check: Does it look like a transaction SMS?
    // It must contain currency keywords (Rs, INR) AND action keywords (debited, credited, transferred, received, etc.)
    final hasAmountMarker = bodyLower.contains('rs') || bodyLower.contains('inr');
    if (!hasAmountMarker) return null;

    final isDebit = _debitKeywords.any((kw) => bodyLower.contains(kw));
    final isCredit = _creditKeywords.any((kw) => bodyLower.contains(kw));

    if (!isDebit && !isCredit) return null;

    // 2. Extract Amount
    final amountMatch = _amountRegex.firstMatch(body);
    if (amountMatch == null) return null;

    final rawAmount = amountMatch.group(1)?.replaceAll(',', '');
    if (rawAmount == null) return null;
    
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) return null;

    // 3. Extract Type
    // If a message contains both, prioritize debit (typical for bank notifications detailing a transfer)
    final type = isDebit ? "expense" : "income";

    // 4. Extract Merchant
    final merchant = parseMerchant(body, type);

    // 5. Extract Bank
    final bank = parseBank(sender, body);

    // 6. Extract Reference
    final refMatch = _refRegex.firstMatch(body);
    final reference = refMatch?.group(1)?.trim();

    // 7. Generate Hash
    final smsHash = generateSmsHash(sender, date.millisecondsSinceEpoch, body);

    // 8. Categorize
    final category = detectCategory(merchant, body);

    return ParsedSmsTransaction(
      amount: amount,
      type: type,
      merchant: merchant,
      bank: bank,
      date: date,
      referenceNumber: reference,
      smsHash: smsHash,
      messageBody: body,
      sender: sender,
      category: category,
    );
  }

  /// Extracts the merchant name from the SMS body using prefix context or fallback search
  static String parseMerchant(String body, String type) {
    final bodyLower = body.toLowerCase();
    
    // 1. Check known popular merchants first (highest accuracy)
    final commonMerchants = ['swiggy', 'zomato', 'uber', 'ola', 'amazon', 'flipkart', 'netflix', 'spotify', 'swyft'];
    for (final m in commonMerchants) {
      if (bodyLower.contains(m)) {
        return m[0].toUpperCase() + m.substring(1);
      }
    }

    // 2. Regular expressions looking for merchant name suffixes
    final merchantRegexes = [
      RegExp(r'(?:spent\s+at|at|paid\s+to|transfer\s+to|sent\s+to|to|by|info\s+at)\s+([a-zA-Z0-9\s\.\-_]+?)(?:\s+on|\s+via|\s+ref|\s+using|\s+balance|\s+from|\s+date|\s+limit|\.|\s*$)', caseSensitive: false),
    ];

    for (final regex in merchantRegexes) {
      final match = regex.firstMatch(body);
      if (match != null) {
        final rawMerchant = match.group(1)?.trim();
        if (rawMerchant != null && rawMerchant.isNotEmpty) {
          final cleanMerchant = _cleanMerchant(rawMerchant);
          if (cleanMerchant.isNotEmpty && 
              cleanMerchant.toLowerCase() != 'upi' && 
              cleanMerchant.toLowerCase() != 'imps' &&
              cleanMerchant.toLowerCase() != 'your' &&
              cleanMerchant.toLowerCase() != 'your account') {
            return cleanMerchant;
          }
        }
      }
    }

    return type == 'income' ? 'Income Deposit' : 'Merchant Spend';
  }

  static String _cleanMerchant(String merchant) {
    String result = merchant;
    // Strip trailing account information, txn keywords, or system text
    final noisePatterns = [
      RegExp(r'\b(?:a/c|account|ending|card|ref|upi|imps|neft|via|on|at|using|balance|credited|debited|is|successful|completed|for|rs|inr)\b.*$', caseSensitive: false),
      RegExp(r'\d+$'), // Trailing digits (often account suffix or date digits)
    ];
    for (final noise in noisePatterns) {
      result = result.replaceFirst(noise, '');
    }
    
    result = result.replaceAll(RegExp(r'[^\w\s\.-]'), '').trim();
    
    if (result.length > 50) {
      result = result.substring(0, 50).trim();
    }
    return result;
  }

  /// Extracts bank from sender code or message body (e.g., AD-HDFCBK -> HDFC)
  static String parseBank(String sender, String body) {
    final senderUpper = sender.toUpperCase();
    if (senderUpper.contains('-')) {
      final parts = senderUpper.split('-');
      if (parts.length > 1) {
        final possibleBank = parts[1];
        if (possibleBank.length >= 3) {
          return possibleBank;
        }
      }
    }
    
    // Check body for common banks
    final commonBanks = ['HDFC', 'SBI', 'ICICI', 'AXIS', 'KOTAK', 'CITI', 'BOB', 'PNB', 'YESB', 'IDBI', 'HSBC', 'RBL'];
    final bodyUpper = body.toUpperCase();
    for (final bank in commonBanks) {
      if (bodyUpper.contains(bank)) {
        return bank;
      }
    }

    return sender;
  }

  /// Map transaction data to BudgetBee categories
  static String detectCategory(String merchant, String body) {
    final merchantLower = merchant.toLowerCase();
    final bodyLower = body.toLowerCase();

    // Swiggy, Zomato, Restaurant -> Food
    if (merchantLower.contains('swiggy') || 
        merchantLower.contains('zomato') || 
        merchantLower.contains('food') || 
        merchantLower.contains('eat') ||
        merchantLower.contains('restaurant') || 
        bodyLower.contains('swiggy') || 
        bodyLower.contains('zomato')) {
      return 'Food';
    }
    
    // Uber, Ola, Metro, Cabs -> Transport
    if (merchantLower.contains('uber') || 
        merchantLower.contains('ola') || 
        merchantLower.contains('metro') || 
        merchantLower.contains('irctc') || 
        merchantLower.contains('cab') || 
        merchantLower.contains('auto') || 
        merchantLower.contains('rail') || 
        merchantLower.contains('train') || 
        bodyLower.contains('uber') || 
        bodyLower.contains('ola')) {
      return 'Transport';
    }

    // Amazon, Flipkart, Shopping -> Shopping
    if (merchantLower.contains('amazon') || 
        merchantLower.contains('flipkart') || 
        merchantLower.contains('myntra') || 
        merchantLower.contains('shopping') || 
        merchantLower.contains('groceries') || 
        merchantLower.contains('supermarket') || 
        merchantLower.contains('mart') || 
        bodyLower.contains('amazon') || 
        bodyLower.contains('flipkart') || 
        bodyLower.contains('grocery')) {
      return 'Shopping';
    }

    // Netflix, Spotify, Entertainment -> Entertainment
    if (merchantLower.contains('netflix') || 
        merchantLower.contains('spotify') || 
        merchantLower.contains('hotstar') || 
        merchantLower.contains('youtube') || 
        merchantLower.contains('prime') || 
        merchantLower.contains('cinema') || 
        merchantLower.contains('movie') || 
        merchantLower.contains('entertainment')) {
      return 'Entertainment';
    }

    // Hospital, Medical, Doctor -> Medical
    if (merchantLower.contains('hospital') || 
        merchantLower.contains('pharmacy') || 
        merchantLower.contains('medical') || 
        merchantLower.contains('doctor') || 
        merchantLower.contains('clinic') || 
        merchantLower.contains('chemist') || 
        bodyLower.contains('hospital') || 
        bodyLower.contains('medical') ||
        bodyLower.contains('chemist')) {
      return 'Medical';
    }

    // Recharge, Telecom -> Bills
    if (merchantLower.contains('recharge') || 
        merchantLower.contains('jio') || 
        merchantLower.contains('airtel') || 
        merchantLower.contains('vi ') || 
        merchantLower.contains('telecom') || 
        bodyLower.contains('recharge') || 
        bodyLower.contains('bill') ||
        bodyLower.contains('electricity') ||
        bodyLower.contains('gas')) {
      return 'Bills';
    }

    // Salary, Employer -> Salary
    if (bodyLower.contains('salary') || 
        merchantLower.contains('salary') || 
        bodyLower.contains('employer') || 
        bodyLower.contains('payroll')) {
      return 'Salary';
    }

    // Rent -> Rent
    if (merchantLower.contains('rent') || bodyLower.contains('rent paid') || bodyLower.contains('house rent')) {
      return 'Rent';
    }

    // Travel, Flight, Hotel -> Travel
    if (merchantLower.contains('travel') || 
        merchantLower.contains('flight') || 
        merchantLower.contains('hotel') || 
        merchantLower.contains('booking') || 
        merchantLower.contains('trip') ||
        merchantLower.contains('airways')) {
      return 'Travel';
    }

    // Default to 'Other'
    return 'Other';
  }
}
