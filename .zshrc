
export ZSH="/home/yan/.oh-my-zsh"
export PATH="/home/yan/.tfenv/bin:$PATH"
ZSH_THEME="robbyrussell-mod"
plugins=(git pass fd)

source $ZSH/oh-my-zsh.sh
source /usr/share/fzf/key-bindings.zsh 
source /usr/share/fzf/completion.zsh 

#export GDK_BACKEND=wayland
#export CLUTTER_BACKEND=wayland
#export XDG_CURRENT_DESKTOP=Unity
#export AWS_VAULT_KEYCHAIN_NAME=login
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse'

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
  aws-vault exec hbi-$1 -- ${args[@]:1}
}

k9s() {
  [ -z "$1" ] && 1=$(printf "sandbox\ndev\nprod" | fzf)
  [ "$(kubectx -c )" != $1 ] && kubectx $1
  hbi $1 "/usr/bin/k9s"
}

tfinit() { 
  filepath=$(_get_filepath $1 "backend.tfvars")
  [ -z "$1" ] && 1=$(echo $filepath | cut -d'/' -f3)
  hbi $1 terraform init --reconfigure --backend-config $filepath
}

tfplan() { 
  filepath=$(_get_filepath $1 "terraform.tfvars")
  [ -z "$1" ] && 1=$(echo $filepath | cut -d'/' -f3)
  hbi $1 terraform plan --var-file $filepath -out /tmp/plan.out
}

tfapply() {
  hbi $1 terraform apply /tmp/plan.out
}

_get_filepath() {
  echo $(fd . '../' | awk "/$1/ && /$2/" | fzf -1 -0)
}

## password store
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

## nmcli
wifi() {
  if [ "$1" = "connect" ]; then
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
