import 'package:get_storage/get_storage.dart';


final GetStorage _storage = GetStorage();
String getToken() {
  return _storage.read('token')?.toString() ?? '';
}