# 两阶段构建，最终镜像小很多
FROM eclipse-temurin:17-jdk AS build
WORKDIR /workspace
COPY pom.xml ./
COPY .mvn .mvn
COPY mvnw ./
RUN chmod +x mvnw && ./mvnw -B -ntp dependency:go-offline
COPY src src
RUN ./mvnw -B -ntp -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app
# 复制 fat jar
COPY --from=build /workspace/target/flight-attendance-server.jar /app/app.jar

# 时区 / JVM 参数可由 -e JVM_OPTS 注入
ENV JAVA_OPTS=""
ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
