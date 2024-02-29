#!/bin/bash
set -o errexit

# desired cluster name; default is "kind"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-k8s}"

# create registry container unless it already exists
reg_name='registry'
reg_port='5000'
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" registry:2
fi
reg_ip="$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "${reg_name}")"

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --name "${KIND_CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches: 
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_ip}:${reg_port}"]
kubeadmConfigPatches:
- |-
  kind: ClusterConfiguration
  apiServer:
    extraArgs::
      "audit-policy-file": "/home/pcarlton/src/github.com/paulcarlton-ww/dev-stuff/info/auditpolicy.yaml"
      "feature-gates": "DynamicAuditing=true,auditregistration.k8s.io/v1alpha1=true"
nodes:
- role: control-plane
- role: control-plane
- role: worker
- role: worker
EOF

export KUBECONFIG=$HOME/info/kind-${KIND_CLUSTER_NAME}.config
cp ~/.kube/config $HOME/info/kind-${KIND_CLUSTER_NAME}.config
kubectl config use-context kind-${KIND_CLUSTER_NAME}

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

pushd $HOME/src/github.com/istio/istio-$ISTIO_VER/
bin/istioctl manifest apply --set profile=demo
popd

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
kubectl apply -f info/k8s-dash-sa.yaml
kubectl apply -f info/k8s-dash-crb.yaml
kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
kubectl proxy --port=8081 &

kubectl label namespace default istio-injection=enabled

kubectl create namespace test
kubectl label namespace test istio-injection=enabled

helm upgrade --install --wait frontend \
--namespace test \
--set replicaCount=2 \
--set backend=http://backend-podinfo:9898/echo \
podinfo/podinfo

# Test pods have hook-delete-policy: hook-succeeded

helm upgrade --install --wait backend \
--namespace test \
--set hpa.enabled=true \
podinfo/podinfo

echo "export KUBECONFIG=$HOME/info/kind-${KIND_CLUSTER_NAME}.config"
