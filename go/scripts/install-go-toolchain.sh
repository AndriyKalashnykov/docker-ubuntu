#!/bin/bash

# set -x

LAUNCH_DIR=$(pwd); SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; cd $SCRIPT_DIR; cd ..; SCRIPT_PARENT_DIR=$(pwd);
. $SCRIPT_DIR/set-env.sh

cd $SCRIPT_DIR

git clone https://github.com/udhos/update-golang ~/projects/update-golang/ 
sudo ~/projects/update-golang/update-golang.sh 
sudo echo 'source /etc/profile.d/golang_path.sh' | sudo tee -a ~/.bashrc

source /etc/profile.d/golang_path.sh

./install-goreleaser.sh

go install golang.org/x/tools/cmd/godoc@latest
go install golang.org/x/tools/cmd/benchcmp@latest
go install golang.org/x/tools/cmd/cover@latest
go install golang.org/x/tools/cmd/eg@latest
go install golang.org/x/tools/cmd/goimports@latest
go install golang.org/x/tools/cmd/gotype@latest
go install golang.org/x/tools/cmd/gorename@latest
go install golang.org/x/tools/cmd/gomvpkg@latest

# https://github.com/jfeliu007/goplantuml
go install github.com/jfeliu007/goplantuml/cmd/goplantuml@latest

# https://github.com/go-delve/delve/tree/master/Documentation/installation
go install github.com/go-delve/delve/cmd/dlv@latest

# https://pkg.go.dev/github.com/mgechev/revive#readme-installation
go install github.com/mgechev/revive@latest

cd $LAUNCH_DIR