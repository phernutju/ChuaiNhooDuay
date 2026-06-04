allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            force("com.google.guava:guava:32.1.3-android")
            force("com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava")
            force("com.google.j2objc:j2objc-annotations:2.8")
            force("com.google.code.findbugs:jsr305:3.0.2")
        }
        exclude(group = "com.google.guava", module = "guava-jdk5")
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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
