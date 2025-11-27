import '../models/emergency_contact_model.dart';
import '../utils/util.dart';

extension EmergencyContactModelUI on EmergencyContactModel {
  String get nameUI => capitalizeWords(name);
  String get relationshipUI => capitalizeWords(relationship);

  String get phoneNumberUI {
    if (phoneNumber.startsWith("+62")) {
      return "(+62) ${phoneNumber.substring(3)}";
    }
    return phoneNumber;
  }
}
