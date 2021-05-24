#!/bin/sh
# ISTIO_INSTALL_DIR will receive the folder istio-$ISTIO_VERSION
ISTIO_INSTALL_DIR=${ISTIO_INSTALL_DIR:-/opt}
ISTIO_PROFILE=${ISTIO_PROFILE:-default}
ISTIO_VERSION=${ISTIO_VERSION:-1.10.0}

KNATIVE_VERSION=${KNATIVE_VERSION:-v0.23.0}

MINIKUBE_BOOTSTRAPPER=${MINIKUBE_BOOTSTRAPPER:-kubeadm}
MINIKUBE_CPUS=${MINIKUBE_CPUS:-4}
MINIKUBE_MEMORY=${MINIKUBE_MEMORY:-16384}
MINIKUBE_KUBERNETES_VERSION=${MINIKUBE_KUBERNETES_VERSION:-v1.20.2}

WORKDIR=/tmp

if [ ! $(id -u) = 0 ] && [ ! -d "${ISTIO_INSTALL_DIR}/istio-${ISTIO_VERSION}" ]
then
   echo "The script need to be run as root in order to install Istio" >&2
   exit 1
fi

cd $WORKDIR

curl -L https://istio.io/downloadIstio | sh -
sudo mv ${WORKDIR}/istio-${ISTIO_VERSION} ${ISTIO_INSTALL_DIR}
export PATH="${ISTIO_INSTALL_DIR}/istio-${ISTIO_VERSION}/bin:${PATH}"

istioctl install --set profile=${ISTIO_PROFILE} -y

minikube delete

minikube config set bootstrapper $MINIKUBE_BOOTSTRAPPER
minikube config set cpus $MINIKUBE_CPUS
minikube config set kubernetes-version $MINIKUBE_KUBERNETES_VERSION
minikube config set memory $MINIKUBE_MEMORY

minikube start --extra-config=apiserver.enable-admission-plugins="LimitRanger,NamespaceExists,NamespaceLifecycle,ResourceQuota,ServiceAccount,DefaultStorageClass,MutatingAdmissionWebhook"

kubectl create namespace knative-serving
kubectl apply -f https://github.com/knative/serving/releases/download/${KNATIVE_VERSION}/serving-crds.yaml
kubectl apply -f https://github.com/knative/serving/releases/download/${KNATIVE_VERSION}/serving-core.yaml
kubectl apply -f https://github.com/knative/net-istio/releases/download/${KNATIVE_VERSION}/istio.yaml
kubectl apply -f https://github.com/knative/net-istio/releases/download/${KNATIVE_VERSION}/net-istio.yaml
kubectl --namespace istio-system get service istio-ingressgateway
kubectl get pods --namespace knative-serving

kubectl create namespace knative-eventing
kubectl apply -f https://github.com/knative/eventing/releases/download/${KNATIVE_VERSION}/eventing-crds.yaml
kubectl apply -f https://github.com/knative/eventing/releases/download/${KNATIVE_VERSION}/eventing-core.yaml
kubectl get pods --namespace knative-eventing
