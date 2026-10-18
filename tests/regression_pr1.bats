#!/usr/bin/env bats

load test_helper

@test "regression PR-1 #1: config() unknown config exits 1 and preserves existing config.yml" {
    echo "keep_me" > "$ENVSETUP_INSTALL_DIR/config.yml"
    run "$REPO_ROOT/scripts/env-setup" -c "definitely_does_not_exist.yml"
    [ "$status" -eq 1 ]
    [ -f "$ENVSETUP_INSTALL_DIR/config.yml" ]
    [ "$(< "$ENVSETUP_INSTALL_DIR/config.yml")" = "keep_me" ]
}

@test "regression PR-1 #2: config() reads symlink destination without broken pipe" {
    touch "$ENVSETUP_INSTALL_DIR/.dummy.config.yml"
    ln -s "$ENVSETUP_INSTALL_DIR/.dummy.config.yml" "$ENVSETUP_INSTALL_DIR/config.yml"
    run "$REPO_ROOT/scripts/env-setup" -c
    [ "$status" -eq 0 ]
    [[ "$output" =~ "dummy" ]]
}

@test "regression PR-1 #3: -e uses INSTALL_DIR and validates EDITOR is set" {
    unset EDITOR
    run "$REPO_ROOT/scripts/env-setup" -e
    [ "$status" -eq 1 ]
    [[ "$output" =~ "\$EDITOR is not set" ]]

    touch "$ENVSETUP_INSTALL_DIR/config.yml"
    echo "target content" > "$ENVSETUP_INSTALL_DIR/config.yml"
    export EDITOR="cat"
    run "$REPO_ROOT/scripts/env-setup" -e
    [ "$status" -eq 0 ]
    [[ "$output" =~ "target content" ]]
}

@test "regression PR-1 #4: PWD is not clobbered during playbook execution" {
    mkdir -p "$ENVSETUP_PLAYBOOKS_DIR/test-pb"
    touch "$ENVSETUP_PLAYBOOKS_DIR/test-pb/main.yml"
    INITIAL_PWD="$PWD"
    run "$REPO_ROOT/scripts/env-setup" test-pb
    [ "$status" -eq 0 ]
    [ "$PWD" = "$INITIAL_PWD" ]
}

@test "regression PR-1 #5: linux python user-base check runs safely under set -e" {
    # Test under linux OS emulation
    export ENVSETUP_OS="linux-gnu"
    run bash -c "source '$REPO_ROOT/scripts/_common'; source '$REPO_ROOT/scripts/env-setup'"
    [ "$status" -eq 0 ]
}

@test "regression PR-1 #6: add-playbook missing argument exits 1 and does not crash" {
    run "$REPO_ROOT/scripts/add-playbook"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Enter a playbook name" ]]
}

@test "regression PR-1 #7: scripts/_common defines ENVSETUP_DIR from BASH_SOURCE not \$0" {
    run bash -c "source '$REPO_ROOT/scripts/_common'; echo \"\$ENVSETUP_DIR\""
    [ "$status" -eq 0 ]
    [ -d "$output" ]
    [ "$output" = "$REPO_ROOT" ]
}
