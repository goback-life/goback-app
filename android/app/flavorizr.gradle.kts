import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("prestage") {
            dimension = "flavor-type"
            applicationId = "com.dedecube.prestage.cloudless"
            resValue(type = "string", name = "app_name", value = "goback .")
        }
        create("stage") {
            dimension = "flavor-type"
            applicationId = "com.dedecube.stage.cloudless"
            resValue(type = "string", name = "app_name", value = "goback .")
        }
        create("production") {
            dimension = "flavor-type"
            applicationId = "com.goback.app"
            resValue(type = "string", name = "app_name", value = "goback .")
        }
    }
}