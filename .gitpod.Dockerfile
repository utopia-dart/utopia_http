FROM gitpod/workspace-full:2022-06-09-20-58-43
SHELL ["/bin/bash", "-c"]

USER root
RUN RUN brew tap dart-lang/dart && brew install dart
