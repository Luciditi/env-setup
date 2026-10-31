#!/usr/bin/env bats

load test_helper

@test "formula-intersection: default runs against repo configs and outputs 15 common packages" {
    run "$REPO_ROOT/scripts/formula-intersection"
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 15 ]
    [ "${lines[0]}" = "ansible" ]
    [ "${lines[14]}" = "zsh" ]
}

@test "formula-intersection: --format=space outputs single space-delimited string" {
    run "$REPO_ROOT/scripts/formula-intersection" --format=space
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ansible antigen composer direnv fzf go node pipx python rg ruby rust tmate vim zsh" ]]
}

@test "formula-intersection: --format=json outputs valid JSON array" {
    run "$REPO_ROOT/scripts/formula-intersection" --format=json
    [ "$status" -eq 0 ]
    [[ "$output" =~ '["ansible", "antigen"' ]]
}

@test "formula-intersection: custom configs compute intersection accurately" {
    cat << 'EOF' > "$TEST_TMP/c1.yml"
envsetup_homebrew_installed_packages:
  - alpha
  - beta
  - gamma
EOF
    cat << 'EOF' > "$TEST_TMP/c2.yml"
envsetup_homebrew_installed_packages:
  - beta
  - gamma
  - delta
EOF
    run "$REPO_ROOT/scripts/formula-intersection" "$TEST_TMP/c1.yml" "$TEST_TMP/c2.yml"
    [ "$status" -eq 0 ]
    [ "${#lines[@]}" -eq 2 ]
    [ "${lines[0]}" = "beta" ]
    [ "${lines[1]}" = "gamma" ]
}

@test "formula-intersection: handles empty packages list gracefully" {
    cat << 'EOF' > "$TEST_TMP/empty.yml"
envsetup_homebrew_installed_packages: []
EOF
    run "$REPO_ROOT/scripts/formula-intersection" "$TEST_TMP/empty.yml"
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}
