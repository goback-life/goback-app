import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_environment/src/data/exceptions/environment_file_load_exception.dart';
import 'package:dedecube_environment/src/domain/contracts/environment_service_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentService implements EnvironmentServiceContract {
  EnvironmentService(
    Ref ref,
  );

  @override
  Future<void> initialize({String filename = '.env'}) async {
    try {
      await dotenv.load(fileName: filename);
    } catch (e) {
      throw EnvironmentFileLoadException(filename);
    }
  }

  @override
  String? envString(String key, [String? defaultValue]) {
    return _getEnv<String>(key, dotenv.get, defaultValue);
  }

  @override
  int? envInt(String key, [int? defaultValue]) {
    return _getEnv<int>(key, dotenv.getInt, defaultValue);
  }

  @override
  double? envDouble(String key, [double? defaultValue]) {
    return _getEnv<double>(key, dotenv.getDouble, defaultValue);
  }

  @override
  bool? envBool(String key, [bool? defaultValue]) {
    return _getEnv<bool>(key, dotenv.getBool, defaultValue);
  }

  T? _getEnv<T>(
    String key,
    T Function(String key, {T? fallback}) getter, [
    T? defaultValue,
  ]) {
    try {
      if (_keyExists(key)) {
        return getter(key, fallback: defaultValue);
      }
    } on FormatException catch (e) {
      debugPrint('Error retrieving value for key $key: $e');
      return defaultValue;
    }

    debugPrint('Key $key not found. Returning default value: $defaultValue');
    return defaultValue;
  }

  bool _keyExists(String key) {
    return dotenv.env.containsKey(key);
  }
}
