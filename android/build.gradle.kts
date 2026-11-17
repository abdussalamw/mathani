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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    plugins.withId("com.android.library") {
        // Wakelock 1.8 assumes AGP 9 built-in Kotlin; other plugins still need KGP.
        if (project.name == "wakelock_plus") {
            project.pluginManager.apply("org.jetbrains.kotlin.android")
        }
        extensions.configure<com.android.build.api.dsl.LibraryExtension> {
            buildToolsVersion = "36.1.0"
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
