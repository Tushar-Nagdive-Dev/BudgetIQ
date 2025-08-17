import org.gradle.api.plugins.JavaPlugin
import org.gradle.api.plugins.JavaPluginExtension
import org.gradle.jvm.toolchain.JavaLanguageVersion

plugins {
    id("com.diffplug.spotless") version "6.25.0"
}

allprojects {
    repositories { mavenCentral() }
}

subprojects {
    // Apply Java to all modules (libraries + apps)
    apply(plugin = "java")

    // Configure toolchain AFTER the plugin is applied, in a type-safe way
    plugins.withType<JavaPlugin> {
        extensions.configure(JavaPluginExtension::class.java) {
            toolchain.languageVersion.set(JavaLanguageVersion.of(21))
        }
    }

    tasks.withType<Test> {
        useJUnitPlatform()
    }
}

spotless {
    java {
        target("**/*.java")
        googleJavaFormat("1.22.0")
        trimTrailingWhitespace()
        endWithNewline()
    }
}
