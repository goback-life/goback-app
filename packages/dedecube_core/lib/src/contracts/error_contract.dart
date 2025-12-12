abstract interface class ErrorContract {
  String getMessage();

  String getCode();

  bool isRecoverable();
}
