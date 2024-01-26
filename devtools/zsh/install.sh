brew install zsh

rsync -avh --no-perms devtools/zsh/.zshrc ~

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
