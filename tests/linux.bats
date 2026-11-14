#!/usr/bin/env bats

load test_helper

@test "install-ansible: Debian uses apt-get directly without Ubuntu PPA" {
    cat > "$TEST_TMP/os-release" << 'EOF'
ID=debian
VERSION_CODENAME=trixie
EOF
    make_stub "sudo" 'echo "sudo $*" >> "$TEST_TMP/sudo.calls"'
    make_stub "apt-get" 'exit 0'
    rm -f "$TEST_TMP/bin/apk" "$TEST_TMP/bin/dnf" "$TEST_TMP/bin/zypper"

    run env PATH="$TEST_TMP/bin:/usr/bin:/bin" OS_RELEASE_FILE="$TEST_TMP/os-release" \
        "$REPO_ROOT/scripts/linux/install-ansible"
    [ "$status" -eq 0 ]

    run cat "$TEST_TMP/sudo.calls"
    [[ "$output" =~ "apt-get update --yes" ]]
    [[ "$output" =~ "apt-get install --yes ansible python3-apt" ]]
    [[ ! "$output" =~ "add-apt-repository" ]]
}

@test "install-ansible: Ubuntu uses ppa:ansible/ansible" {
    cat > "$TEST_TMP/os-release" << 'EOF'
ID=ubuntu
VERSION_CODENAME=noble
EOF
    make_stub "sudo" 'echo "sudo $*" >> "$TEST_TMP/sudo.calls"'
    make_stub "apt-get" 'exit 0'
    rm -f "$TEST_TMP/bin/apk" "$TEST_TMP/bin/dnf" "$TEST_TMP/bin/zypper"

    run env PATH="$TEST_TMP/bin:/usr/bin:/bin" OS_RELEASE_FILE="$TEST_TMP/os-release" \
        "$REPO_ROOT/scripts/linux/install-ansible"
    [ "$status" -eq 0 ]

    run cat "$TEST_TMP/sudo.calls"
    [[ "$output" =~ "add-apt-repository --yes --update ppa:ansible/ansible" ]]
}
