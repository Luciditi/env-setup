#!/usr/bin/env bats

load test_helper

init_setup() {
    export ENVSETUP_INSTALL_DIR="$TEST_TMP/env-setup-target"
    export ENVSETUP_KEY_FILE="$HOME/.ssh/id_rsa"
    export ENVSETUP_INTERACT="0"

    make_stub "git" '
        echo "git $@" >> "$TEST_TMP/git.calls"
        if [[ "$1" == "clone" ]]; then
            mkdir -p "${@: -1}"
            exit 0
        fi
        exit 0
    '

    make_stub "ssh-keygen" '
        mkdir -p "$(dirname "$2")"
        touch "$2"
        echo "ssh-rsa dummy-pub-key" > "$2.pub"
        exit 0
    '

    make_stub "xcode-select" 'exit 0'
}

@test "init: clones specified branch using ENVSETUP_INSTALL_BRANCH" {
    init_setup
    make_stub "ssh" '
        echo "Hi user! You have successfully authenticated"
        exit 1
    '
    export ENVSETUP_INSTALL_BRANCH="v3"
    run "$REPO_ROOT/scripts/init"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/git.calls"
    [[ "$output" =~ "git clone -b v3" ]]
}

@test "init: forces HTTPS clone when ENVSETUP_CLONE_PROTO=https" {
    init_setup
    make_stub "ssh" '
        echo "Hi user! You have successfully authenticated"
        exit 1
    '
    export ENVSETUP_CLONE_PROTO="https"
    run "$REPO_ROOT/scripts/init"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/git.calls"
    [[ "$output" =~ "https://github.com/Luciditi/env-setup.git" ]]
    [[ ! "$output" =~ "git@github.com" ]]
}

@test "init: defaults to SSH when SSH key has GitHub access" {
    init_setup
    make_stub "ssh" '
        echo "Hi user! You have successfully authenticated"
        exit 1
    '
    export ENVSETUP_CLONE_PROTO="ssh"
    run "$REPO_ROOT/scripts/init"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/git.calls"
    [[ "$output" =~ "git@github.com:Luciditi/env-setup.git" ]]
}

@test "init: falls back to HTTPS when SSH key has no GitHub access" {
    init_setup
    make_stub "ssh" '
        echo "git@github.com: Permission denied (publickey)." >&2
        exit 255
    '
    export ENVSETUP_CLONE_PROTO="ssh"
    run "$REPO_ROOT/scripts/init"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/git.calls"
    [[ "$output" =~ "https://github.com/Luciditi/env-setup.git" ]]
    [[ ! "$output" =~ "git@github.com" ]]
}
