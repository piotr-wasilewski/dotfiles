# -------------------------------------------------------------------
# Call from a local repo to open the repository on github/bitbucket in browser
#
# usage:
repo()
{
  local giturl=$(git config --get remote.origin.url \
    | sed 's/git@/\/\//g' \
    | sed 's/.git$//' \
    | sed 's/https://g' \
    | sed 's/:/\//g')

  if [[ $giturl == "" ]]; then
    echo "Not a git repository or no remote.origin.url is set."
  else
    local gitbranch=$(git rev-parse --abbrev-ref HEAD)
    local giturl="https:${giturl}"

    if [[ $gitbranch != "master" ]]; then
      if echo "${giturl}" | grep -i "bitbucket" > /dev/null ; then
        local giturl="${giturl}/branch/${gitbranch}"
      else
        local giturl="${giturl}/tree/${gitbranch}"
      fi
    fi

    echo $giturl
    o $giturl
  fi
}

# -------------------------------------------------------------------
# os-info: show some info about your system
os-info()
{
  lsb_release -a
  uname -a

  if [ -z /etc/lsb-release ]; then
    cat /etc/lsb-release;
  fi;

  if [ -z /etc/issue ]; then
    cat /etc/issue;
  fi;

  if [ -z /proc/version ]; then
    cat /proc/version;
  fi;
}

# -------------------------------------------------------------------
# calc: Simple calculator
# usage: e.g.: 3+3 || 6*6/2
calc()
{
  local result=""
  result="$(printf "scale=10;$*\n" | bc --mathlib | tr -d '\\\n')"
  #                       └─ default (when `--mathlib` is used) is 20
  #
  if [[ "$result" == *.* ]]; then
    # improve the output for decimal numbers
    printf "$result" |
    sed -e 's/^\./0./'        `# add "0" for cases like ".5"` \
        -e 's/^-\./-0./'      `# add "0" for cases like "-.5"`\
        -e 's/0*$//;s/\.$//'   # remove trailing zeros
  else
    printf "$result"
  fi
  printf "\n"
}

# -------------------------------------------------------------------
# mkd: Create a new directory and enter it
mkd()
{
  mkdir -p "$@" && cd "$_"
}

# -------------------------------------------------------------------
# mkf: Create a new directory, enter it and create a file
#
# usage: mkf /tmp/lall/foo.txt
mkf()
{
  mkd $(dirname "$@") && touch $@
}

# -------------------------------------------------------------------
# rand_int: use "urandom" to get random int values
#
# usage: rand_int 8 --> e.g.: 32245321
rand_int()
{
  if [ $1 ]; then
    local length=$1
  else
    local length=16
  fi

  tr -dc 0-9 < /dev/urandom  | head -c${1:-${length}}
}

# -------------------------------------------------------------------
# passwdgen: a password generator
#
# usage: passwdgen 8 --> e.g.: f4lwka_2f
passwdgen()
{
  if [ $1 ]; then
    local length=$1
  else
    local length=16
  fi

  tr -dc A-Za-z0-9_ < /dev/urandom  | head -c${1:-${length}}
}

# -------------------------------------------------------------------
# duh: Sort the "du"-command output and use human-readable units.
duh()
{
  local unit=""
  local size=""

  du -k "$@" | sort -n | while read size fname; do
    for unit in KiB MiB GiB TiB PiB EiB ZiB YiB; do
      if [ "$size" -lt 1024 ]; then
        echo -e "${size} ${unit}\t${fname}"
        break
      fi
      size=$((size/1024))
    done
  done
}

