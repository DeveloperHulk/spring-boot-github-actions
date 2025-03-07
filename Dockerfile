# Use an official Java runtime as a parent image
FROM eclipse-temurin:17-jdk AS build

# Set the working directory inside the container
WORKDIR /app

# Copy the built JAR file into the container
COPY target/demo-0.0.1-SNAPSHOT.jar app.jar

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
