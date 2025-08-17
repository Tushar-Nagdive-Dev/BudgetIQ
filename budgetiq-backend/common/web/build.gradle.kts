plugins { id("java-library") }

dependencies {
    implementation(platform("org.springframework.boot:spring-boot-dependencies:3.3.2"))
    api("org.springframework:spring-web")
    api("jakarta.validation:jakarta.validation-api:3.1.0")
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.2")
}