# -------------------------------------------------------------------
# fs: Determine size of a file or total size of a directory
fs()
{
  if du -b /dev/null > /dev/null 2>&1; then
    local arg=-sbh
  else
    local arg=-sh
  fi

  if [[ -n "$@" ]]; then
    du $arg -- "$@"
  else
    du $arg .[^.]* ./*
  fi
}

# -------------------------------------------------------------------
# ff: displays all files in the current directory (recursively)
ff()
{
  find . -type f -iname '*'$*'*' -ls
}

# -------------------------------------------------------------------
# fstr: find text in files
fstr()
{
  OPTIND=1
  local case=""
  local usage="fstr: find string in files.
  Usage: fstr [-i] \"pattern\" [\"filename pattern\"] "

  while getopts :it opt
  do
        case "$opt" in
        i) case="-i " ;;
        *) echo "$usage"; return;;
        esac
  done

  shift $(( $OPTIND - 1 ))
  if [ "$#" -lt 1 ]; then
    echo "$usage"
    return 1
  fi

  find . -type f -name "${2:-*}" -print0 \
    | xargs -0 egrep --color=auto -Hsn ${case} "$1" 2>&- \
    | more
}

# -------------------------------------------------------------------
# file_information: output information to a file
file_information()
{
  if [ $1 ]; then
    if [ -z $1 ]; then
      echo "$1: not found"
      return 1
    fi

    echo $1
    ls -l $1
    file $1
    ldd $1
  else
    echo "Missing argument"
    return 1
  fi
}

# -------------------------------------------------------------------
# psgrep: grep a process
psgrep()
{
  if [ ! -z $1 ] ; then
    echo "Grepping for processes matching $1..."
    ps aux | grep -i $1 | grep -v grep
  else
    echo "!! Need a process-name to grep for"
    return 1
  fi
}

# -------------------------------------------------------------------
# cpuinfo: get info about your cpu
cpuinfo()
{
  if lscpu > /dev/null 2>&1; then
    lscpu
  else
    cat /proc/cpuinfo
  fi
}

# -------------------------------------------------------------------
# json: Syntax-highlight JSON strings or files
#
# usage: json '{"foo":42}'` or `echo '{"foo":42}' | json
json()
{
  if [ -t 0 ]; then # argument
    python -mjson.tool <<< "$*" | pygmentize -l javascript
  else # pipe
    python -mjson.tool | pygmentize -l javascript
  fi
}

# -------------------------------------------------------------------
# tail with search highlight
#
# usage: t /var/log/Xorg.0.log [kHz]
t()
{
  if [ $# -eq 0 ]; then
    echo "Usage: t /var/log/Xorg.0.log [kHz]"
    return 1
  else
    if [ $2 ]; then
      tail -n 50 -f $1 | perl -pe "s/$2/${COLOR_LIGHT_RED}$&${COLOR_NO_COLOUR}/g"
    else
      tail -n 50 -f $1
    fi
  fi
}

# -------------------------------------------------------------------
# `o`: with no arguments opens current directory, otherwise opens the given
# location
o()
{
  local open_command=""

  if gnome-open --version /dev/null > /dev/null 2>&1; then
    # GNOME
    open_command='gnome-open'
  elif exo-open --version /dev/null > /dev/null 2>&1; then
    # Xfce
    open_command='exo-open'
  elif kde-open --version /dev/null > /dev/null 2>&1; then
    # KDE
    open_command='kde-open'
  elif xdg-open --version /dev/null > /dev/null 2>&1; then
    # Linux
    open_command='xdg-open'
  elif open --version /dev/null > /dev/null 2>&1; then
    # Mac OS
    open_command='open'
  elif cygstart --version /dev/null > /dev/null 2>&1; then
    # Cygwin
    open_command='cygstart'
  elif [[ $SYSTEM_TYPE == "MINGW" ]]; then
    # MinGW
    open_command='start ""'
  fi

  if [ $# -eq 0 ]; then
    open_command_path="."
  else
    open_command_path="$@"
  fi

  # don't use nohup on OSX
  if [[ "$SYSTEM_TYPE" == "OSX" ]]; then
    $open_command $open_command_path &>/dev/null
  else
    nohup $open_command $open_command_path &>/dev/null
  fi
}

# -------------------------------------------------------------------
# `tre`: is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
tre()
{
  tree -aC -I '.git|node_modules|bower_components|.Spotlight-V100|.TemporaryItems|.DocumentRevisions-V100|.fseventsd' --dirsfirst "$@" | less -FRNX;
}