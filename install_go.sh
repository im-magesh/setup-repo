VERSION="1.21.1"
ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

ARCH=$(echo "$ARCH" | sed 's/aarch64/arm64/')
DOWNLOAD_LINK="https://go.dev/dl/go${VERSION}.${OS}-${ARCH}.tar.gz"
FILENAME="go${VERSION}.${OS}-${ARCH}.tar.gz"

apt update && apt install -y wget git-core
wget $DOWNLOAD_LINK
tar -xzf ${FILENAME}

mv go /usr/local/go
echo 'export PATH=$PATH:/usr/local/go/bin
export GOPATH=/var/www/go
export PATH=$PATH:$GOPATH/bin' >> /etc/profile
. /etc/profile
mkdir -p $GOPATH/src
mkdir -p $GOPATH/bin
mkdir -p $GOPATH/pkg
. /etc/profile
go version
