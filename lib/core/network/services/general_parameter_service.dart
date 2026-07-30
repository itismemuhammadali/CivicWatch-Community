import 'package:cctv_app/core/network/models/general_parameter_option.dart';
import 'package:cctv_app/core/firebase/firestore_service.dart';

class GeneralParameterService {
  const GeneralParameterService();

  Future<List<GeneralParameterOption>> getByHeaderName({
    required String headerName,
    required String accessToken,
  }) async {
    return FirestoreDataService().getParametersByHeader(headerName);
  }
}
