set positional-arguments := true
set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']
set dotenv-load := true

kubernetes_dir := justfile_dir() + '/kubernetes'


[private]
default:
    just -l

destroy:
    terraform destroy

apply:
    terraform apply -auto-approve

get-config:
    terraform output -raw kubeconfig > ~/.kube/config \
    && terraform output -raw talosconfig > ~/.talos/config



#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