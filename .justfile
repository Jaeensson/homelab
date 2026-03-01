#!/usr/bin/env -S just --justfile

set dotenv-load := true
set quiet := true

mod k8s "kubernetes"
mod terraform "terraform"

[private]
default:
    just -l

deploy:
    just terraform::apply
    just terraform::get-config
    just k8s::wait
    just k8s::namespaces
    just k8s::resources
    just k8s::crds
    just k8s::apps
    just k8s::kustomizations
