#!/usr/bin/env bats

load test_helper

@test "_vm: vm_require_tart fails when tart is missing" {
    make_stub "tart" 'exit 127'
    rm -f "$TEST_TMP/bin/tart"
    source "$REPO_ROOT/scripts/_vm"
    # Run in subshell since failure calls fatal or exit
    run bash -c "source '$REPO_ROOT/scripts/_vm' && PATH='$TEST_TMP/bin' vm_require_tart"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "tart is required" ]]
}

@test "_vm: vm_running detects exact running VM and ignores stopped" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"es-macos","State":"running"},{"Name":"es-linux","State":"stopped"},{"Name":"vpn","State":"running"}]'\''
            exit 0
        fi
        exit 1
    '
    source "$REPO_ROOT/scripts/_vm"
    run vm_running "es-macos"
    [ "$status" -eq 0 ]

    run vm_running "es-linux"
    [ "$status" -ne 0 ]

    run vm_running "nonexistent"
    [ "$status" -ne 0 ]
}

@test "_vm: vm_find_running never selects vpn VM" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"vpn","State":"running"},{"Name":"es-target","State":"running"}]'\''
            exit 0
        fi
        exit 1
    '
    source "$REPO_ROOT/scripts/_vm"
    run vm_find_running
    [ "$status" -eq 0 ]
    [ "$output" = "es-target" ]
}

@test "_vm: vm_find_running returns empty when only vpn is running" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"vpn","State":"running"}]'\''
            exit 0
        fi
        exit 1
    '
    source "$REPO_ROOT/scripts/_vm"
    run vm_find_running
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "_vm: vm_ip returns IP for running VM" {
    make_stub "tart" '
        if [[ "$1" == "ip" && "$2" == "es-macos" ]]; then
            echo "192.168.64.42"
            exit 0
        fi
        exit 1
    '
    source "$REPO_ROOT/scripts/_vm"
    run vm_ip "es-macos"
    [ "$status" -eq 0 ]
    [ "$output" = "192.168.64.42" ]
}

@test "_vm: vm_start runs tart run with --vnc" {
    make_stub "tart" '
        echo "tart $@" >> "$TEST_TMP/tart.calls"
    '
    source "$REPO_ROOT/scripts/_vm"
    run vm_start "es-test"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/tart.calls"
    [[ "$output" =~ "tart run --vnc es-test" ]]
}

@test "_vm: vm_stop runs tart stop" {
    make_stub "tart" '
        echo "tart $@" >> "$TEST_TMP/tart.calls"
    '
    source "$REPO_ROOT/scripts/_vm"
    run vm_stop "es-test"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/tart.calls"
    [[ "$output" =~ "tart stop es-test" ]]
}

@test "_vm: vm_create clones image and sets disk size" {
    make_stub "tart" '
        echo "tart $@" >> "$TEST_TMP/tart.calls"
    '
    source "$REPO_ROOT/scripts/_vm"
    run vm_create "es-test" "my-image:latest" 60
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/tart.calls"
    [[ "$output" =~ "tart clone my-image:latest es-test" ]]
    [[ "$output" =~ "tart set es-test --disk-size 60" ]]
}

@test "_remote: remote_require_sshpass fails when sshpass is missing" {
    make_stub "sshpass" 'exit 127'
    rm -f "$TEST_TMP/bin/sshpass"
    run bash -c "source '$REPO_ROOT/scripts/_remote' && PATH='$TEST_TMP/bin' remote_require_sshpass"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "sshpass is required" ]]
}

@test "_remote: remote_exec invokes sshpass and ssh with credentials and host" {
    make_stub "sshpass" '
        echo "sshpass $@" >> "$TEST_TMP/remote.calls"
    '
    source "$REPO_ROOT/scripts/_remote"
    run remote_exec "192.168.64.42"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/remote.calls"
    [[ "$output" =~ "-p admin ssh" ]]
    [[ "$output" =~ "admin@192.168.64.42" ]]
}

