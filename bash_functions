#!/bin/bash 
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
source_file_if_exists "${PROJPATH}/docker/bash/docker_functions" #this should probs be done in .bash_functions
source_file_if_exists "${PROJPATH}/docker/bash/docker_completion" #this should probs be done in .bash_functions

function prepend-path(){

  [[ -d "${1}" ]] && { export PATH="$(realpath ${1}):${PATH}"; echo  "${PATH}"; } || echo -ne "\n Dir Not Acceptable: \"${1}\"\n\n" >&2; }

# bit hackish -- but tired of 'less <dir>'
# either by typo or autocompletion ;)
function less(){

  if [[ $# -eq 1 && -d "${1}" ]]
  then
    ls "${1}"
  else
   /usr/bin/less "${@}" 
  fi
}

# recursively find world-writable files
# use with ~/bin/chmod_sensible for example
function fww(){
  find "${1:-.}" \( -type f -o -type d \) -a -perm /o=w ! -perm -1000
}

# e.g., cd into location of a file
# c /path/to/file -> cd /path/to
alias c="cdf"
function cdf(){

  #local fullpath="$( readlink -f ${1} )"
  IFS=$'\n'
  local fullpath="${1}"
  if [[ -n "${fullpath}" && ! -d "${fullpath}" ]]
  then
    cd "$( dirname ${fullpath} )"
  else
    cd "${fullpath}"
  fi
  IFS=$' \t\n'
}

# cd-make; make a dir and cd into it; 
function cdm(){

  #( [[ ! -e "${1}" ]] && mkdir -p "${1}" ) || cd "${1}" -- boolean algebra 
  if [[ -n ${1} && ! -e "${1}" ]]
  then 
    mkdir -p "${1}"
  fi

  cd "${1:-${HOME}}"

}

# yet another fzf related cd function ;) 
function zcd(){
    IFS=$'\n'
      cd "$( find ${1:-.} -maxdepth 1 -type d -exec realpath '{}' \; | \
            sort | fzfr +m --preview='{ echo -e "{}\n"; ls --color=always --group-directories-first -F {}; }' --preview-window='top:45%:wrap' --bind 'alt-f:preview-page-down,alt-r:preview-page-up,alt-w:up,alt-s:down,alt-e:accept' )"
    IFS=$' \t\n'
}
complete -o dirnames zcd

function glf(){

  # get last file by mod-date
  local lfile="$( ls -1rt | stest ${1:--f}| tail -n 1 )"
  # get realpath of file
  lfile=$( realpath "${lfile}" 2>/dev/null )
  # if [[ -e "${lfile}" ]]
  # then
  echo -ne "${lfile}"
  # else
  #   echo "Empty!" >&2
  # fi
}
alias gld="glf -d"
alias cdld="cd $( glf -d )"

# remove last file (force)
alias rlff="yes | rlf"
function rlf(){

  # get last file
  lfile="$(glf)"
  # if file exists, ask user to delete it
  [[ -f "${lfile}" ]] && rm -i "${lfile}" || echo -ne "Cannot delete! (improve the script to see why ;))\n" >&2

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

# cbf -- cd to bash function
# has to be 3 letters because the other '.bf' functions are ;)
function cbf(){
  
  c "$( realpath $( lbf ${1} | afs -m 3 ) )"

}

function cdl(){

  if [[ -d "${_}" ]]
  then
    cd "${_}"
  elif [[ -f "${_}" || -h ${_} ]]
  then
    c "${_}"
  else
    echo "Cannot cd into \"${_}\"" >&2
  fi

}


# sbf -- show bash function function
alias sbfc="sbf -s"
function sbf(){
  
  SYNT=1
  VIPE=1
  OPTIND=
  while getopts 'sv' flag
  do
   case "${flag}" in
    s) SYNT=0;;
    v) VIPE=0;;
   esac
   shift $(( ${OPTIND} - 1 ))
   OPTIND=
  done

  shopt -s extdebug
    if [[ ${VIPE} -eq 0 ]]
    then
      declare -f "${@}" | vipe
    else
      if [[ ${SYNT} -eq 0 ]]
      then
        declare -f "${@}" | source-highlight -s sh -f esc 
      else
        declare -f "${@}"
      fi
    fi

  shopt -u extdebug

}

# bash auto-complete on functions for {e,l}bf
complete -A function lbf
complete -A function ebf
complete -A function sbf sbfc

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

  local tree=1
  OPTIND=
  while getopts 't' flag
  do
    case "${flag}" in
      t) tree=0;;
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
    IFS=$'\n' pids=( $( ${sudo} pstree -aplcn | fzf ${query} -e -m +s --cycle --reverse +i --bind alt-space:toggle-all,alt-x:select-all,alt-c:toggle --preview-window='wrap' ) )
  else
    IFS=$'\n' pids=( $( ${sudo} ps -ef | lli -s 2 | fzf ${query} -e -m +s --cycle --reverse +i --bind alt-space:toggle-all,alt-x:select-all,alt-c:toggle --preview-window='wrap' --preview='echo {}' --tac | afs -o 2 ) ) #--nth=2,3,8.. | afs -o 2 ) )
  fi

  if [[ -n "${pids}" ]]
  then
    echo "${pids[*]}"
  fi
}

