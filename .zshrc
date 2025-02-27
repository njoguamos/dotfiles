# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your dotfiles.
export DOTFILES=$HOME/.dotfiles

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Enable completions
autoload -Uz compinit && compinit

# Minimal - Theme Settings
export MNML_INSERT_CHAR="$"
export MNML_PROMPT=(mnml_git mnml_keymap)
export MNML_RPROMPT=('mnml_cwd 20')

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="minimal"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=7

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="dd/mm/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$DOTFILES

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# These plugins are installed and maintained at homebrew
# We source them to make sure they are recognised by zsh
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LC_ALL=en_GB.UTF-8
export LANG=en_GB.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Export Homebrew sbin
export PATH="/usr/local/sbin:$PATH"

# Export composer
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Load Node global installed binaries
export PATH="$HOME/.node/bin:$PATH"

# Use project specific binaries before global ones
export PATH="node_modules/.bin:vendor/bin:$PATH"

# Export node
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"

# Run tinker
function tinker()
{
    if [ -z "$1" ]
        then
            php artisan tinker
        else
            php artisan tinker --execute="dd($1);"
    fi
}

# Run Pest or PhpUnit
function p() {
    if [ -f vendor/bin/pest ]; then
       vendor/bin/pest "$@"
    else
       vendor/bin/phpunit "$@"
    fi
 }

 # Android studio
 export ANDROID_HOME="$HOME/Library/Android/sdk"
 export PATH="$ANDROID_HOME/platform-tools:$PATH"

  if command -v ngrok &>/dev/null; then
    eval "$(ngrok completion)"
  fi

# Always wrap shells
# For zsh subshells, add to ~/.zshrc.
printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh"}}\x9c'

# Run Docker Task Runner
dtr() {
    # Set project name to the current directory name by default
    local PROJECT_NAME=${1:-$(basename "$PWD")}

    # Check if docker-compose.yml exists
    if [[ ! -f "docker-compose.yml" ]]; then
        echo "Error: docker-compose.yml not found in the current directory."
        return 1
    fi

    echo "Docker Task Runner - Project: $PROJECT_NAME"
    echo "------------------"
    echo "1. Start services (up)"
    echo "2. Stop and remove services (down)"
    echo "3. Restart services"
    echo "4. Show service logs"
    echo "5. List running containers"
    echo "6. Execute command in a running container"
    echo "7. Exit"

    read "choice?Enter your choice [1-7]: "

    case $choice in
        1)
            docker compose -f docker-compose.yml -p $PROJECT_NAME up -d
            ;;
        2)
            docker compose -f docker-compose.yml -p $PROJECT_NAME down
            ;;
        3)
            docker compose -f docker-compose.yml -p $PROJECT_NAME down && docker compose -f docker-compose.yml -p $PROJECT_NAME up -d
            ;;
        4)
            docker compose -f docker-compose.yml -p $PROJECT_NAME logs --tail=100
            ;;
        5)
            docker ps
            ;;
        6)
            read "container?Enter container name or ID: "
            read "command?Enter command to execute (e.g., /bin/bash): "
            docker exec -it $container $command
            ;;
        7)
            echo "Exiting."
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
}

export EDITOR=nanoexport 

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"