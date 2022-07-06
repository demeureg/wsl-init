#!/bin/bash
KIND=linux
ARCH=amd64
GRAALVM_VERSION=22.1.0-0
GRAALVM_8_FILE=graalvm-ce-java8_amd64_21.3.1-0.deb
GRAALVM_11_FILE=graalvm-ce-java11_$ARCH\_$GRAALVM_VERSION.deb
GRAALVM_17_FILE=graalvm-ce-java17_$ARCH\_$GRAALVM_VERSION.deb
JAVA_BASE_DIR=/usr/lib/jvm
HELM_VERSION=3.9.0
HELM_FILE=helm-v$HELM_VERSION-$KIND-$ARCH.tar.gz
KUBELOGIN_VERSION=1.25.1
KUBELOGIN_FILE=kubelogin_$KIND\_$ARCH.zip
KUBESEAL_VERSION=0.18.0
KUBESEAL_FILE=kubeseal-$KUBESEAL_VERSION-$KIND-$ARCH.tar.gz
WORKDIR=/tmp

cd $WORKDIR
echo "Executing script into $(pwd)..."

apt update && \
    apt upgrade -qy && \
    apt install -qy curl dos2unix git keychain libnss3 libnspr4 libsqlite3-0 openjdk-17-jre-headless sudo tar unzip zsh && \
    apt autoremove -qy --purge

[[ ! -f /usr/bin/kubectl ]] && curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/$ARCH/kubectl > /dev/null

[[ ! -f /usr/bin/kubelogin ]] && curl -LO https://github.com/int128/kubelogin/releases/download/v$KUBELOGIN_VERSION/$KUBELOGIN_FILE > /dev/null

[[ ! -f $WORKDIR/$HELM_FILE ]] && curl -LO https://get.helm.sh/$HELM_FILE > /dev/null

[[ ! -f $WORKDIR/$GRAALVM_8_FILE ]] && curl -LO https://github.com/dongjinleekr/graalvm-ce-deb/releases/download/21.3.1-0/$GRAALVM_8_FILE > /dev/null

[[ ! -f $WORKDIR/$GRAALVM_11_FILE ]] && curl -LO https://github.com/dongjinleekr/graalvm-ce-deb/releases/download/$GRAALVM_VERSION/$GRAALVM_11_FILE > /dev/null

[[ ! -f $WORKDIR/$GRAALVM_17_FILE ]] && curl -LO https://github.com/dongjinleekr/graalvm-ce-deb/releases/download/$GRAALVM_VERSION/$GRAALVM_17_FILE > /dev/null

[[ ! -f $WORKDIR/$KUBESEAL_FILE ]] && curl -LO https://github.com/bitnami-labs/sealed-secrets/releases/download/v$KUBESEAL_VERSION/$KUBESEAL_FILE > /dev/null

find $WORKDIR -type f -name '*.deb' -exec dpkg --unpack {} \;
GRAALVM_DIRS=( $(find /usr/lib/jvm -mindepth 1 -maxdepth 1 -type d | sort) ) 
GRAALVM_DIR=${GRAALVM_DIRS[1]}
mkdir -p /etc/ssl/certs/java && cp $GRAALVM_DIR/lib/security/cacerts /etc/ssl/certs/java
for JAVA_BASE_DIR in $GRAALVM_DIRS
do
    rm $JAVA_BASE_DIR/lib/security/cacerts
    ln -s /etc/ssl/certs/java/cacerts $JAVA_BASE_DIR/lib/security/cacerts
done
apt install -qy ca-certificates-java java-common
[[ ! -L /home/$SUDO_USER/.m2 ]] && ln -s /mnt/c/Users/g.demeure/.m2 /home/$SUDO_USER/.m2

if [ ! -f /usr/bin/kubectl ]; then
    mv kubectl /usr/bin
    chmod +x /usr/bin/kube*
fi

if [ ! -f /usr/bin/helm ]; then
    tar -xzvf $HELM_FILE
    mv linux-amd64/helm /usr/bin
    chmod +x /usr/bin/helm
    rm -rf linux-amd64
fi

if [ ! -f /usr/bin/kubelogin ]; then 
    unzip $KUBELOGIN_FILE
    mv kubelogin /usr/bin
    chmod +x /usr/bin/kube*
fi

if [ ! -f /usr/bin/kubeseal ]; then
    tar -xzvf $KUBESEAL_FILE
    mv kubeseal /usr/bin
    chmod +x /usr/bin/kube*
fi

# Target user config
[[ ! -L /home/$SUDO_USER/.kube ]] && ln -s /mnt/c/Users/g.demeure/.kube /home/$SUDO_USER/.kube

# Configuring SSH
mkdir -p /home/$SUDO_USER/.ssh && \
    yes | cp -rf /mnt/c/Users/g.demeure/ssh/id_rsa /home/$SUDO_USER/.ssh && \
    ssh-keygen -f /home/$SUDO_USER/.ssh/id_rsa -y > /home/$SUDO_USER/.ssh/id_rsa.pub && \
    chmod 700 /home/$SUDO_USER/.ssh && \
    chmod 644 /home/$SUDO_USER/.ssh/id_rsa.pub && \
    chmod 600 /home/$SUDO_USER/.ssh/id_rsa && \
    chown -R $SUDO_UID:$SUDO_GID /home/$SUDO_USER/.ssh

#FIXME
cat <<EOF | tee /home/$SUDO_USER/.profile
export JAVA_HOME="$GRAALVM_DIR"
export GRAALVM_HOME=\$JAVA_HOME
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF

cat <<EOF | tee /home/$SUDO_USER/.bashrc
eval \`keychain --eval /home/$SUDO_USER/.ssh/id_rsa\`
EOF

cat <<EOF | tee /home/$SUDO_USER/.bash_profile
ssh-agent bash
EOF

#FIXME env vars
git config --global user.email "g.demeure@monaco-telecom.mc"
git config --global user.name "DEMEURE Guillaume"
git config --global core.editor vim

apt autoremove --purge -qy openjdk-17-jre-headless
