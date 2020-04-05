
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
#export AWS_VAULT_KEYCHAIN_NAME=login
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse'
NOTES_PATH="$HOME/Documents/notes"

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

## hbi stuff
hbi() {
  args=($@)
  [[ "$args[2]" == "kubectl" ]] && kubectx $1
  aws-vault exec hbi-$1 -- ${args[@]:1}
}

k9s() {
  [ -z "$1" ] && 1=$(printf "sandbox\ndev\nprod" | fzf)
  [ -z "$1" ] && return 0
  [ "$(kubectx -c )" != $1 ] && kubectx $1
  hbi $1 "/usr/bin/k9s"
}

tfinit() {
  filepath=$(_get_filepath $1 "backend.tfvars")
  [ -z "$1" ] && 1=$(echo $filepath | cut -d'/' -f3)
  [ -z "$1" ] && return 0
  hbi $1 terraform init --reconfigure --backend-config $filepath
}

tfplan() {
  filepath=$(_get_filepath $1 "terraform.tfvars")
  [ -z "$1" ] && 1=$(echo $filepath | cut -d'/' -f3)
  [ -z "$1" ] && return 0
  hbi $1 terraform plan --var-file $filepath -out /tmp/plan.out
}

tfapply() {
  hbi $1 terraform apply /tmp/plan.out
}

_get_filepath() {
  echo $(fd . '../' | awk "/$1/ && /$2/" | fzf -1 -0)
}

## passexpression store
pass() {
  if [ "$#" -eq 0 ] || ([ "$#" -eq 1 ] && [[ "$1" == "-c" ]]); then
    pass_dir=$HOME/.password-store/
    dir_len=${#pass_dir}
    selection=$(fd 'gpg' . $pass_dir | cut -c "$((dir_len+1))"- | sed -e 's/\(.*\)\.gpg/\1/' | fzf)
    [ -z "$selection" ] && return 0
    echo $selection && /bin/pass $1 $selection
  else
    /bin/pass "$@"
  fi
}

## note taking
notes() {
  current_dir=$(pwd)
  action=$EDITOR
  cd $NOTES_PATH

  if [[ "$1" == "view" ]]; then
    action=mdless
  elif [[ "$1" == "add" ]]; then
    $action $2
  else
    expression=$1
  fi

  while true; do
    if [ -z "$expression" ]; then
      selection=$(ls -t | fzf --preview="cat {}" --preview-window=right:70%:wrap) || break
    else
      selection=$(rg --files-with-matches --no-messages "$expression" * | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$expression' || rg --ignore-case --pretty --context 10 '$expression' {}") || break
    fi
    $action $selection
  done

  cd $current_dir
}

## nmcli
wifi() {
  if [[ "$1" == "connect" ]]; then
    nmcli d w rescan && nmcli d w c $2 $3
  else
    selection=$(nmcli --color yes d w l | fzf --ansi --inline-info --header-lines=1 --cycle | xargs) 
    [ -z "$selection" ] && return 0
    BSSID=$(echo $selection | cut -d' ' -f1) 
    SSID=$(echo $selection | cut -d' ' -f2) 

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
