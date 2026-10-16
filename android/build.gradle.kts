import com.android.build.api.variant.LibraryAndroidComponentsExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Native Flutter plugins must use the project's installed NDK as well.
    // Finalize after each plugin's own DSL (JNI otherwise uses Flutter's default).
    plugins.withId("com.android.library") {
        extensions.configure<LibraryAndroidComponentsExtension> {
            finalizeDsl { android ->
                android.ndkVersion = "29.0.14206865"
            }
        }
    }
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
