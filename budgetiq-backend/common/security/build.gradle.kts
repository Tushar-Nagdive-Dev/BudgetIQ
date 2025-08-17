plugins { id("java-library") }

dependencies {
    implementation(platform("org.springframework.boot:spring-boot-dependencies:3.3.2"))
    api("org.springframework.boot:spring-boot-starter") // logging, core utils

    // JWT libs will come in Phase 1; for Phase 0 keep empty or basic stubs.
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.2")
}
