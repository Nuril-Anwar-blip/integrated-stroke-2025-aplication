import '../models/user_model.dart';
import '../utils/util.dart';

extension UserModelUI on UserModel {
  String get fullNameUI => capitalizeWords(fullName);

  String get medicalHistoryUI =>
      medicalHistory.map((e) => capitalizeWords(e)).join(', ');

  String get drugAllergyUI =>
      drugAllergy.map((e) => capitalizeWords(e)).join(', ');

  String get genderUI => gender == "male" ? "Pria" : "Wanita";

  String get phoneNumberUI {
    if (phoneNumber.startsWith("+62")) {
      return "(+62) ${phoneNumber.substring(3)}";
    }
    return phoneNumber;
  }
}
