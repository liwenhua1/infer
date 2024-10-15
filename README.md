<img src="website/static/img/logo.png" alt="logo" width="15%" />

# Infer ![build](https://github.com/facebook/infer/actions/workflows/install.yml/badge.svg) ![website](https://github.com/facebook/infer/actions/workflows/deploy.yml/badge.svg)

[Infer](http://fbinfer.com/) is a static analysis tool for Java,
C++, Objective-C, and C. Infer is written in [OCaml](https://ocaml.org/).

## Installation

Read our [Getting
Started](http://fbinfer.com/docs/getting-started) page for
details on how to install packaged versions of Infer. To build Infer
from source, see [INSTALL.md](./INSTALL.md).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

Infer is MIT-licensed.

Note: Enabling Java support may require you to download and install 
components licensed under the GPL.

TACAS25:
Install using Infer's instruction. 
Disable/Enable casting error detection: 
comment/uncomment line 1252 in infer/src/pulse/PulseModelsJava.ml 
run a maven program cd to the top directory and using: sudo infer --pulse-only -- mvn clean compile
run a gradle program cd to the top directory and using: sudo infer --pulse-only -- ./gradlew build
