#!/usr/bin/env bats

load test_helper

@test "env-setup -h prints usage and exits 0" {
    run "$REPO_ROOT/scripts/env-setup" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "env-setup --help prints usage and exits 0" {
    run "$REPO_ROOT/scripts/env-setup" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "env-setup -A generates aliases and exits 0" {
    run "$REPO_ROOT/scripts/env-setup" -A
    [ "$status" -eq 0 ]
    [[ "$output" =~ "alias env-vm-create=" ]]
    [[ "$output" =~ "alias env-vm-ssh=" ]]
    [[ "$output" =~ "scripts/vm/create" ]]
    [[ "$output" =~ "deprecated" ]]
}

@test "env-setup vm prints usage when no subcommand provided" {
    run "$REPO_ROOT/scripts/env-setup" vm
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "vm <subcommand>" ]]
}

@test "env-setup vm dispatches to scripts/vm/<subcommand>" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"es-test","State":"stopped"}]'\''
            exit 0
        fi
        echo "tart $@" >> "$TEST_TMP/tart.calls"
    '
    run "$REPO_ROOT/scripts/env-setup" vm start "es-test"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/tart.calls"
    [[ "$output" =~ "tart run --vnc es-test" ]]
}

@test "env-setup vm fails on unknown subcommand" {
    run "$REPO_ROOT/scripts/env-setup" vm unknown-subcmd
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown vm subcommand" ]]
}

@test "env-setup -e fails with code 1 when EDITOR is unset" {
    unset EDITOR
    run "$REPO_ROOT/scripts/env-setup" -e
    [ "$status" -eq 1 ]
    [[ "$output" =~ "\$EDITOR is not set" ]]
}

@test "env-setup -e opens config.yml with EDITOR when set" {
    touch "$ENVSETUP_INSTALL_DIR/config.yml"
    echo "test content" > "$ENVSETUP_INSTALL_DIR/config.yml"
    export EDITOR="cat"
    run "$REPO_ROOT/scripts/env-setup" -e
    [ "$status" -eq 0 ]
    [[ "$output" =~ "test content" ]]
}

@test "env-setup -c fails with code 1 on unknown config and preserves existing" {
    echo "existing content" > "$ENVSETUP_INSTALL_DIR/config.yml"
    run "$REPO_ROOT/scripts/env-setup" -c "nonexistent_config_12345.yml"
    [ "$status" -eq 1 ]
    [ -f "$ENVSETUP_INSTALL_DIR/config.yml" ]
    [ "$(< "$ENVSETUP_INSTALL_DIR/config.yml")" = "existing content" ]
}

@test "env-setup -c symlinks valid config and exits 0" {
    touch "$ENVSETUP_INSTALL_DIR/.mini.config.yml"
    run "$REPO_ROOT/scripts/env-setup" -c "mini"
    [ "$status" -eq 0 ]
    [ -L "$ENVSETUP_INSTALL_DIR/config.yml" ]
}

@test "env-setup -C passes -C flag to ansible-playbook" {
    mkdir -p "$ENVSETUP_PLAYBOOKS_DIR/test-pb"
    touch "$ENVSETUP_PLAYBOOKS_DIR/test-pb/main.yml"
    run "$REPO_ROOT/scripts/env-setup" -C test-pb
    [ "$status" -eq 0 ]
    [ -f "$TEST_TMP/ansible-playbook.log" ]
    grep -q -- "-C" "$TEST_TMP/ansible-playbook.log"
}

@test "env-setup -i passes --list-tasks to ansible-playbook" {
    mkdir -p "$ENVSETUP_PLAYBOOKS_DIR/test-pb"
    touch "$ENVSETUP_PLAYBOOKS_DIR/test-pb/main.yml"
    run "$REPO_ROOT/scripts/env-setup" -i test-pb
    [ "$status" -eq 0 ]
    [ -f "$TEST_TMP/ansible-playbook.log" ]
    grep -q -- "--list-tasks" "$TEST_TMP/ansible-playbook.log"
}

@test "env-setup -s and -t pass tags to ansible-playbook" {
    mkdir -p "$ENVSETUP_PLAYBOOKS_DIR/test-pb"
    touch "$ENVSETUP_PLAYBOOKS_DIR/test-pb/main.yml"
    run "$REPO_ROOT/scripts/env-setup" -s skip_me -t run_me test-pb
    [ "$status" -eq 0 ]
    [ -f "$TEST_TMP/ansible-playbook.log" ]
    grep -q -- "--skip-tags skip_me" "$TEST_TMP/ansible-playbook.log"
    grep -q -- "--tags run_me" "$TEST_TMP/ansible-playbook.log"
}

@test "env-setup -v passes -vvv to ansible-playbook" {
    mkdir -p "$ENVSETUP_PLAYBOOKS_DIR/test-pb"
    touch "$ENVSETUP_PLAYBOOKS_DIR/test-pb/main.yml"
    run "$REPO_ROOT/scripts/env-setup" -v test-pb
    [ "$status" -eq 0 ]
    [ -f "$TEST_TMP/ansible-playbook.log" ]
    grep -q -- "-vvv" "$TEST_TMP/ansible-playbook.log"
}
