#!/bin/bash

DOCKER_BUILDKIT=1 docker build --build-arg USER_EMAIL="AndriyKalashnykov@gmail.com" --build-arg UBUNTU_VERSION="21.10" --build-arg GITHUB_PAT="${GITHUB_PAT}" --build-arg SSH_PUBLIC_KEY="$(cat /home/$USER/.ssh/id_rsa.pub)" --build-arg SSH_PRIVATE_KEY="$(cat /home/$USER/.ssh/id_rsa)" --build-arg GPG_SECRET="$(cat /home/andriy/projects/dotfiles/gnupg/AndriyKalashnykov-secret-gpg.key | base64 -w 0)" --build-arg GPG_OWNER_TRUST="$(cat /home/andriy/projects/dotfiles/gnupg/AndriyKalashnykov-ownertrust-gpg.txt | base64 -w 0)" --build-arg GPG_PWD="${MY_GPG_PASSWORD}" -t go-dev .

# ./scripts/generate-keys.sh "user" "AndriyKalashnykov@gmail.com" "$(cat /home/$USER/.ssh/id_rsa.pub)" "$(cat /home/$USER/.ssh/id_rsa)"
# ./scripts/generate-gpg-keys.sh "user" "$(cat /home/andriy/projects/dotfiles/gnupg/AndriyKalashnykov-secret-gpg.key | base64 -w 0)" "$(cat /home/andriy/projects/dotfiles/gnupg/AndriyKalashnykov-ownertrust-gpg.txt | base64 -w 0)" "${MY_SSH_PASSWORD}"