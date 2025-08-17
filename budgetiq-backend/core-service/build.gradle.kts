import org.gradle.kotlin.dsl.register

plugins {
    id("org.springframework.boot") version "3.3.2"
    id("io.spring.dependency-management") version "1.1.6"
    id("java")
}

dependencies {
    implementation(platform("org.springframework.boot:spring-boot-dependencies:3.3.2"))

    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    // Database stack
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.flywaydb:flyway-core")
    runtimeOnly("org.postgresql:postgresql:42.7.4")   // <— JDBC driver
    // will add data-jpa, flyway, postgres later (after DB step)

    implementation("me.paulschwarz:spring-dotenv:4.0.0")
    implementation(project(":common:web"))
    implementation(project(":common:security"))

    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

tasks.named<Jar>("jar") { enabled = false }

tasks.register<Exec>("setupLocalDb") {
    workingDir = rootDir
    commandLine("bash", "scripts/shell/setup-local-db.sh")
    isIgnoreExitValue = false
    onlyIf { (System.getenv("BUDGETIQ_DB_BOOTSTRAP") ?: "true").lowercase() != "false" }
}
tasks.named("bootRun") { dependsOn("setupLocalDb") }