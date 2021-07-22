## some functions
## lots of which make use of fzf; which may, or may not be a sacrilege ;)

# bootstrap functions; currently only 'source_file_if_exists' ;)
source ~/.bash_functions-bootstrap || \
 { echo -ne "Couldn't Import Bootstrap Functions.  This is bad; as in not good :(\n" >&2; \
   return 9; }


#force this:
assert_is_sourced

# stuff that contains private vars, etc...
# I may split stuff into functional blocks at somepoint(?)
source_file_if_exists ~/.bash_functions-priv

# recursively find world-writable files
# use with ~/bin/chmod_sensible for example
function fww(){
  find "${1:-.}" \( -type f -o -type d \) -a -perm /o=w ! -perm -1000
}

# e.g., cd into location of a file
# c /path/to/file -> cd /path/to
function c(){
  cd "$(dirname $1)"
}

# cd-make; make a dir and cd into it; 
function cdm(){
  #( [[ ! -e "${1}" ]] && mkdir -p "${1}" ) || cd "${1}" -- boolean algebra 
  if [[ ! -e "${1}" ]]
  then 
    mkdir -p "${1}"
  fi

  cd "${1}"

}

# yet another fzf related cd function ;) 
function zcd(){
    cd "$( find ${1:-.} -maxdepth 1 -type d -exec realpath '{}' \; | sort | fzfr +m --preview='echo {}' --preview-window='wrap' )"
}

# now a file in ~/bin for some reason ;)
#function now(){
# date '+%Y%m%d_%H%M%S' 
#}

# lbf -- locate bash function function
function lbf(){
  shopt -s extdebug

    declare -F "${1}"

  shopt -u extdebug
}

# ebf -- edit bash function 
function ebf() {
 
  fdef=( $( lbf "${1}" ) )
  fname="${fdef[2]}"
  lnum="${fdef[1]}"

  if [[ -n "${fname}" && -n "${lnum}" ]]
  then
    ${EDITOR:-vim} ${fname} +${lnum}
  else
    echo -ne "\nCouldn't find anything for \"${1}\"\n\n"
  fi  

} 

# bash auto-complete on functions for {e,l}bf
complete -A function lbf
complete -A function ebf

# dm: diff --line-format='%L'
function dmi(){
 
  # get current noclobber status 
  clob="$( set +o | grep noclobber )"

  # allow user to specify force flag; forces overwrite of existing merge file
  force=1
  OPTIND=
  while getopts 'f' flag
  do
    case "${flag}" in
      f)force=0;;
    esac

    shift $(( ${OPTIND} - 1 ))
    OPTIND=
  done

  # '+' == off // '-' == on 
  # on/off VAR/noVAR  -- you work it out ;)
  if [[ ${force} -eq 0 ]]
  then
    set +o noclobber
  else
    set -o noclobber 
  fi

  # generate filname from input filenames 
  foname="${1}_${2}.merged"

  # merge files with diff and if this produces output
  # cat the stream into a file, and echo the filename to stdout
  diff --line-format='%L' "${1}" "${2}" | ifne cat - >"${foname}" && echo "${foname}"

  # return noclobber status
  ${clob}

} &&
complete -f dmi # complete on filenames

# use fzf to parse/select apropos output
function apropoz(){

  show_cstd=1
  OPTIND=
  while getopts 'C' flag
  do
    case "${flag}" in
      C) show_cstd=0;;
    esac
    shift $(( OPTIND - 1 ))
    OPTIND=
  done

  q=""
  if [[ ${show_cstd} -ne 0 ]]
  then
    # use fzf query syntax to filter out std library stuff by default
    q="--query !^std::"
  fi

  x="$( apropos ${@} | fzfr ${q} )"
  section=$( echo ${x} | cut -d' ' -f 2 | sed 's/[()]//g' )
  topic=$(   echo ${x} | cut -d' ' -f 1 )
  man ${section} ${topic}

}