# kill pids selected with 'psz'
function kfu(){
  local sudo="" 
  local nine=""
  local incself=1
  OPTIND=
  while getopts 'NSi' flag
  do
  case "${flag}" in
    N) nine="-9";;
    S) sudo="sudo";; 
    i) incself=0;;
  esac
    shift $(( OPTIND - 1 ))
    OPTIND=
  done

  if [[ ${incself} -eq 0 ]]
  then
    # TODO:
    pids=( "$( ps -ef | awk -v ppid=$$ '( $2 ~ ppid )' )" )
    echo ${pids[@]}
    return 0
  else
    pids=( "$( psz ${@} )" )
  fi

  echo "${sudo} kill ${nine} ${pids[@]}" | xclip -i -sel pri
  ${sudo} kill ${nine} ${pids[@]}

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
  local dryrun=""
  local drunmsg=""
  if [[ "${1}" == "-n" ]]
  then
    dryrun="-s " # space required
    drunmsg="[dryrun] "
    shift
  fi

  if [[ "${1}" == "-N" ]]
  then
    dryrun="--no-install-recommends "
    shift
  fi


  #fzf/awk slice apt-cache-search
  local aptout="$( apt-cache search ${@})"
  progs="$( echo "${aptout}" | fzf -0 -e -m +s --cycle --reverse +i --bind 'alt-space:toggle-all,alt-q:abort' | awk_field_slicer -o 1 )"
  # if nothing found, do nothing
  if [[ "x${progs}" == "x" ]]
  then
    echo -ne '...Nothing To Do.\n\n'
    echo "${aptout}" | xclip -i -sel sec
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
   pkgshow="$( apt-cache show ${pkg} | awk '/Description/{f++} f; f>1 {return}' | head -n -1 )" 
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

# select a node virtualenv w/fzf
function novirt(){

  pv=""
  pv="$( ls -1 ~/Novirts | fzf --reverse +s --query="${@}" -1  )"

  if [[ -n "${pv}" ]]
  then
    source ~/Novirts/${pv}/bin/activate
  else
    echo -ne "\nNo virtualenv chosen.  Nothing to do.\n\n"
  fi

}

function loc(){

  locate -r "${@}" | xs_chop -p -e

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


alias fff="ff -f"
function ff(){

  local hidden=1
  local maxdepth=""
  local fname=""
  local type="f"
  local dryrun=""

  local usg="
  Usage: ${FUNCNAME[0]} [-afntL] [ -h | --help ]

    -a          := include hidden files (default: no)
    -t <f|d|l>  := type [file,dir,link] (default: file)
    -f <fname>  := search for '*fname*' (default: **) 
    -h | --help := This help msg. :)
    -n          := "dryrun" / echo find command that would be run
    -L <int>    := set maxpdepth to <int> (default: 1)

"

  # -a := show all
  # -L := specify maxdepth

  source ~/Projects/dotfiles/bash_functions-util 
  declare -A pargs
  declare -A arg_list=( ["-a"]=0 ["-L"]=1 ["-n"]=0 ["-f"]=1 ["--help"]=0 ["-h"]=0 ["-t"]=1)

  parse_args pargs arg_list "${@}"

  if [[ ${pargs["-h"]} || ${pargs["--help"]} ]]
  then
    echo -ne "${usg}"   
    return 0
  fi

  if [[ ${pargs["-a"]} ]]
  then
    hidden=0
    unset 'pargs["-a"]'
  fi

  if [[ ${pargs["-L"]} ]]
  then
    maxdepth="-maxdepth ${pargs["-L"]}"
    unset 'pargs["-L"]'
  fi

  if [[ ${pargs["-f"]} ]]
  then
    fname="${pargs['-f']}"
    unset 'pargs["-f"]'
  fi

  if [[ ${pargs["-n"]} ]]
  then
    dryrun="echo [dryrun] "
    unset 'pargs["-n"]'
  fi

  if [[ ${pargs["-t"]} ]]
  then
    type="${pargs["-t"]}"
    unset 'pargs["-t"]'
  fi

  set -- ${pargs[@]}

  if [[ ${hidden} -eq 0 ]]
  then
    ${dryrun} find "${1:-.}" ${maxdepth} -type ${type} -name "*${fname}*"
  else
    ${dryrun} find "${1:-.}" ${maxdepth} -type ${type} -a ! -name '.*' -a -name "*${fname}*" 
  fi

}

