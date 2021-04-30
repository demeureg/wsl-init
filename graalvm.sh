#!/bin/sh
TARGET_DIR="/usr/lib/jvm"
if [ ! -d "${TARGET_DIR}" ] 
then
    echo "Creating ${TARGET_DIR}..."
    sudo mkdir -p /usr/lib/jvm
    echo 'Done'
fi

if [ ! -f "/tmp/graalvm-ce-java11-linux-amd64-21.1.0.tar.gz" ]
then
    echo 'Downloading GraalVM 21.1.0...'
    wget https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-21.1.0/graalvm-ce-java11-linux-amd64-21.1.0.tar.gz -O /tmp/graalvm-ce-java11-linux-amd64-21.1.0.tar.gz
    echo 'Done'
else
    echo 'GraalVM already downloaded. Using cached archive'
fi 

echo 'Extracting GraalVM files...'
sudo tar -xzf /tmp/graalvm-ce-java11-linux-amd64-21.1.0.tar.gz -C ${TARGET_DIR}
echo 'Done'

echo "export JAVA_HOME=${TARGET_DIR}/graalvm-ce-java11-21.1.0" >> $HOME/.profile
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> $HOME/.profile
source $HOME/.profile 
echo "JAVA_HOME set to ${JAVA_HOME}"
echo 'GraalVM info:'
java -version

echo 'Installing GraalVM as systeme default' 
for executable in $(ls "${JAVA_HOME}/bin")
do 
    sudo update-alternatives --install /usr/bin/${executable} ${executable} ${JAVA_HOME}/bin/${executable} 0 
done 
echo 'Done'
