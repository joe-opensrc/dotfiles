

# bootstrap functions
source ~/.bash_functions-bootstrap || \
 { echo -ne "Couldn't Import Bootstrap Functions.  This is bad; as in not good :(\n" >&2; \
   return 9; }

# do not allow this file to be executed
assert_is_sourced

# bring in some other aliases 
# (these are probably not available to you in the repo)
source_file_if_exists ~/.bash_aliases-tmp
source_file_if_exists ~/.bash_aliases-priv
source_file_if_exists ~/bin/lks/bash_aliases

# common 'ls' aliases
alias ls='ls --color=auto'  # color for 'ls'; if interactive
alias sl='ls'               # typo correction ;)
alias ll='ls -l'            # long-listing
alias la='ls -A'            # short-listing, incl dotfiles (not '.' and '..')
alias lal='ls -Al'          # ditto; long-listing
alias lha='ls -Alh'         # ditto; human readable sizes
alias lah='lha'             # alt
alias lh='ls -lh'           # long-listing human readable sizes
alias lss="~/bin/ls-star"   # runs ls on globbed arguments; accepts dash-args

# df 
alias dfh='df -hl'
alias dfhl='dfh /'

# not very useful find shortcuts
alias f0='find . -type f -size 0'
alias ff='find . -maxdepth 1 -type f '
alias fd='find . -maxdepth 1 -type d '

# feh sensible 
alias fehz="feh -Z --scale-down -B black "

# vim -- open last file 
alias lvim='vim -c "normal '\''0"'

# sudo 
alias sk="sudo -k" # kill current sudo ticket
alias sv="sudo -v" # verify sudo cred ticket
alias un="sudo unshare -n sudo -i -u $(whoami) " # quick network isolation for a command  

# grep color
alias grep='grep --color=auto'

# typo fixer 
alias cd..='cd ..'
alias up='cd ..'

# ps related
alias po='ps -eo pid,ppid,stat,etime,args'
alias poz='zx ps -eo pid,ppid,stat,etime,args | afs -o 1'

# head and tail one
alias h1='head -n 1'
alias t1='tail -n 1'

# diff merge
alias dm="diff --line-format='%L' "

# git log aliases
alias gl='git log --oneline --decorate=full --all --graph'
alias gls='git log --oneline --decorate=full --all --graph --simplify-by-decoration'
alias glp='git log -p' 
alias gln='git log --name-status --pretty="%h%d" | grep -v "^$" | sed -re "s/^[ACDMRTUXB]\W+/  &/"'
alias gno='git ls-files'
alias gsp='git status --porcelain'
alias gs='gsp | grep -v "^??"'
alias gd='git diff'
alias gcv='git commit -v'
alias gcva='gcv -a'
alias gcvp='gcv -p'
alias gcpv='gcvp'

if [[ -f ~/bin/vimgit ]]
then
  alias vg='vimgit'
  alias vgp='vimgit -p'
fi

# fzf shorthands 
alias fzfr="fzf -0 -1 -e -m +s --cycle --reverse +i --bind alt-space:toggle-all,alt-x:select-all --preview-window='wrap'"
alias fzfr_toggle_accept='fzfr --bind enter:toggle+accept'

# afs 
alias afs='awk_field_slicer'
alias afsp="afs -F'|'"

# sed -- sed replace newlines with pipes
alias rnp="sed -ne ':^;N;\$!b^;s/\n/|/g p'"
# sed -- sed replace newlines with pipes or just print if no newline
alias snp="sed -ne ':.;\$p;:^;N;\$!b^;s/\n/|/g; t.;'"

# apt-get/cache
alias ag="apt-get"
alias ac="apt-cache"
alias agi="ag install"

alias rp="realpath"

## xbuffer utils -- 
# p := primary 
# s := secondary 
# b := clipboard

# most of the xbuffer stuff only makes sense when combined with .bash_binds,
# alongside some other scripts.  none of which are up here yet ;) 

# xbuffer stuff 
alias xfs='xs_ftype_split'

# mv xbuffers around
alias xbp='xclip -o -selection clipboard | xclip -i -selection primary'
alias xbs='xclip -o -selection clipboard | xclip -i -selection secondary'
alias xpb='xclip -o -selection primary   | xclip -i -selection clipboard'
alias xps='xclip -o -selection primary   | xclip -i -selection secondary'
alias xsb='xclip -o -selection secondary | xclip -i -selection clipboard'
alias xsp='xclip -o -selection secondary | xclip -i -selection primary'
# clear xbuffers
alias xxc='echo '' | { xclip -i -selection primary; xclip -i -selection secondary; xclip -i -selection clipboard; }'

# merge xbuffers
alias mps='{ xp; echo; xs; } | xs_set_fzf_inline'
alias mpb='{ xp; echo; xb; } | xs_set_fzf_inline'
alias msp='{ xs; echo; xp; } | xs_set_fzf_inline'
alias msb='{ xs; echo; xb; } | xs_set_fzf_inline'
alias mbp='{ xb; echo; xp; } | xs_set_fzf_inline'
alias mbs='{ xb; echo; xs; } | xs_set_fzf_inline'

# output contents of xbuffer
alias xp='xclip -o -selection primary'
alias xs='xclip -o -selection secondary'
alias xb='xclip -o -selection clipboard'

# yay for moretools & vipe! Cat-skinned :)
# edit primary x buffer 'inplace'
alias xcv="xclip -o -selection primary | vipe | xclip -i -selection primary"
# edit a chosen x buffer, and replace contents of another chosen x buffer (can be the same one)
alias xcx="xs_get_fzf_inline | vipe | xs_set_fzf_inline"

# used in binds shortcuts
alias ii="IFS=$'\n'"
alias io="IFS=$' \t\n'"

# tree + fzf + afs list/select files
alias treez="tree --noreport -f -C -tr | fzfr --ansi | afs -F'── ' -m 2"
alias tz="treez"
alias t="treez "

# Avoid 'procan' typo ;)
alias procan='echo "Procan Sends Data Without Asking...Abort! Abort! Abort!"'

# typical iptsfilter usage
alias iptsf="sudo iptables-save | iptsfilter"

# docker stuff
source_file_if_exists "${PROJPATH}/docker/bash/docker_aliases"
source_file_if_exists "${PROJPATH}/docker/bash/docker_functions" #this should probs be done in .bash_functions

