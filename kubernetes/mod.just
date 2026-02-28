set positional-arguments := true
set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']
set dotenv-load := true

kubernetes_dir := justfile_dir() + '/kubernetes'


[private]
default:
    namespaces crds resources

namespaces:
    find "{{ kubernetes_dir }}/apps" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r dir; do \
        if ! kustomize build "$dir" | yq ea -e 'select(.kind == "Namespace")' | kubectl apply -f -; then \
            echo "Failed to apply namespaces"; \
        fi; \
    done

crds:
    if ! helmfile -f "{{ kubernetes_dir }}/bootstrap/helmfile.d/00-crds.yaml" template -q | yq ea -e 'select(.kind == "CustomResourceDefinition")' | kubectl apply -f -; then \
        echo "Failed to apply crds"; \
    fi;

resources: 
    envsubst < bootstrap/resources.yaml.tmpl | kubectl apply -f -

apps:
    helmfile -f "bootstrap/helmfile.d/01-apps.yaml" sync --hide-notes