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
}

subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIX: camera_android_camerax compileDebugJavaWithJavac fails with:
//   "class file for androidx.concurrent.futures.CallbackToFutureAdapter not found"
//
// camera-core 1.5.3 references CallbackToFutureAdapter in its API jar, so
// javac needs the concurrent-futures JAR on the compile classpath.
// The dependency may only be on the runtime path, or resolved to a version
// that doesn't include it. We explicitly add it to ALL Android library and
// application subprojects via plugins.withId (fires at plugin-apply time,
// safe to call before the subproject's build.gradle runs).
// ─────────────────────────────────────────────────────────────────────────────
subprojects {
    plugins.withId("com.android.library") {
        dependencies {
            add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
        }
    }
    plugins.withId("com.android.application") {
        dependencies {
            add("implementation", "androidx.concurrent:concurrent-futures:1.2.0")
        }
    }

    // Also force the resolved version across all configurations
    configurations.all {
        resolutionStrategy {
            eachDependency {
                if (requested.group == "androidx.concurrent" &&
                    requested.name == "concurrent-futures") {
                    useVersion("1.2.0")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}