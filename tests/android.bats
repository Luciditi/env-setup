#!/usr/bin/env bats

load test_helper

@test "build-image.sh: --help prints usage and exits 0" {
    run "$REPO_ROOT/infra/android/build-image.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "--config" ]]
    [[ "$output" =~ "--tart-disk" ]]
}

@test "build-image.sh: rejects invalid --config preset" {
    run "$REPO_ROOT/infra/android/build-image.sh" --config invalid --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Unknown config" ]]
}

@test "build-image.sh: --dry-run validates config and prints plan" {
    run "$REPO_ROOT/infra/android/build-image.sh" --config mini --output "$TEST_TMP/out.tar.gz" --tart-disk "$TEST_TMP/disk.img" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Config preset: mini (.mini.config.yml)" ]]
    [[ "$output" =~ "Output archive: $TEST_TMP/out.tar.gz" ]]
    [[ "$output" =~ "Tart disk image: $TEST_TMP/disk.img" ]]
}

@test "push-image.sh: fails when archive file does not exist" {
    run "$REPO_ROOT/infra/android/push-image.sh" "$TEST_TMP/missing.tar.gz"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "not found" ]]
}

@test "push-image.sh: pushes archive to /sdcard/linux/images.tar.gz via adb" {
    touch "$TEST_TMP/images.tar.gz"
    make_stub "adb" '
        echo "adb $*" >> "$TEST_TMP/adb.calls"
        if [[ "$1" == "get-state" ]]; then
            echo "device"
        fi
        exit 0
    '
    run "$REPO_ROOT/infra/android/push-image.sh" "$TEST_TMP/images.tar.gz"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/adb.calls"
    [[ "$output" =~ "adb shell mkdir -p /sdcard/linux" ]]
    [[ "$output" =~ "adb push $TEST_TMP/images.tar.gz /sdcard/linux/images.tar.gz" ]]
}

@test "scripts/vm/android: --help prints subcommands" {
    run "$REPO_ROOT/scripts/vm/android" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "build" ]]
    [[ "$output" =~ "import" ]]
    [[ "$output" =~ "push" ]]
}

@test "scripts/vm/android: import creates Tart VM directory with disk.img and config.json" {
    dd if=/dev/zero of="$TEST_TMP/disk.img" bs=1024 count=16 2>/dev/null
    TART_HOME="$TEST_TMP/tart_home" \
        run "$REPO_ROOT/scripts/vm/android" import "$TEST_TMP/disk.img" "debian-android"
    [ "$status" -eq 0 ]
    [ -f "$TEST_TMP/tart_home/vms/debian-android/disk.img" ]
    [ -f "$TEST_TMP/tart_home/vms/debian-android/config.json" ]
}

@test "scripts/vm/android: build delegates to running Tart Linux VM and pulls images.tar.gz" {
    make_stub "tart" '
        if [[ "$1" == "list" ]]; then
            echo '\''[{"Name":"ubuntu","State":"running"}]'\''
            exit 0
        fi
        if [[ "$1" == "ip" ]]; then
            echo "192.168.64.88"
            exit 0
        fi
        exit 0
    '
    make_stub "sshpass" '
        echo "sshpass $*" >> "$TEST_TMP/remote.calls"
        exit 0
    '
    run "$REPO_ROOT/scripts/vm/android" build --config mini --output "$TEST_TMP/images.tar.gz"
    [ "$status" -eq 0 ]
    run cat "$TEST_TMP/remote.calls"
    [[ "$output" =~ "build-image.sh" ]]
    [[ "$output" =~ "--config mini" ]]
}

