#!/usr/bin/env bats

load test_helper

@test "export: env-setup --help documents export command" {
    run "$REPO_ROOT/scripts/env-setup" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "export" ]]
}

@test "export: .09-export is hidden from interactive playbook listing" {
    local macos_playbooks
    # shellcheck disable=SC2012
    macos_playbooks=$(find "$REPO_ROOT/ansible/macos/"* -maxdepth 0 -type d -print0 2>/dev/null | xargs -0 -n1 basename)
    [[ ! "$macos_playbooks" =~ ".09-export" ]]
    [[ ! "$macos_playbooks" =~ ".00-init" ]]
    [[ "$macos_playbooks" =~ "01-config" ]]
}

@test "export: env-setup export dispatches to .09-export without sudo prompt" {
    mkdir -p "$ENVSETUP_PLAYBOOKS_DIR/.09-export"

    # Default ANSIBLE_SUDO in env-setup would be -K unless overridden
    unset ANSIBLE_SUDO

    run "$REPO_ROOT/scripts/env-setup" export
    [ "$status" -eq 0 ]
    [ -f "$TEST_TMP/ansible-playbook.log" ]
    run cat "$TEST_TMP/ansible-playbook.log"
    [[ "$output" =~ "main.yml" ]]
    [[ ! "$output" =~ "-K" ]]
}

@test "export: env-setup export accepts optional target output file" {
    mkdir -p "$ENVSETUP_PLAYBOOKS_DIR/.09-export"
    unset ANSIBLE_SUDO

    run "$REPO_ROOT/scripts/env-setup" export "/tmp/my-custom-export.yml"
    [ "$status" -eq 0 ]
    [ -f "$TEST_TMP/ansible-playbook.log" ]
    run cat "$TEST_TMP/ansible-playbook.log"
    [[ "$output" =~ "export_file=/tmp/my-custom-export.yml" ]]
}

@test "export: .09-export symlinks and template files exist and resolve" {
    [ -L "$REPO_ROOT/ansible/macos/.09-export/ansible.cfg" ]
    [ -L "$REPO_ROOT/ansible/macos/.09-export/inventory" ]
    [ -L "$REPO_ROOT/ansible/macos/.09-export/requirements.yml" ]
    [ -e "$REPO_ROOT/ansible/macos/.09-export/ansible.cfg" ]
    [ -e "$REPO_ROOT/ansible/macos/.09-export/inventory" ]
    [ -e "$REPO_ROOT/ansible/macos/.09-export/requirements.yml" ]

    [ -L "$REPO_ROOT/ansible/linux/.09-export/ansible.cfg" ]
    [ -L "$REPO_ROOT/ansible/linux/.09-export/inventory" ]
    [ -L "$REPO_ROOT/ansible/linux/.09-export/requirements.yml" ]
    [ -e "$REPO_ROOT/ansible/linux/.09-export/ansible.cfg" ]
    [ -e "$REPO_ROOT/ansible/linux/.09-export/inventory" ]
    [ -e "$REPO_ROOT/ansible/linux/.09-export/requirements.yml" ]

    [ -f "$REPO_ROOT/ansible/macos/.09-export/templates/config.export.yml.j2" ]
    [ -L "$REPO_ROOT/ansible/linux/.09-export/templates/config.export.yml.j2" ]
    [ -e "$REPO_ROOT/ansible/linux/.09-export/templates/config.export.yml.j2" ]
}

@test "export: playbook syntax checks cleanly" {
    local real_ansible
    real_ansible=$(type -a -p ansible-playbook | grep -v "$TEST_TMP" | head -n1 || true)
    if [[ -z "$real_ansible" ]]; then
        skip "ansible-playbook not found on host"
    fi
    run "$real_ansible" --syntax-check "$REPO_ROOT/ansible/macos/.09-export/main.yml"
    [ "$status" -eq 0 ]
    run "$real_ansible" --syntax-check "$REPO_ROOT/ansible/linux/.09-export/main.yml"
    [ "$status" -eq 0 ]
}
