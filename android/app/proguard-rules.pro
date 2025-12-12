# Keep OkHttp classes for image_cropper/uCrop
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Keep uCrop classes
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Keep image_cropper related classes
-keep class id.flutter.plugins.imagecropper.** { *; }