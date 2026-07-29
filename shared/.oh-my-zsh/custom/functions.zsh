# neomutt + bitwarden
function mutt() {
  my_pass=$(bws secret get 5c662b9f-2192-49f8-ade7-b3f900fd3051 | jq ".value") neomutt
}

# find shorthand
function f() {
  find . -name "$1"
}

# copy to homeserver
function scphs() {
  scp $1 nonroot@gmktec.local:$2
}

# get new emails
function whatsnew() {
 find ~/.Maildir/*/{INBOX,Spam}/new -type f -exec sh -c 'grep -h -E "^From|Subject" "$1" | paste -sd " " -' _ {} \; || echo "Nothing"
}

function _find_port_expand() {
    reply=()
    local -aU ports
    local arg start end port

    if (( $# == 0 )); then
        echo "Usage: $funcstack[2] <port> [port...]  (ranges: 8081-8090)" >&2
        return 1
    fi

    for arg in "$@"; do
        if [[ $arg == *-* ]]; then
            start=${arg%%-*}
            end=${arg#*-}
            if [[ ! $start =~ ^[0-9]+$ || ! $end =~ ^[0-9]+$ ]]; then
                echo "Invalid range: $arg" >&2
                return 1
            fi
            if (( 10#$start < 1 || 10#$end > 65535 || 10#$start > 10#$end )); then
                echo "Invalid range: $arg" >&2
                return 1
            fi
            for (( port = 10#$start; port <= 10#$end; port++ )); do
                ports+=($port)
            done
        else
            if [[ ! $arg =~ ^[0-9]+$ ]]; then
                echo "Invalid port: $arg" >&2
                return 1
            fi
            if (( 10#$arg < 1 || 10#$arg > 65535 )); then
                echo "Port out of range: $arg" >&2
                return 1
            fi
            ports+=($arg)
        fi
    done

    reply=($ports)
}

function _find_port_pids() {
    lsof -nP -iTCP:"$1" -sTCP:LISTEN -t 2>/dev/null | sort -u
}

function _find_port_short_cmd() {
    local -a words
    local i out
    words=(${(z)1})
    (( $#words )) || return
    words[1]=${words[1]:t}
    i=1
    while (( i <= $#words )); do
        case $words[i] in
            -cp|-classpath|--class-path)
                words[i,i+1]=()
                continue
                ;;
        esac
        (( i++ ))
    done
    out=${(j: :)words}
    if (( ${#out} > 140 && $#words > 2 )); then
        local -a kept
        local w acc
        for w in $words[1,-2]; do
            if (( ${#acc} + ${#w} + 1 > 90 )); then
                break
            fi
            kept+=($w)
            acc="${(j: :)kept}"
        done
        print -r -- "${acc} … ${words[-1]}"
    else
        print -r -- "$out"
    fi
}

function find-port() {
    _find_port_expand "$@" || return
    local -a ports
    local port pids pid cwd cmd
    ports=($reply)

    for port in $ports; do
        pids=$(_find_port_pids "$port")
        if [[ -z $pids ]]; then
            printf '%-6s frei\n' "$port"
            continue
        fi
        for pid in ${(f)pids}; do
            cwd=$(lsof -a -p "$pid" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
            cmd=$(_find_port_short_cmd "$(ps -ww -p "$pid" -o command=)")
            printf '%-6s pid=%s\ncwd  %s\ncmd  %s\n\n' "$port" "$pid" "$cwd" "$cmd"
        done
    done
}

function kill-port() {
    _find_port_expand "$@" || return
    local -a ports
    local port pids pid
    ports=($reply)

    for port in $ports; do
        pids=$(_find_port_pids "$port")
        if [[ -z $pids ]]; then
            printf '%-6s frei\n' "$port"
            continue
        fi
        for pid in ${(f)pids}; do
            if kill -9 "$pid" 2>/dev/null; then
                printf '%-6s killed pid=%s\n' "$port" "$pid"
            else
                printf '%-6s could not kill pid=%s\n' "$port" "$pid" >&2
            fi
        done
    done
}

export BW_USER='web+bitwarden@jrdn.cx'

bw() {
  bw_exec=$(sh -c "which bw")
  local -r bw_session_file='/var/root/.bitwarden.session' # Only accessible as root

  _read_token_from_file() {

    local -r err_token_not_found="Token not found, please run bw --regenerate-session-key"
    case $1 in
    '--force')
      unset bw_session
      ;;
    esac

    if [ "$bw_session" = "$err_token_not_found" ]; then
      unset bw_session
    fi

    # If the session key env variable is not set, read it from the file
    # if file it not there, ask user to regenerate it

    if [ -z "$bw_session" ]; then
      bw_session="$(
        sh -c "sudo cat $bw_session_file 2> /dev/null"
        # shellcheck disable=SC2181
        if [ "$?" -ne "0" ]; then
          echo "$err_token_not_found"
          sudo -k # De-elevate privileges
          exit 1
        fi
        sudo -k # De-elevate privileges
      )"

      # shellcheck disable=SC2181
      if [ "$bw_session" = "$err_token_not_found" ]; then
        echo "$err_token_not_found"
        return 1
      fi
    fi
  }

  case $1 in
  '--regenerate-session-key')
    echo "Regenerating session key, this has invalidated all existing sessions..."
    sudo rm -f /var/root/.bitwarden.session && ${bw_exec} logout 2>/dev/null # Invalidate all existing sessions

    ${bw_exec} login "${BW_USER}" --raw | sudo tee /var/root/.bitwarden.session &>/dev/null # Generate new session key

    _read_token_from_file --force # Read the new session key for immediate use
    sudo -k                       # De-elevate privileges, only doing this now so _read_token_from_file can resuse the same sudo session
    ;;

  'login' | 'logout' | 'config')
    ${bw_exec} "$@"
    ;;


  '--help' | '-h' | '')
    ${bw_exec} "$@"
    echo "To regenerate your session key type:"
    echo "  bw --regenerate-session-key"
    ;;

  *)
    _read_token_from_file

    ${bw_exec} "$@" --session "$bw_session"
    ;;
  esac
}
