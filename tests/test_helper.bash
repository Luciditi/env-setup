# tests/test_helper.bash

setup() {
    export REPO_ROOT
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

    export TEST_TMP="$BATS_TEST_TMPDIR"
    export ENVSETUP_INSTALL_DIR="$TEST_TMP"
    export ENVSETUP_INTERACT="0"
    export ANSIBLE_SUDO=""
    export HOME="$TEST_TMP/home"
    export EDITOR="cat"

    mkdir -p "$HOME" "$TEST_TMP/bin" "$TEST_TMP/playbooks/.00-init"
    touch "$TEST_TMP/playbooks/.00-init/.init"
    export ENVSETUP_PLAYBOOKS_DIR="$TEST_TMP/playbooks"

    # Create dummy Ansible stubs that record arguments to logs
    cat << EOF > "$TEST_TMP/bin/ansible"
#!/usr/bin/env bash
echo "\$@" >> "$TEST_TMP/ansible.log"
EOF
    chmod +x "$TEST_TMP/bin/ansible"

    cat << EOF > "$TEST_TMP/bin/ansible-playbook"
#!/usr/bin/env bash
echo "\$@" >> "$TEST_TMP/ansible-playbook.log"
EOF
    chmod +x "$TEST_TMP/bin/ansible-playbook"

    cat << EOF > "$TEST_TMP/bin/ansible-galaxy"
#!/usr/bin/env bash
echo "\$@" >> "$TEST_TMP/ansible-galaxy.log"
EOF
    chmod +x "$TEST_TMP/bin/ansible-galaxy"

    # Prepend stub bin to PATH
    export PATH="$TEST_TMP/bin:$PATH"
}
