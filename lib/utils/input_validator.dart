/// Kelas utilitas untuk validasi input di form.
///
/// Digunakan untuk memvalidasi input kosong, format email,
/// dan panjang karakter minimum.
///
/// Semua metode mengembalikan pesan error (String) jika tidak valid,
/// atau `null` jika valid.
class InputValidator {
  const InputValidator._();

  // Regex email standar (bisa di-reuse)
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Validasi apakah [value] kosong/null.
  ///
  /// - [field]: Nama field untuk pesan error.
  ///
  /// Return pesan error jika kosong/null, selain itu `null`.
  static String? _isEmpty(String? value, String field) {
    if (value == null || value.isEmpty) {
      return "$field tidak boleh kosong!";
    }
    return null;
  }

  /// Validasi apakah field kosong.
  static String? emptyField(String? value, String field) {
    return _isEmpty(value, field);
  }

  /// Validasi khusus untuk email.
  ///
  /// Aturan:
  /// - Tidak boleh kosong.
  /// - Harus sesuai format email.
  static String? email(String? value) {
    final emptyCheck = _isEmpty(value, "Email");
    if (emptyCheck != null) return emptyCheck;

    if (!_emailRegex.hasMatch(value!)) {
      return "Format email tidak valid!";
    }
    return null;
  }

  /// Validasi apakah field kosong atau kurang dari panjang minimal.
  ///
  /// - [length]: Panjang karakter minimal yang dibutuhkan.
  static String? minLength(String? value, String field, int length) {
    final emptyCheck = _isEmpty(value, field);
    if (emptyCheck != null) return emptyCheck;

    if (value!.length < length) {
      return "$field harus memiliki minimal $length karakter!";
    }
    return null;
  }

  /// Validasi khusus nomor telepon Indonesia.
  ///
  /// Aturan:
  /// - Tidak boleh kosong.
  /// - Harus diawali dengan "08".
  /// - Minimal panjang 9 karakter.
  static String? phoneNumber(String? value) {
    final emptyCheck = _isEmpty(value, "Nomor telepon");
    if (emptyCheck != null) return emptyCheck;
    final trimValue = value!.trim().toLowerCase();

    if (!trimValue.startsWith("08") && !trimValue.startsWith("+62")) {
      return "Nomor telepon harus diawali dengan 08 atau +62";
    }

    if (trimValue.length < 9) {
      return "Nomor telepon minimal 9 digit!";
    }

    return null;
  }
}