# list specified paths in reverse time modified order
# outputs realpaths; this can <s>probably</s> certainly be improved :D !
function lsd(){
  
  local col="auto"

  if [[ $# -gt 0 && "${1}" == "-C" ]]
  then  
    col="always"
    shift
  fi

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

  # 
  ls --color=${col} -d1rt "${@}" 2>/dev/null

}

# return fst line of cmd output
# alias f="fst"
function fst(){
  "${@}" | head -n 1
}

# return last line of cmd output 
# alias l="lst"
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


function zf(){

  IFS=$'\n'
  "${@}" $( zlsd )
  IFS=$' \t\n'

}

alias zl='zlsd'
# lsd output into xbuffer using fzf (w/ edit)
function zlsd(){
  lsd -C "${@}" | fzf -0 -1 -e -m +s --cycle --reverse --bind 'alt-space:toggle-all,alt-x:select-all,alt-c:execute( echo -e "{+}" | xs_chop -I )' --ansi
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

alias afc="awk_field_counter"
function awk_field_counter(){
  
  AFS=" "      # awk field sep
  acount="NF" # thing to count (number of fields) 

  OPTIND=
  while getopts 'F:s' flag
  do
    case "${flag}" in
      F) AFS="${OPTARG}";;
      s) acount="NF - 1";; # count number of separators
    esac

    shift $(( ${OPTIND} - 1 ))
    OPTIND=
  done

  # run awk
  awk -F"${AFS}" "{ printf(\"%s\n\", ${acount} ) }"

}


# go up n dirs; default 1
# Horrendously Functional ™
function up(){

  if [[ "${PWD}" == "/" ]]
  then
    echo "You cannot 'up' from root. ;)" >&2
    return 1
  fi

  # default to '..'
  path="${1:-..}"

  if [[ $# -eq 1 ]]
  then

    # if user specifies a number
    if [[ ${1} =~ ^[0-9]+$ ]]
    then 

      # generate relative path upto that number of levels, i.e.,
      # shell> up 2 => ../../
      path="$( printf '../%.0s' $( seq 1 ${1} ) )"

    elif [[ -d "${1}" ]]
    then


      if [[ "${1}" == "${PWD}" ]]
      then

        echo "Already here: \"${PWD}\"" >&2
        return 2
      
      fi

      # always reachable!
      if [[ "${1}" == "/" ]]
      then

        path="/"

      else

        # test that this path is somewhere directly above "${PWD}"

        # realpath of user-specified path
        upath="$( realpath -e "${1}" )"

        # depth of same
        udepth=$( echo "${upath}" | afc -F'/' )

        # current depth
        cdepth=$( echo "${PWD}"   | afc -F'/' )

        # if the supplied path is shorter than current
        # it might be 'up'
        if [[ ${udepth} -lt ${cdepth} ]]
        then

          # get sub-path of current path;
          # take same length as user-specified path from '/'
          subpath="$( echo ${PWD} | afs -F'/' -l ${udepth} )"

          # requested subpath is further up the tree... 
          if [[ "${subpath}" == "${upath}" ]]
          then
            path="${subpath}" 
          else
            echo "Cannot reach requested path: \"${upath}\"" >&2
            return 3
          fi

        fi

      fi

      else
        echo "Argument must be numeric, or a valid directory! (\"${1}\")" >&2
        return 4
      fi

   fi

  cd "$( realpath "${path}" )"

}

# Hartigan's Law: for every bash function there must exist another, of equal power and opposite alignment. ;)
# choose a directory at random and descend into it ;)
function down(){

  n=1 

  if [[ ${1} =~ ^[0-9]+$ ]]
  then 
    n=${1}
  fi

  IFS=$'\n' 
    pdirs=( $( find . -maxdepth ${n} -type d ! -path '.' ) )

  rnd=${RANDOM}
  pmod=${#pdirs[@]}

  if [[ ${pmod} -gt 0 ]]
  then
    let "rnd %= ${pmod}"
    cd "$( realpath ${pdirs[${rnd}]} )"
  else
    echo "cannot 'down' from leaf." >&2
  fi

  IFS=$' \t\n'

}

function randChars2(){

  local f=12;
  local l=1; 

  local cset="$( echo {A..Z} {0..9} | tr -d ' ' )"
  
  usg="\n  ${FUNCNAME[0]} [-c <cset>] [-f <fold>] [-h] [-l <lines>]\n\n    cset := {A..Z} {0..9}\n\n"
 
  OPTIND=
  while getopts ':c:f:hl:' flag
  do
   case "${flag}" in
    c) cset="$( echo ${OPTARG} | tr -d ' ' )";;
    f) f=${OPTARG};;
    l) l=${OPTARG};;
    \?|h) echo -ne "${usg}"; return 0;;
   esac
   shift $(( ${OPTIND} - 1 ))
   OPTIND=
  done

#cset=$( echo ${@} | tr -d ' ' )
  for x in $( seq 1 $(( ${f} * ${l} ))  )
  do 
    echo -n "${cset:RANDOM%${#cset}:1}" 
  done | fold -w ${f}
  echo ""

}

