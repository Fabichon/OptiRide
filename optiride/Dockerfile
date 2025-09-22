# Dockerfile pour tester OptiRide Flutter en mode web
FROM cirrusci/flutter:stable

WORKDIR /app
COPY . /app

RUN flutter pub get

EXPOSE 8080
CMD ["flutter", "run", "-d", "web-server", "--web-port=8080"]