@test "_remote: remote_exec runs command when arguments provided" {
    make_stub "sshpass" '
        echo "sshpass $@" >> "$TEST_TMP/remote.calls"
    '
    source "$REPO_ROOT/scripts/_remote"
    run remote_exec "192.168.64.42" "uname -a"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/remote.calls"
    [[ "$output" =~ "admin@192.168.64.42 uname -a" ]]
}

@test "_remote: remote_copy invokes sshpass and scp" {
    make_stub "sshpass" '
        echo "sshpass $@" >> "$TEST_TMP/remote.calls"
    '
    source "$REPO_ROOT/scripts/_remote"
    run remote_copy "local_file" "192.168.64.42" "/tmp/dest"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/remote.calls"
    [[ "$output" =~ "-p admin scp -r" ]]
    [[ "$output" =~ "local_file admin@192.168.64.42:/tmp/dest" ]]
}

@test "scripts/vm/start starts VM" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"es-test","State":"stopped"}]'\''
            exit 0
        fi
        echo "tart $@" >> "$TEST_TMP/tart.calls"
    '
    run "$REPO_ROOT/scripts/vm/start" "es-test"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/tart.calls"
    [[ "$output" =~ "tart run --vnc es-test" ]]
}

@test "scripts/vm/stop stops running VM" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"es-test","State":"running"}]'\''
            exit 0
        fi
        echo "tart $@" >> "$TEST_TMP/tart.calls"
    '
    run "$REPO_ROOT/scripts/vm/stop" "es-test"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/tart.calls"
    [[ "$output" =~ "tart stop es-test" ]]
}

@test "scripts/vm/ssh connects to target VM" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"es-test","State":"running"}]'\''
            exit 0
        fi
        if [[ "$1" == "ip" && "$2" == "es-test" ]]; then
            echo "192.168.64.50"
            exit 0
        fi
        exit 1
    '
    make_stub "sshpass" '
        echo "sshpass $@" >> "$TEST_TMP/remote.calls"
    '
    run "$REPO_ROOT/scripts/vm/ssh" "es-test" "echo hello"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/remote.calls"
    [[ "$output" =~ "admin@192.168.64.50 echo hello" ]]
}

@test "scripts/vm/ssh auto-discovers non-vpn VM when VM name omitted" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"vpn","State":"running"},{"Name":"es-auto","State":"running"}]'\''
            exit 0
        fi
        if [[ "$1" == "ip" && "$2" == "es-auto" ]]; then
            echo "192.168.64.60"
            exit 0
        fi
        exit 1
    '
    make_stub "sshpass" '
        echo "sshpass $@" >> "$TEST_TMP/remote.calls"
    '
    run "$REPO_ROOT/scripts/vm/ssh" "hostname"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/remote.calls"
    [[ "$output" =~ "admin@192.168.64.60 hostname" ]]
}

@test "scripts/vm/warm fails when no VM is running" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo "[]"
            exit 0
        fi
        exit 1
    '
    run "$REPO_ROOT/scripts/vm/warm"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "No running test VM found!" ]]
}

@test "scripts/vm/warm fails when specified VM is not running" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"es-stopped","State":"stopped"}]'\''
            exit 0
        fi
        exit 1
    '
    run "$REPO_ROOT/scripts/vm/warm" "es-stopped"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "VM es-stopped is not running!" ]]
}

@test "scripts/vm/warm connects to target VM and executes warmup" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"es-test","State":"running"}]'\''
            exit 0
        fi
        if [[ "$1" == "ip" && "$2" == "es-test" ]]; then
            echo "192.168.64.50"
            exit 0
        fi
        exit 1
    '
    make_stub "sshpass" '
        echo "sshpass $@" >> "$TEST_TMP/remote.calls"
    '
    run "$REPO_ROOT/scripts/vm/warm" "es-test"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/remote.calls"
    [[ "$output" =~ "admin@192.168.64.50" ]]
    [[ "$output" =~ "ansible-galaxy role install" ]]
    [[ "$output" =~ "brew install" ]]
}
