// lib/utils/validators.dart

class Validators {
  /// Validate Australian Business Number (ABN) - Modulus 89 Algorithm
  static String? validateABN(String? value) {
    if (value == null || value.isEmpty) return "ABN is required";

    // Remove spaces/hyphens
    String abn = value.replaceAll(RegExp(r'\D'), '');

    if (abn.length != 11) return "ABN must be 11 digits";

    final weights = [10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19];
    int sum = 0;

    for (int i = 0; i < 11; i++) {
      int digit = int.parse(abn[i]);
      // Step 1: Subtract 1 from the first digit
      if (i == 0) {
        digit -= 1;
      }
      // Step 2: Multiply by weight
      sum += digit * weights[i];
    }

    // Step 3: Verify Modulus 89
    if (sum % 89 != 0) {
      return "Invalid ABN (Checksum failed)";
    }

    return null; // Valid
  }

  /// Validate Tax File Number (TFN) - Modulus 11 Algorithm
  static String? validateTFN(String? value) {
    if (value == null || value.isEmpty) return "TFN is required";
    String tfn = value.replaceAll(RegExp(r'\D'), '');

    if (tfn.length != 9) return "TFN must be 9 digits";

    final weights = [1, 4, 3, 7, 5, 8, 6, 9, 10];
    int sum = 0;

    for (int i = 0; i < 9; i++) {
      sum += int.parse(tfn[i]) * weights[i];
    }

    if (sum % 11 != 0) {
      return "Invalid TFN format";
    }
    return null;
  }

  /// Validate BSB (Bank State Branch)
  static String? validateBSB(String? value) {
    if (value == null || value.isEmpty) return "BSB is required";
    String bsb = value.replaceAll(RegExp(r'\D'), '');
    if (bsb.length != 6) return "BSB must be 6 digits";
    return null;
  }

  /// Validate Account Number
  static String? validateAccountNum(String? value) {
    if (value == null || value.isEmpty) return "Account Number is required";
    String acc = value.replaceAll(RegExp(r'\D'), '');
    if (acc.length < 6 || acc.length > 10) return "Must be 6-10 digits";
    return null;
  }
}
