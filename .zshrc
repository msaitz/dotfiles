
export ZSH="/home/yan/.oh-my-zsh"
export PATH="/home/yan/.tfenv/bin:$PATH"
ZSH_THEME="robbyrussell-mod"
plugins=(git pass fd)

source $ZSH/oh-my-zsh.sh
source /usr/share/fzf/key-bindings.zsh 
source /usr/share/fzf/completion.zsh 

#export GDK_BACKEND=wayland
export CLUTTER_BACKEND=wayland
export XDG_CURRENT_DESKTOP=Unity
export AWS_VAULT_KEYCHAIN_NAME=login
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse'

HISTSIZE=1000000
SAVEHIST=1000000
setopt HIST_IGNORE_ALL_DUPS 

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

alias suspend="systemctl suspend"
alias hibernate="systemctl hibernate"
alias poweroff="systemctl poweroff"
alias vim="nvim"
alias rm='rm -I --preserve-root'
alias sudo="sudo "
alias hbi-services="aws-vault exec hbi-services --"
alias hbi-dev="aws-vault exec hbi-dev --"
alias hbi-sandbox="aws-vault exec hbi-sandbox --"
alias hbi-prod="aws-vault exec hbi-prod --"
alias hbi-billing="aws-vault exec hbi-billing --"
alias hbi-audit="aws-vault exec hbi-audit --"

## password store
pass() {
  if [ -z "$1" ] || [[ "$1" == "-c" ]]; then
    pass_dir=$HOME/.password-store/
    dir_len=${#pass_dir}
    selection=$(fd 'gpg' . $pass_dir | cut -c "$((dir_len+1))"- | sed -e 's/\(.*\)\.gpg/\1/' | fzf)
    echo $selection
    /bin/pass $1 $selection
  else
    /bin/pass "$@"
  fi
}

## Terraform
tfinit() { 
  filepath=$(fd . '../' | awk "/$1/ && /backend.tfvars/" | fzf -1)
  if [ -z "$1" ]; then 1=$(echo $filepath | cut -d'/' -f3); fi
  aws-vault exec hbi-$1 -- terraform init --reconfigure --backend-config $filepath 
}

tfplan() { 
  filepath=$(fd . '../' | awk "/$1/ && /terraform.tfvars/" | fzf -1)
  if [ -z "$1" ]; then 1=$(echo $filepath | cut -d'/' -f3); fi
  aws-vault exec hbi-$1 -- terraform plan --var-file $filepath -out /tmp/plan.out 
}

tfapply() { aws-vault exec hbi-$1 -- terraform apply /tmp/plan.out }

## nmcli
wifi() {
  if [ "$1" = "connect" ]; then
    nmcli d w c $2 $3
  else
    selection=$(nmcli --color yes d w l | fzf --ansi --inline-info --header-lines=1 --cycle | xargs) 
    [[ -z "$selection" ]] && return 0
    BSSID=$(echo $selection | cut -d' ' -f1) 
    SSID=$(echo $selection | cut -d' ' -f2) 

    if [ "$(nmcli c | grep $SSID | wc -l)" -eq 0 ]; then
      nmcli -a d w c $BSSID 
    else
      nmcli d w c $BSSID 
    fi
  fi
}
