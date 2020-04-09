
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.tfenv/bin:$PATH"
ZSH_THEME="robbyrussell-mod"
plugins=(git pass fd)

source $ZSH/oh-my-zsh.sh
source /usr/share/fzf/key-bindings.zsh 
source /usr/share/fzf/completion.zsh 

#export GDK_BACKEND=wayland
#export CLUTTER_BACKEND=wayland
export XDG_CURRENT_DESKTOP=Unity
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --bind=ctrl-o:accept --cycle"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BATPAGER="less -RF"
NOTE_DIR="$HOME/Documents/notes"
PASS_DIR="$HOME/.password-store"
PROJECTS_DIR="$HOME/Dev/HnB"

HISTSIZE=1000000
SAVEHIST=1000000
setopt HIST_IGNORE_ALL_DUPS 

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

eval "$(pyenv init -)"

alias open="xdg-open"
alias suspend="systemctl suspend"
alias hibernate="systemctl hibernate"
alias poweroff="systemctl poweroff"
alias vim="nvim"
alias rm='rm -I --preserve-root'
alias sudo="sudo "
alias pbcopy="wl-copy"
alias pbpaste="wl-paste"
alias glow="glow -p"
alias cat="bat"

## hbi stuff

cdp() {
  local expression=${1:-'.'}
  local project=$(fd $expression $PROJECTS_DIR -HI -t d -a -d 1 | rg -o '[^/]*$' | fzf)
  [ -z "$project" ] && return 0
  cd $PROJECTS_DIR/$project
}

hbi() {
  [ -z "$1" ] && echo "ENV not provided!" && return 1
  local env=$1
  local args=($@)
  [[ "$2" == "kubectl" ]] && kubectx $env
  aws-vault exec hbi-$env -- ${args[@]:1}
}

k9s() {
  local env=${1:-$(printf "sandbox\ndev\nprod" | fzf)}
  [ -z "$env" ] && return 0
  [ "$(kubectx -c )" != $env ] && kubectx $env
  hbi $env "/usr/bin/k9s"
}

tfinit() {
  local filepath=$(_get_tf_filepath $1 "backend.tfvars") && echo Using: $filepath
  local env=$(_get_tf_env $filepath $1)
  [ -z "$env" ] && return 0
  hbi $env terraform init --reconfigure --backend-config $filepath
}

tfplan() {
  local filepath=$(_get_tf_filepath $1 "terraform.tfvars") && echo Using: $filepath
  local env=$(_get_tf_env $filepath $1)
  [ -z "$env" ] && return 0
  hbi $env terraform plan --var-file $filepath -out /tmp/plan.out
}

tfapply() {
  hbi $1 terraform apply /tmp/plan.out
}

_get_tf_filepath() {
  echo $(fd . '../' | awk "/$1/ && /$2/" | fzf -1 -0)
}

_get_tf_env() {
  echo ${2:-$(echo $1 | cut -d'/' -f3)}
}

## pass store
pass() {
  if [ "$#" -eq 0 ] || ([ "$#" -eq 1 ] && [[ "$1" == "-c" ]]); then
    local dir_len=${#PASS_DIR}
    local selection=$(fd 'gpg' $PASS_DIR | cut -c "$((dir_len+1))"- | sed -e 's/\(.*\)\.gpg/\1/' | fzf)
    [ -z "$selection" ] && return 0
    echo Showing: $selection && /bin/pass $1 $selection
  else
    /bin/pass "$@"
  fi
}

## note taking
note() {
  local preview_options="--preview-window=right:70%:wrap"
  local current_dir=$(pwd)
  local action=$EDITOR
  local expression=""
  cd $NOTE_DIR

  if [[ "$1" == "view" ]]; then
    action='glow'
    [ -n "$2" ] && expression=$2 
  elif [[ "$1" == "add" ]]; then
    $action $2
  else
    expression=$1
  fi

  while true; do
    local note=""
    if [ -z "$expression" ]; then
      note=$(ls -t | fzf --preview="bat --color 'always' --decorations 'never' {}" $preview_options) || break
    else
      matches=$(rg --files-with-matches --no-messages --ignore-case "$expression" *)
      if [ -z "$matches" ]; then
        echo "No matches!" && break
      else
        note=$(echo $matches | fzf --preview "rg --ignore-case --pretty --context 10 $expression {}" $preview_options) || break
      fi
    fi
    eval "$action $note"
  done

  cd $current_dir
}

## nmcli
wifi() {
  if [[ "$1" == "connect" ]]; then
    nmcli d w c $2 $3
  elif [[ "$1" == "scan" ]]; then
    nmcli d w rescan
  else
    local selection=$(nmcli --color yes d w l | fzf --ansi --inline-info --header-lines=1 --cycle | xargs)
    [ -z "$selection" ] && return 0
    local BSSID=$(echo $selection | cut -d' ' -f1)
    local SSID=$(echo $selection | cut -d' ' -f2)

    if [ "$(nmcli c | rg $SSID | wc -l)" -eq 0 ]; then
      nmcli -a d w c $BSSID 
    else
      nmcli d w c $BSSID 
    fi
  fi
}

validate-yaml() {
  ruby -e "require 'yaml';puts YAML.load_file('$1')" > /dev/null
  if [ "$?" -eq 0 ]; then echo "yaml is valid!"
  else
    return 1
  fi
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