# use fzf to parse/select output of 'ps'
# may, or may not be similar to 'alias:poz'
function psz(){

  tree=1
  OPTIND=
  while getopts 't' flag
  do
    case "${flag}" in
      t)tree=0;;
  esac
    shift $(( OPTIND - 1 ))
  done

  query=""
  if [[ $# -gt 0 ]]
  then  
    query="-q ${@}"
  fi
  pids=""

  if [[ ${tree} -eq 0 ]]
  then
   IFS=$'\n' pids=( $( pstree -aplcn | fzfr ${query} --preview-window='wrap' --preview='echo {}' | sed -e 's/.*,\([0-9]\+\).*/\1/' ) )
  else
   IFS=$'\n' pids=( $( ps -u $(whoami) -f | lli -s 2 | fzfr ${query} --preview-window='wrap' --preview='echo {}' --tac --nth=2,3,8.. | afs -o 2 ) )
  fi

  if [[ -n "${pids}" ]]
  then

   echo "${pids[*]}"

  fi
}

# kill pids selected with 'psz'
function kfu(){
  
  nine=""
  OPTIND=
  while getopts '9' flag
  do
  case "${flag}" in
    9) nine="-9";;
  esac
    shift $(( OPTIND - 1 ))
  done


  pids="$( psz ${@} )"
  echo "kill ${nine} ${pids}" | tee /dev/tty | xclip -i -sel pri
  kill ${nine} ${pids}

}

# apt-cache-search w/fzf
function acs(){
  if [[ $# -eq 0 ]]
  then
    pkgs="."
  else
    pkgs="${@}"
  fi

  acsret="$( apt-cache search "${pkgs}" | fzf -0 -e -m +s --cycle --reverse +i --bind alt-space:toggle-all | awk_field_slicer -o 1 )" 
  multi="$( echo ${acsret} | sed -n '/./ N; s/\n/ / p' )"
  acsret="${multi:-${acsret}}"
  echo ${acsret}
 
}

# apt search n' install w/fzf
function asni() {
  dryrun=""
  drunmsg=""
  if [[ "${1}" == "-n" ]]
  then
    dryrun="-s " # space required
    drunmsg="[dryrun] "
    shift
  fi

  #fzf/awk slice apt-cache-search
  progs="$( apt-cache search "${@}" | fzf -0 -e -m +s --cycle --reverse +i --bind alt-space:toggle-all | awk_field_slicer -o 1 )"
  # if nothing found, do nothing
  if [[ "x${progs}" == "x" ]]
  then
    echo -ne '...Nothing To Do.\n\n'
    return 1
  fi

  # if only one selected, the sed returns empty; so we handle that here
  multi="$( echo "${progs}" | sed -n '/./ N; s/\n/ / p' )"
  progs="${multi:-${progs}}"

  # could check for verbose..etc...
  apt-cache show ${progs} | less -S

  # save selection in primary xbuffer 
  echo "${progs}" | xclip -i -sel pri

  # ask for confirm
  read -p "${drunmsg}sudo apt-get install ${dryrun}${progs} [y/N]? " ans
  case "${ans}" in
    Y|y) sudo apt-get install ${dryrun} ${progs} | tee /dev/tty | xclip -i -sel sec;;
      *) echo -ne '...Aborted.\n\n';;
  esac

}

# dpkg 'find' w/fzf
function dpkgf(){
  dpkg -l | lli -s 6 | fzf --query="${@}" -0 -e -m +s --cycle --reverse +i --bind alt-space:toggle-all | awk_field_slicer -o 2
}