function randChars(){

  local f=12;
  local l=1; 

  # default hex
  local cset="A-Z0-9"

  usg="\nUsage: ${FUNCNAME[0]} [-c <set>] [-f <fold>] [-l <lines>]
        -c := complementary set                 ( default: [A-Z0-9] )
        -f := fold-length; i.e., string length  ( default: 12 )
        -l := produce <lines> many strings      ( default: 1 )\n\n"

  OPTIND=
  while getopts ':c:f:l:' flag
  do
   case "${flag}" in
    c) cset="${OPTARG}";;
    f) f=${OPTARG};;
    l) l=${OPTARG};;
    \?|h) echo -ne "${usg}"; return 0;;
   esac
   shift $(( ${OPTIND} - 1 ))
   OPTIND=
  done

  cat /dev/urandom | tr -dc "${cset}" | fold -w ${f} | lli -e ${l} 

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
alias vnd="vnstatd -d --noadd --config ~/.config/vnstat/vnstat.conf"
alias vnt="vnstat --config ~/.config/vnstat/vnstat.conf -i "

# use fzf to select an interface on which to monitor
function vns() {
  sudo vnstat -l -ru 0 -i $( ip link | grep '^[0-9]' | cut -d':' -f 2 | tr -d ' ' | fzf --reverse --tac -1 +s -q "${@:-}" )
}

