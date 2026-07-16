import 'package:shared_preferences/shared_preferences.dart';

abstract class SharedPreferencesService {
  Future<int?> getEmployeeId();
}

class RealSharedPreferencesService implements SharedPreferencesService {
  @override
  Future<int?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('employeeId');
  }
}
