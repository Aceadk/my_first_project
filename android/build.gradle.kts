import org.gradle.api.tasks.compile.JavaCompile

plugins {
    // Add the dependency for the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.2" apply false
}

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
}
subprojects {
    project.evaluationDependsOn(":app")

    // Third-party Flutter plugins may still compile with deprecated Java APIs.
    // Suppress javac summary notes (for example "uses or overrides a deprecated API")
    // emitted by upstream plugin code, without muting normal warnings.
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-XDsuppressNotes=true")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
