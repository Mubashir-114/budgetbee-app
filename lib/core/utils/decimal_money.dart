/// Exact BigInt minor-unit decimal arithmetic utilities.
///
/// Ensures financial operations in Flutter never use IEEE-754 [double].
class DecimalMoney {
  DecimalMoney._();

  static final RegExp _validDecimalPattern = RegExp(r'^-?\d+(\.\d{1,2})?$');

  /// Validates whether [val] is a proper currency decimal string with at most 2 decimal places.
  static bool isValidDecimal(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return false;
    return _validDecimalPattern.hasMatch(trimmed);
  }

  /// Parses a 2-decimal money string into exact minor units (e.g. "12.50" -> 1250n).
  static BigInt parseToMinor(String val) {
    final clean = val.trim();
    if (!isValidDecimal(clean)) {
      throw FormatException('Invalid currency decimal string: "$val"');
    }
    final isNeg = clean.startsWith('-');
    final unsigned = isNeg ? clean.substring(1) : clean;
    final parts = unsigned.split('.');
    final whole = BigInt.parse(parts[0].isEmpty ? '0' : parts[0]);
    var fractionStr = parts.length > 1 ? parts[1] : '';
    if (fractionStr.length > 2) {
      fractionStr = fractionStr.substring(0, 2);
    } else {
      fractionStr = fractionStr.padRight(2, '0');
    }
    final fraction = BigInt.parse(fractionStr.isEmpty ? '0' : fractionStr);
    final minor = whole * BigInt.from(100) + fraction;
    return isNeg ? -minor : minor;
  }

  /// Formats exact minor units into canonical 2-decimal string (e.g. 1250n -> "12.50").
  static String formatMinor(BigInt minor) {
    final isNeg = minor < BigInt.zero;
    final abs = isNeg ? -minor : minor;
    final whole = abs ~/ BigInt.from(100);
    final remainder = abs % BigInt.from(100);
    final fracStr = remainder.toString().padLeft(2, '0');
    return '${isNeg ? '-' : ''}$whole.$fracStr';
  }

  /// Compares two decimal strings: returns 1 if a > b, -1 if a < b, 0 if equal.
  static int compare(String a, String b) {
    final diff = parseToMinor(a) - parseToMinor(b);
    if (diff > BigInt.zero) return 1;
    if (diff < BigInt.zero) return -1;
    return 0;
  }

  /// Adds two decimal strings exactly.
  static String add(String a, String b) {
    return formatMinor(parseToMinor(a) + parseToMinor(b));
  }

  /// Subtracts b from a exactly (a - b).
  static String subtract(String a, String b) {
    return formatMinor(parseToMinor(a) - parseToMinor(b));
  }

  /// Returns true if decimal string is strictly positive (> 0.00).
  static bool isPositive(String a) {
    return parseToMinor(a) > BigInt.zero;
  }
}