# dpkg 'show' (actually apt-cache show) w/fzf
function dpkgs(){
 desc_only=1
 OPTIND=
 while getopts 'd' flag
 do
  case "${flag}" in
    d) desc_only=0;;
  esac
 shift $(( OPTIND - 1 ))
 done

 if [[ $# -gt 0 ]]
 then
   pkg="${@}"
 else
   pkg="$( dpkgf )"
 fi

 echo "${pkg}" | xclip -i -sel pri
 if [[ ${desc_only} -eq 0 ]]
 then
   pkgshow="$( apt-cache show ${pkg} | awk '/Description/{f++} f; f>1 {exit}' | head -n -1 )" 
 else
   pkgshow="$( apt-cache show ${pkg} )"
 fi

 echo "${pkgshow}" | xclip -i -sel sec
 echo "${pkgshow}" | less -SX
}

# dpkg 'list-files' w/fzf
function dpkgl(){
 dpkg -L $( dpkgf "${@}" )
}

# select a python virtualenv w/fzf
function pyvirt(){

  pv=""
  pv="$( ls -1 ~/Pyvirts | fzf --reverse +s --query="${@}" -1  )"

  if [[ -n "${pv}" ]]
  then
    source ~/Pyvirts/${pv}/bin/activate
  else
    echo -ne "\nNo virtualenv chosen.  Nothing to do.\n\n"
  fi

}

# could be useful ;)
# function has_input_pipe(){

# if [[ -p /dev/stdin ]]
#  then
#   return 0
#  else
#   return 1
#  fi

# }

# function assert_has_input_pipe(){
#  if [[ has_input_pipe -ne 0 ]]
#  then
#   echo -ne "\nError! No Piped Input\n\n" >&2
#   return 1
#  fi

# }

# list specified paths in reverse time modified order
# outputs realpaths; this can <s>probably</s> certainly be improved :D !
function lsd(){
 
  if [[ $# -eq 0 ]]
  then
    set -- .
  fi

  ds=()
  for a in "${@}"
  do
    a=$(realpath "${a}")
    if [[ -d ${a} ]]
    then
      ds+=("${a%/}"/*) 
    else
      ds+=("${a}")
    fi
  done
  set -- "${ds[@]}"  

  ls -d1rt "${@}" 2>/dev/null

}

# return fst line of cmd output
alias f="fst"
function fst(){
  "${@}" | head -n 1
}

# return last line of cmd output 
alias l="lst"
function lst(){
  "${@}" | tail -n 1
}

# cmd output into fzf w/preview
function zx(){
 "${@}" | fzfr --preview='echo {}' --preview-window='wrap'
}

# cmd output into xbuffer using fzf (w/edit)
function zX(){
  "$@" | xs_set_fzf_inline -e 
}

# cmd output into xbuffer using fzf (w/o edit)
function Z(){
  "$@" | xs_set_fzf_inline 
}

# lsd output into xbuffer using fzf (w/ edit)
function zl(){
  zX lsd "${@}"
}

# Limit LInes -- use sed to limit lines to an output range
# i.e., a fancy version of: sed -n '${1},${2} p' "${@}"
function lli(){

  s='1' # first line
  e='$' # last line
  o=    # only line 
  O=-1  # offset
  q='$'

  OPTIND=
  while getopts 's:e:o:O:' flag
  do
   case "${flag}" in
    s) s=${OPTARG};;
    e) e=${OPTARG};;
    o) o=${OPTARG}; s=${o}; e=${o};;
    O) O=${OPTARG};;
   esac
   shift $(( OPTIND - 1 ))
   OPTIND=
  done

  if [[ ${O} -gt 0 ]]
  then
    e=$(( ${s} + ${O} - 1 ))
  fi

  # if e(nd) isa number; quit after e+1 lines
  if [[ ${e} =~ [0-9]+ ]]
  then
    q=$(( ${e} + 1 ))
  fi

  sed -n "${s},${e} p; ${q}q" "${@}"

}

# select an individual line using 'lli'
function lN(){
  lnum=${1:-1}
  lli -o ${lnum} 
}

# use tree + fzf to list and filter directories; then cd into selected dir
# instead of using a filemanager like ranger... ;P
# aka. enthusiasm for fzf can go too far ;)
alias xcd="tcd "
alias xcdh="xcd -h -I '.git'"
function tcd(){
  
  incl_hidden=""
  ign=""
  larg=""
  lval=
  OPTIND=
  while getopts 'hI:L:' flag
  do
    case "${flag}" in
      h)  incl_hidden="-a";;
      I)  ign="-I --matchdirs ${OPTARG}";;
      L)  larg="-L"; lval=${OPTARG};;
    esac
    shift $(( OPTIND - 1 ))
  done

  IFS=$'\n'
  
  d=$( tree ${larg} ${lval} --noreport -C ${ign} ${incl_hidden} -d -f -c "${@}" | fzf -0 -1 -e +m +s --cycle --reverse +i --ansi )
  echo "${d}" | grep -q '── ' 2>/dev/null
  if [[ $? -eq 0 ]]
  then
    # look at the nice use of multi-char field separator with afs/awk_field_separator ;)
    d=$( echo "${d}" | afs -F'── ' -m 2 )
  fi

  cd ${d:-.}

  IFS=$' \t\n'
}


# get network usage stats
alias vd="vnstatd -d --noadd --config ~/.config/vnstat/vnstat.conf"
alias vn="vnstat --config ~/.config/vnstat/vnstat.conf -i "

# use fzf to select an interface on which to monitor
function vns() {
  sudo vnstat -l -i $( ip link | grep '^[0-9]' | cut -d':' -f 2 | tr -d ' ' | fzf --reverse --tac -1 +s -q "${@:-}" )
}

# vlc play-from-last-known-position-with-minimal-ui
function vlcq(){
 vlc -I qt --qt-continue 2 --qt-minimal-view "${@}" &>/dev/null &
}

# primary buffer to temp file
# mostly superceded by 'alias:xcv'
function ptv(){
  tf=$(mktemp)
  xclip -o -selection primary | vim - +"file ${tf}"
}

# get du stats in human readable format, for 'args/*'
# sort by size, lowest to highest, w/optional 'total'
alias dS="ds -t"
function ds(){

  d=1 # dirsonly
  n=1 # names only
  t=1 # show total 

  OPTIND=
  while getopts 'dnt' flag
  do
   case "${flag}" in
    d) d=0;;
    n) n=0;;
    t) t=0;;
   esac
   shift $(( ${OPTIND} - 1 ))
   OPTIND=
  done

  if [[ ${t} -eq 0 && ${n} -ne 0 ]]
  then 
    dargs="-sxhc"
  else
    dargs="-sxh"
  fi

  if [[ $# -eq 0 ]]
  then
    set -- ./*
  else
    if [[ ${d} -ne 0 ]]
    then
      ds=()
      for a in "${@}"
      do
        a=$(realpath "${a}")
        if [[ -d ${a} ]]
        then
          ds+=("${a%/}"/*) 
        else
          ds+=("${a}")
        fi
      done
      set -- "${ds[@]}"  
    fi
  fi

  if [[ ${n} -eq 0 ]] 
  then
    du ${dargs} "${@}" | sort -h | afs -m 2
  else
    du ${dargs} "${@}" | sort -h 
  fi

}

# top 10 largest entities
alias dsT="dst -t"
function dst() {
  ds "$@" | tail
}

# triple-x; not that exciting really: switch primary and secondary xbuffers (mem-bound)
function xxx(){
  p="$( xclip -o -selection primary   2>/dev/null )"
  s="$( xclip -o -selection secondary 2>/dev/null )"

  echo "${p}" | xclip -i -selection secondary 
  echo "${s}" | xclip -i -selection primary
}

# also used in .bash_binds 
alias xx='xsel_show'
function xsel_show() {

  p="$( xclip -o -selection primary   2>/dev/null )"
  s="$( xclip -o -selection secondary 2>/dev/null )"
  b="$( xclip -o -selection clipboard 2>/dev/null )"

  echo -ne "\nPrimary:\n${p}\n\nSecondary:\n${s}\n\nClipboard:\n${b}\n\n"
  
}

# set title of current window
function set_title() { printf '\e]2;%s\a' "$*"; }

# run 'cmnd --help' and send output to stdout
function help() {
  ${@} --help 2>&1
}

