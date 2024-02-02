plugins {
    kotlin("jvm") version "1.9.22"
}

group = "com.stockmq"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    implementation("org.zeromq:jeromq:0.5.4")
    implementation("org.msgpack:msgpack:0.6.12")
}

tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}