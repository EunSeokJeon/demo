FROM adoptopenjdk:8-jdk-hotspot AS builder # 베이스 이미지 + 이미지 별칭
COPY gradlew . # gradlew 복사
COPY gradle gradle # gradle 복사
COPY build.gradle . # build.gradle 복사
COPY settings.gradle . # settings.gradle 복사
COPY src src # 웹 어플리케이션 소스 복사
RUN chmod +x ./gradlew # gradlew 실행권한 부여
RUN ./gradlew bootJar # gradlew를 사용하여 실행 가능한 jar 파일 생성

FROM adoptopenjdk:8-jdk-hotspot # 베이스 이미지
COPY --from=builder build/libs/*.jar app.jar # builder 이미지에서 build/libs/*.jar 파일을 app.jar로 복사

EXPOSE 8080 # 컨테이너 Port 노출
ENTRYPOINT ["java","-jar","/app.jar"] # jar 파일 실행