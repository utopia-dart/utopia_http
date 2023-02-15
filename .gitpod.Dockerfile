FROM gitpod/workspace-full:2022-06-20-19-54-55

RUN apt-get update \
    && apt-get install apt-transport-https \
    && wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list

 RUN apt-get update \
    && apt-get install dart
