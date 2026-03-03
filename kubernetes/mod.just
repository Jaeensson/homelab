set positional-arguments := true
set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']
set dotenv-load := true

kubernetes_dir := justfile_dir() + '/kubernetes'


[private]
default:
    namespaces crds resources

wait:
    if ! kubectl wait nodes --for=condition=Ready=True --all --timeout=10s &>/dev/null; then \
        until kubectl wait nodes --for=condition=Ready=False --all --timeout=10s &>/dev/null; do \
            echo "Nodes not available, waiting for nodes to be available. Retrying in 5 seconds..."; \
            sleep 5; \
        done \
    fi


namespaces:
    find "{{ kubernetes_dir }}/apps" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r dir; do \
        if ! kustomize build "$dir" | yq ea -e 'select(.kind == "Namespace")' | kubectl apply --server-side --field-manager bootstrap --force-conflicts -f -; then \
            echo "Failed to apply namespaces"; \
        fi; \
    done

crds:
    if ! helmfile -f "{{ kubernetes_dir }}/bootstrap/helmfile.d/00-crds.yaml" template -q | yq ea -e 'select(.kind == "CustomResourceDefinition")' | kubectl apply --server-side --field-manager bootstrap --force-conflicts -f -; then \
        echo "Failed to apply crds"; \
    fi;

resources: 
    envsubst < "{{ kubernetes_dir }}/bootstrap/resources.yaml.tmpl" | kubectl apply --server-side --field-manager bootstrap --force-conflicts -f -

kustomizations:
    find "{{ kubernetes_dir }}/apps" -name "ks.yaml" | while IFS= read -r f; do \
        dir=$(dirname "$f")/app; \
        echo "Applying Kustomization from $dir"; \
        kustomize build "$dir" | kubectl apply --server-side --force-conflicts -f -; \
    done

apps:
    helmfile -f "{{ kubernetes_dir }}/bootstrap/helmfile.d/01-apps.yaml" sync --hide-notes --debug

prune-pods:
    for phase in Failed Pending Succeeded; do \
        kubectl delete pods -A --field-selector status.phase="$phase" --ignore-not-found=true; \
    done

apply-ks ns ks:
    just k8s render-local-ks "{{ ns }}" "{{ ks }}" | kubectl apply --server-side --force-conflicts --field-manager=kustomize-controller -f /dev/stdin


[private]
render-local-ks ns ks:
    flux build ks --namespace "{{ ns }}" --path "{{ kubernetes_dir }}/flux/cluster" "{{ ks }}"