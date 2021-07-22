############################################################################# 
##  WARNING: I have anonimized this file somewhat.                         ##
##  Therefore some things which are expected might be missing...           ##
##                  ...and other things might not be relevant to you.      ##
##  e.g., such as setting the PATH variable, and HISTIGNORE settings, etc  ##
#############################################################################

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# function to source other stuff
function source_file_if_exists(){

  if [[ -r "${1}" ]]
  then
    source "${1}"
  fi

}

# Don't forget to set your PATH variable accordingly ;P
# export PATH=

# append to histfile 
shopt -s histappend
# re-calculate COLS/LINES after every command (or SIGWINCH)
shopt -s checkwinsize
# allow bash globbing '**' matching rules 
shopt -s globstar

# UTF-8 
export LANGUAGE="en_GB.utf8"
export LC_ALL="en_GB.utf8"

## The only case where we wish 'less' was 'more' ;)
export PAGER="less -SEX"

# infinite history; just remember to back it up if it's important 
export HISTCONTROL=ignoreboth
export HISTIGNORE="xx:xs:xp:xb:xps:xpb:xsp:xpb:xbp:xbs" # bash_binds / xclip buffer stuff
export HISTSIZE=-1
export HISTFILESIZE=-1

# term; editor; gopath
export TERM=xterm-256color
export EDITOR=vim


# bring in aliases and functions and set path
# (pathnames moved to protect the innocent ;))
source_file_if_exists ".bash_paths"
source_file_if_exists ".bash_aliases"
source_file_if_exists ".bash_functions"

# can't remember why BIND_OVERRIDE is useful ;); 
# probably used it to switch off custom binds whilst testing
BIND_OVERRIDE="${BIND_OVERRIDE:-0}"
if [[ BIND_OVERRIDE -eq 0 ]]; 
then
  source_file_if_exists ".bash_binds"
fi

# turn on elipsis shortening of directory names in PS1 evaluation
# keep last to elements, i.e., [/long/path/to/nested/dir] -> [.../nested/dir]
export PROMPT_DIRTRIM=2

# personalised primary prompt
# i.e., "[03:14:15][user@host][~/.../some/path]: "
export PS1="[\[\e[38;5;24m\]\t\[\e[00m\]][\[\e[38;5;65m\]\u@\h\[\e[00m\]]\[\e[00m\][\[\e[38;5;173m\]\w\[\e[00m\]]: "
#source DOTFILES/.bash_completions/*



LS_COLORS="rs=00:di=38;5;32:ln=38;5;70:mh=00:pi=38;5;208:so=38;5;134:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=48;5;36;38;5;232:ow=48;5;28;38;5;234:st=37;44:ex=38;5;29:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:"
