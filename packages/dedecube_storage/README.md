# Dedecube Storage

Dedecube Storage is a package designed to manage application data storage efficiently. It provides a flexible and scalable solution for handling local and secure storage. With seamless integration and a clean architecture approach, it simplifies data persistence and retrieval, ensuring reliability and performance.

## **Installation**

Add `dedecube_storage` to your dependencies in `pubspec.yaml`:  

```yaml
dependencies:
  dedecube_storage:
    git:
      url: git@github.com:dedecube/dedecube-storage.git
      ref: v0.0.17
```

## **How to Use**

### **Supported Types**

The storage system supports the following data types:

- `String`: Text values
- `int`: Integer numbers
- `double`: Decimal numbers  
- `bool`: Boolean values (true/false)
- `List`: Lists of values represented as `Map<String, dynamic>` 
- `Map`: Objects represented as `Map<String, dynamic>`  

### **Creating a Custom Storable Class**

To create a class that handles specific stored values, simply extend the abstract class `Storable<T>` and specify:  

- The **key** associated with the data.  
- The **storage type** (simple or secure).  

**Example:**

```dart
import 'package:dedecube_storage/dedecube_storage.dart';

class BiometricAuthEnabledStorable extends Storable<bool> {
  BiometricAuthEnabledStorable();

  @override
  String get key => 'biometric_auth_enabled';

  @override
  StorageType get storageType => StorageType.secure;
}
```

---

### **Saving and Retrieving Values**

#### **Boolean**

```dart
final biometricAuth = BiometricAuthEnabledStorable();

// Save a value
await biometricAuth.set(true);

// Retrieve a value with default
bool isEnabled = await biometricAuth.get(defaultValue: false);

// Retrieve an optional value
bool? isEnabledOptional = await biometricAuth.tryGet();
```

## **License**

Dedecube Storage is released under the [MIT License](LICENSE).
