
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.tfenv/bin:$HOME/.local/bin::$PATH"
ZSH_THEME="robbyrussell-mod"
plugins=(git pass fd)

source $ZSH/oh-my-zsh.sh
source /usr/share/fzf/key-bindings.zsh 
source /usr/share/fzf/completion.zsh 

#export GDK_BACKEND=wayland
#export CLUTTER_BACKEND=wayland
export XDG_CURRENT_DESKTOP=Unity
export EDITOR='nvim'
export FZF_DEFAULT_OPTS="--layout=reverse --bind=ctrl-o:accept --cycle"
export FZF_CTRL_R_OPTS="--height 40%"
export FZF_DEFAULT_COMMAND="rg --files --no-ignore-vcs --hidden"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BATPAGER="less -RF"
NOTE_DIR="$HOME/Documents/notes"
PASS_DIR="$HOME/.password-store"
PROJECTS_DIR="$HOME/Dev/HnB"
HISTSIZE=1000000
SAVEHIST=1000000
setopt HIST_IGNORE_ALL_DUPS 

eval "$(pyenv init -)"

alias so="source ~/.zshrc"
alias zshrc="vim $HOME/.zshrc"
alias vimrc="vim $HOME/.config/nvim/init.vim"
alias gitconfig="vim $HOME/.gitconfig"
alias yay="yay -Pw && yay"
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

tfdestroy() {
  local filepath=$(_get_tf_filepath $1 "terraform.tfvars") && echo Using: $filepath
  local env=$(_get_tf_env $filepath $1)
  [ -z "$env" ] && return 0
  hbi $env terraform destroy --var-file $filepath
}

tfapply() {
  hbi $1 terraform apply /tmp/plan.out
}

_get_tf_filepath() {
  echo $(fd . '../' | awk "/$1/ && /$2/" | fzf -1 -0 --height 40%)
}

_get_tf_env() {
  echo ${2:-$(echo $1 | cut -d'/' -f3)}
}

## pass store
pass() {
  if [ "$#" -eq 0 ] || ([ "$#" -eq 1 ] && [[ "$1" == "-c" ]]); then
    local dir_len=${#PASS_DIR}
    local selection=$(fd 'gpg' $PASS_DIR | cut -c "$((dir_len+1))"- | sed -e 's/\(.*\)\.gpg/\1/' | fzf --height 40%)
    [ -z "$selection" ] && return 0
    echo Showing: $selection && /bin/pass $1 $selection
  else
    /bin/pass "$@"
  fi
}

## note taking
note() {
  local preview_options="--preview-window=right:70%:wrap"
  local editor="$EDITOR -c 'Goyo'"
  local expression=""

  if [[ "$1" == "new" ]]; then
    local filename="$2.md"
    eval "$editor $NOTE_DIR/$2.md"
  else
    expression=$1
  fi

  while true; do
    if [ -z "$expression" ]; then
      note=$(ls -t $NOTE_DIR | fzf --preview="bat --color 'always' --decorations 'never' $NOTE_DIR/{}" $preview_options) || break
    else
      matches=$(rg --files-with-matches --no-messages --ignore-case "$expression" $NOTE_DIR/* | rg -o '[^/]*$')

      if [ -z "$matches" ]; then
        echo "No matches!" && break
      else
        note=$(echo $matches | fzf --preview "rg --ignore-case --pretty --context 10 $expression $NOTE_DIR/{}" $preview_options) || break
      fi
    fi

    eval "$editor $NOTE_DIR/$note"
  done
}

## nmcli
wifi() {
  if [[ "$1" == "connect" ]]; then
    nmcli d w c $2 $3
  elif [[ "$1" == "scan" ]]; then
    nmcli d w rescan
  else
    local selection=$(nmcli --color yes d w l | fzf --ansi --inline-info --header-lines=1 | xargs)
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

glogi() {
  local out sha q
  while out=$(
      git log --graph --color=always \
          --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
      fzf --ansi --multi --no-sort --query="$q" --print-query); do
    q=$(head -1 <<< "$out")
    while read sha; do
      git show --color=always $sha | less -R
    done < <(sed '1d;s/^[^a-z0-9]*//;/^$/d' <<< "$out" | awk '{print $1}')
  done
}

pd() {
  local expression=${1:-'.'}
  local project=$(fd $expression $PROJECTS_DIR -HI -t d -a -d 1 | rg -o '[^/]*$' | fzf -0 --height 40%)
  [ -z "$project" ] && return 0
  cd $PROJECTS_DIR/$project
}

# fstash - easier way to deal with stashes
# type fstash to get a list of your stashes
# enter shows you the contents of the stash
# ctrl-d shows a diff of the stash against your current HEAD
# ctrl-b checks the stash out as a branch, for easier merging
fstash() {
  local out q k sha
  while out=$(
    git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
    fzf --ansi --no-sort --query="$q" --print-query \
        --expect=ctrl-d,ctrl-b);
  do
    mapfile -t out <<< "$out"
    q="${out[0]}"
    k="${out[1]}"
    sha="${out[-1]}"
    sha="${sha%% *}"
    [[ -z "$sha" ]] && continue
    if [[ "$k" == 'ctrl-d' ]]; then
      git diff $sha
    elif [[ "$k" == 'ctrl-b' ]]; then
      git stash branch "stash-$sha" $sha
      break;
    else
      git stash show -p $sha
    fi
  done
}

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ -r "/usr/share/z/z.sh" ]] && source /usr/share/z/z.sh
