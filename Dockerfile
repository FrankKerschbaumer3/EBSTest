FROM maven:3-jdk-8 AS builder
WORKDIR /usr/src/app
COPY . .
RUN mvn clean package -DskipTests -Dmaven.javadoc.skip=true

FROM openjdk:alpine
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/target/app.jar /usr/src/app/app.jar
CMD ["java", "-jar", "/usr/src/app/app.jar"]