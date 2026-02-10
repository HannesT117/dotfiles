# find shorthand
function f() {
  find . -name "$1"
}

function find-port() {
    if ! [ $# -eq 1 ]; then
        echo "Please define the port you want to check \n $ find_port_blocker 8000"
        return 1
    fi

    lsof -i tcp:$1
}

function kill-port() {
    if ! [ $# -eq 1 ]; then
        echo "Please define the port you want to check \n $ find_port_blocker 8000"
        return 1
    fi

    lsof -t -i tcp:$1 | xargs kill -9
}
