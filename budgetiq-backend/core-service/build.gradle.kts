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

    // will add data-jpa, flyway, postgres later (after DB step)

    implementation(project(":common:web"))
    implementation(project(":common:security"))

    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

tasks.named<Jar>("jar") { enabled = false }