# vlc play-from-last-known-position-with-minimal-ui
function vlcq(){

  if [[ ${#} -eq 0 ]]
  then
    echo 'You need to specify a file...' >&2
    return 1
  fi

  local -a args=()
  for f in "${@}"
  do
    if [[ -r "${f}" ]]
    then
      args+=("${f}")
    else 
      echo "${f} not found" >&2
    fi
  done

  if [[ ${#args[@]} -gt 0 ]]
  then 
    vlc -I qt --qt-continue 2 --qt-minimal-view "${args[@]}" &>/dev/null &
  fi

}

function inVimShell(){
  lsof -w -c vim -a "$(tty)" &>/dev/null
  if [[ $? -eq 0 ]] 
  then
    echo "VIM OPEN ON THIS PTY"
  else
    echo "NOT IN VIM SUBSHELL"
  fi
}

checkSubShell(){
 
  FOR_PROMPT=1 
  quiet=1
  
  OPTIND=
  while getopts 'Pq' flag
  do
   case "${flag}" in
    P) FOR_PROMPT=0;;
    q) quiet=0;;
   esac
   shift $(( ${OPTIND} - 1 ))
   OPTIND=
  done

  SUBS_TO_LOOK_FOR="dpkg|vim|ranger|screen|bash|mc"
  pfor="$( ps --forest -ocomm | grep -E "${SUBS_TO_LOOK_FOR}" | sed -re '$!s/ +\\_ //g; $d' | sed -ne ':.;$p;:^;N;$!b^;s/\n/->/g; t.;' )" 
  # if [[ ${FOR_PROMPT} -eq 0 ]]
  # then
    # last="$( echo "${pfor}" | awk -F'->' '{ if( (NF-2) > 0 ){ print $(NF-2); } }' )"
  # else
    last="$( echo "${pfor}" | awk -F'->' '{ if( (NF-1) > 0 ){ print $(NF-1); } }' )"
  # fi
  
  if [[ "x${pfor}" == "x" || "x${last}" == "x" || ( "${pfor}" == "${last}" && "${last}" == "bash" ) ]]
  then

    if [[ ${quiet} -eq 0 ]]
    then
      return 1
    else
      #output for bash prompt usage
      if [[ ${FOR_PROMPT} -eq 0 ]]
      then
        echo "NoSub"
      else
        echo 'Not in a subshell.'
      fi
      return 1
    fi

  else
  
    if [[ ${quiet} -eq 0 ]]
    then
      return 0
    else
      if [[ ${FOR_PROMPT} -eq 0 ]]
      then
        echo "InSub:<${last}>"
      else
        echo "In <${last}> subshell! [${pfor}]"
      fi
    fi
 
 fi

}

#aname@k1,v1|k2,v2
fillArray(){

  # e.g., declare -A foo
  #       fillArray foo 'k1,v1|k2,v2|...'
  arrcont="${2}"

  declare -n arr="${1}" 

  IFS='|'
  for kv in ${arrcont}
  do

    k=$( echo "${kv}" | cut -d',' -f 1 )
    v=$( echo "${kv}" | cut -d',' -f 2 )

    arr["${k}"]="${v}"

  done
  IFS=$' \t\n'

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

  Q=1 # quote names
  d=1 # dirsonly
  n=1 # names only
  t=1 # show total 
  sudo= # sudo command

  usg="\n  Usage: ${FUNCNAME[0]} [-d] [-n [-Q]] [-S] [-t]

    -Q := quote names
    -S := sudo
    -d := don't descend into directories
    -n := print only the names in order
    -t := append total on the end\n\n"

  OPTIND=
  while getopts 'QSdhnt' flag
  do
   case "${flag}" in
    Q) Q=0; n=0;;
    S) sudo="sudo";;
    d) d=0;;
    n) n=0;;
    t) t=0;;
    h) echo -ne "${usg}"; return 0;;
   \?) return 1;;
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

    if [[ ${Q} -eq 0 ]]
    then
      ${sudo } du ${dargs} "${@}" | sort -h | afs -m 2  |sed -e 's/'\''/\\'\''/g' -e 's/"/\\"/g' -e 's/.*/'\''&'\''/'
    else
      ${sudo} du ${dargs} "${@}" | sort -h | afs -m 2 
    fi

  else
    ${sudo} du ${dargs} "${@}" | sort -h 
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
function set_title() { 

  if [[ $# -gt 0 ]]
  then
    export MANUAL_TITLE=0
    printf '\e]2;%s\a' "$*" 
    
  else 
    export MANUAL_TITLE=1
  fi


}

# run 'cmnd --help' and send output to stdout
function help() {
  ${@} --help 2>&1
  if [[ $? -ne 0 ]]
  then
    man ${@}
  fi
}

function rgb_to_ansi(){

  #rgb == "#rrggbb
  rgb=${1:1}

  # cpi  := char pair index
  # argb := ansi rgb
  argb=$( for cpi in $( seq 0 2 $(( ${#rgb} - 1 )) ); do printf '%d;' "0x${rgb:${cpi}:2}"; done; )
  argb="${argb%;}"
       #  '\\x1b[38;2;43;178;81m'
  printf '\\x1b[38;2;%sm' "${argb}" 


}

function ansi_to_rgb(){
  printf '#%x%x%x' $( echo "${1}" | cut -d';' -f 3-5 | tr -d 'm' | tr ';' ' ' )
}

function hex_to_rgb_float(){

s="${1:-#000000}"
rgb=$( for x in $( seq 1 2 6); do genius --maxdigits=2 --exec="0x${s:x:2} / 0xff + 0.0"; done | sed -ne ':.;$p;:^;N;$!b^;s/\n/, /g; t.;' )

echo "{ ${rgb}, 1.0 }"
}

function find_links(){

  while read line
  do

    fname=$( echo ${line} | cut -d'|' -f 1 )
    lname=$( echo ${line} | cut -d'|' -f 2 ) 

    if [[ "${lname}" == "$( readlink ${fname} )" ]]
    then
      echo -ne "${fname}|$(rgb_to_ansi "#00ff00" )${lname}\n"
    else
      echo -ne "${fname}|$(rgb_to_ansi "#ff0000" )${lname}\n"
    fi

  done < <( find . -maxdepth 1 -type l -printf '%f|%l\n' )

}

function vimlast(){

  local lfile="/tmp/vtemp.lock"
  local last_file="/tmp/vtemp.last"


  (

    flock -n 9 || { echo "Couldn't Get Lock ${lfile}"; exit 1; }
    if [[ $# -eq 1 && "${1}" == "-p" ]] 
    then
      cat "${last_file}"
    else
      vim "$( cat ${last_file} )"
    fi

  ) 9>"${lfile}"

}

function tar_auto_unpack() {

  local fusename=1 # use the supplied file name?
  local cdir=
  local output=

  OPTIND=
  while getopts 'F' flag
  do
   case "${flag}" in
    F) fusename=0;;
   esac
   shift $(( ${OPTIND} - 1 ))
  done

  local mt="$( file -b --mime-type "${1}" )"
  local args=

  case "${mt}" in
    application/x-xz)    ftype_flag="-J";;
    application/x-bzip2) ftype_flag="-j";;
    application/gzip)    ftype_flag="-z";;
  esac

  if [[ ${fusename} -eq 0 ]]
  then
    local cname="tau/${1}" # assumes correct args 

    mkdir -p "tau"
    mkdir "${cname}"

    if [[ $? -ne 0 ]]
    then
      echo 'ERROR' >&2
      return 1
    fi

    cdir="-C ${cname}"
  
  fi

  while read tpath
  do
    echo "${cname:-.}/${tpath}"
  done <<< $( tar ${cdir} ${ftype_flag} -xvf "${1}" )

}


function mvp() {

  if [[ ${#} -ne 2 ]]
  then
    echo -ne '\nEgg. Need 2 args. src + dst.\n  e.g., mvp file.txt /some/dir/\n\n' >&2
    return 1
  fi

  local src="${1}"
  local dst="${2}"

  if [[ ! -d ${dst} ]]
  then
    echo -ne '\nEgg. dst must be a directory.\n\n' >&2
    return 2
  fi
 
  if [[ ! -r ${src} ]]
  then
    echo -ne '\nEgg. src must be a good ole regular file.\n\n' >&2
    return 3
  fi
 
  local srcrp="$( realpath ${src} )" 
  local sdir="$( dirname  ${srcrp} )"
  local sfil="$( basename ${src} )"
   
  local dst="$( realpath $dst )"
  local dstr="$( echo ${sdir} | sed -e 's|^/||' -e 's|/|-|g'  )"
  outstr=${dst}/${dstr}-${sfil}

  #mv: cannot move '../file1' to '/tmp/foo/nyar/tmp-foo-../file1': No such file or directory
  mv -i "${src}" "${outstr}"
}

function sincup(){

  local dryrun=
  local forward_only=1
  OPTIND=
  while getopts 'Fn' flag
  do
   case "${flag}" in
    n) dryrun='-n';;
    F) forward_only=0;;
   esac
   shift $(( ${OPTIND} - 1 ))
   OPTIND=
  done
  
   left="${1%/}/"  
  right="${2%/}/"

  if [[ $# -ne 2 ]]
  then
    echo -ne "\nUsg: ${FUNCNAME[0]} [-n] <left> <right>\n\n"
    return 1
  fi

  #-@-1 not available in version <=3.1.2

  echo "Left -> Right"
  rsync ${dryrun} --modify-window=-1 --info=NAME -urt ${left} ${right} 

  if [[ ${forward_only} -ne 0 ]]
  then
    echo "Right -> Left"
    rsync ${dryrun} --modify-window=-1 --info=NAME -urt ${right} ${left}
  fi

}

function lsps(){
  lsof -p ^$$ -t "${@}" | xargs ps --forest -o pid,ppid,state,etime,args -p
}


function elipsis(){ 
  wi=$(( $(tput cols ) * 3 / 4 ))
  if [[ ${#1} -gt ${wi} ]]
  then
    echo "${1:1:${wi}}..."
  else
    echo "${1}"
  fi

}


function ziplr(){ 
    q=;
    cmd="${1:-link}";
    filt=;
    [[ -n ${2} ]] && q="-q ${2}";
    case "${cmd}" in 
        link) ip link | grep --color=auto --color=auto '^[0-9]\+' | cut -d' ' -f 2 | tr -d ':' | fzf -0 -1 -e -m +s --cycle --reverse +i --bind alt-space:toggle-all,alt-x:select-all --preview-window='wrap' -0 -1 ${q};;
        *) ip "${cmd}" | fzf -0 -1 -e -m +s --cycle --reverse +i --bind alt-space:toggle-all,alt-x:select-all --preview-window='wrap' -0 -1 ${q};;
    esac
}
