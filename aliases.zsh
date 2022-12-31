# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_ed25519.pub"
alias reloadshell="source $HOME/.zshrc"
alias reloaddns="dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
alias phpstorm='open -a /Applications/PhpStorm.app "`pwd`"'
alias code='open -a /Applications/Visual\ Studio\ Code.app "`pwd`"'
alias c="clear"

# Directories
alias dotfiles="cd $DOTFILES"
alias sites="cd $HOME/code"

# Laravel
alias a="php artisan"
alias tinker="php artisan tinker"
alias fresh='php artisan migrate:fresh --seed'

# Composer
alias cdu="composer dumpautoload"
alias ci="composer install"
alias cu="composer update"

# PHP
alias cfresh="rm -rf vendor/ composer.lock && composer i"
# JS
alias nfresh="rm -rf node_modules/ package-lock.json && npm install"
alias watch="npm run watch"

# Git
alias gst="git status"
alias gb="git branch"
alias gc="git checkout"
alias gl="git log --oneline --decorate --color"
alias amend="git add . && git commit --amend --no-edit"
alias commit="git add . && git commit -m"
alias diff="git diff"
alias force="git push --force"
alias nuke="git clean -df && git reset --hard"
alias pop="git stash pop"
alias pull="git pull"
alias push="git push"
alias resolve="git add . && git commit --no-edit"
alias stash="git stash -u"
alias unstage="git restore --staged ."
alias wip="commit wip"

# Minio
alias myminio='minio server ~/s3 --address=127.0.0.1:8900 --console-address ":8901"'
