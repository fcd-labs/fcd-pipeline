#!/usr/bin/env bats
# Unit tests of the helper functions in fcd (sourced without running a command).

setup() {
  export FCD_PIPELINE_DIR=/code
  # shellcheck disable=SC1091
  source <(sed '/^case "${1:-}" in/,$d' /code/fcd | sed 's/^set -euo pipefail//')
}

@test "ver_gt compares semantic versions" {
  ver_gt 0.2.0 0.1.9
  ver_gt 1.0.0 0.9.9
  ! ver_gt 0.1.0 0.1.0
  ! ver_gt 0.1.0 0.1.1
}

@test "bump_ver raises major, minor and patch" {
  [ "$(bump_ver 0.1.0 patch)" = 0.1.1 ]
  [ "$(bump_ver 0.1.3 minor)" = 0.2.0 ]
  [ "$(bump_ver 0.4.3 major)" = 1.0.0 ]
}

@test "json_str escapes quotes, backslashes and newlines" {
  [ "$(json_str 'a"b\c')" = '"a\"b\\c"' ]
  [ "$(json_str $'x\ny')" = '"x\ny"' ]
}

@test "container_var maps a container to its version variable" {
  [ "$(container_var bestellen-frontend)" = BESTELLEN_FRONTEND_VERSION ]
}

@test "junit_counts sums all test suites" {
  d=$(mktemp -d)
  printf '<testsuites><testsuite name="a" tests="3" failures="1" errors="0" skipped="1" time="1.5"></testsuite>\n<testsuite name="b" tests="2" failures="0" errors="1" skipped="0" time="0.5"></testsuite></testsuites>\n' >"$d/TEST-x.xml"
  [ "$(junit_counts "$d")" = "5 2 1 2.0" ]
}

@test "an explain covers only reasons that contain its rule, its subject, and only until its end date" {
  CFG=$(mktemp); R_NAME=sk-demo
  cat >"$CFG" <<'PROPS'
Explanation/EXP-001/spec/gate=security
Explanation/EXP-001/spec/rule=versheid frontend
Explanation/EXP-001/spec/subject=sk-demo
Explanation/EXP-001/spec/approver=Johannes
Explanation/EXP-001/spec/until=2999-12-31
Explanation/EXP-OLD/spec/gate=security
Explanation/EXP-OLD/spec/rule=kwetsbaarheid
Explanation/EXP-OLD/spec/approver=Johannes
Explanation/EXP-OLD/spec/until=2000-01-01
Explanation/EXP-OTHER/spec/gate=security
Explanation/EXP-OTHER/spec/rule=licentie
Explanation/EXP-OTHER/spec/subject=fcd-dashboard
Explanation/EXP-OTHER/spec/approver=Johannes
Explanation/EXP-LIST/spec/gate=security
Explanation/EXP-LIST/spec/rule=versheid backend
Explanation/EXP-LIST/spec/subjects/0=sk-demo
Explanation/EXP-LIST/spec/subjects/1=fcd-dashboard
Explanation/EXP-LIST/spec/approver=Johannes
PROPS
  [ "$(explain_for security 'versheid frontend (npm): meer dan 0 major-versie(s) achter')" = EXP-001 ]
  [ -z "$(explain_for security 'image x: kwetsbaarheid (CRITICAL,HIGH)')" ]
  [ -z "$(explain_for security 'image x: licentie niet toegestaan')" ]
  [ -z "$(explain_for code 'versheid frontend: x')" ]
  [ "$(explain_for security 'versheid backend (maven): x')" = EXP-LIST ]
  R_NAME=fcd-pipeline; [ -z "$(explain_for security 'versheid backend (maven): x')" ]
}

@test "a gate keeps every reason, and an explain covers only its own" {
  CFG=$(mktemp); R_DIR=$(mktemp -d); R_NAME=sk-demo
  printf 'Explanation/EXP-001/spec/gate=security\nExplanation/EXP-001/spec/rule=versheid\nExplanation/EXP-001/spec/approver=Johannes\nExplanation/EXP-001/spec/until=2999-12-31\n' >"$CFG"
  emit() { printf '%s\n' "$3" >"$R_DIR/gate.json"; }
  finish_run() { :; }
  GATE_REASONS="image x: kritieke of hoge kwetsbaarheid; versheid: een library loopt achter"
  run gate security 6-7
  [ "$status" -eq 1 ]
  grep -q '"outcome":"closed"' "$R_DIR/gate.json"
  grep -q 'kwetsbaarheid; afwijking EXP-001: versheid' "$R_DIR/gate.json"
}

@test "explain_json gives the details of an explain for the log line" {
  CFG=$(mktemp)
  printf 'Explanation/EXP-001/spec/gate=security\nExplanation/EXP-001/spec/rule=versheid\nExplanation/EXP-001/spec/reason=Angular 21 -> 22\nExplanation/EXP-001/spec/approver=Johannes\nExplanation/EXP-001/spec/until=2026-12-31\n' >"$CFG"
  [ "$(explain_json EXP-001)" = '{"id":"EXP-001","gate":"security","rule":"versheid","reason":"Angular 21 -> 22","approver":"Johannes","until":"2026-12-31"}' ]
}

@test "bump raises the sub-product version once per change, compared with main" {
  d=$(mktemp -d); cd "$d"
  git init -q -b main origin.git --bare 2>/dev/null || git init -q --bare origin.git
  git clone -q origin.git work 2>/dev/null; cd work
  git config user.email t@example.com; git config user.name t
  printf 'SUBPRODUCT=x\nSUBPRODUCT_VERSION=0.3.0\nX_BACKEND_VERSION=0.3.0\n' >versions.env
  git add versions.env; git commit -qm one; git push -q origin HEAD:main
  run cmd_bump . x-backend minor
  [ "$(ver_get . SUBPRODUCT_VERSION)" = 0.4.0 ]
  [ "$(ver_get . X_BACKEND_VERSION)" = 0.4.0 ]
  run cmd_bump . x-backend patch
  [ "$(ver_get . SUBPRODUCT_VERSION)" = 0.4.0 ]
  [ "$(ver_get . X_BACKEND_VERSION)" = 0.4.1 ]
}

@test "the configuration is read as Kind/name/path: values, lists, keys and names" {
  CFG=$(mktemp)
  cat >"$CFG" <<'PROPS'
Pipeline/pipeline/spec/steps/0=static-check
Pipeline/pipeline/spec/steps/1=unit-tests
Pipeline/pipeline/spec/steps/10=release
Pipeline/pipeline/spec/steps/2=contract-test
QualityGate/security/spec/thresholds/freshness/maxMajorBehind=1
Environment/demo/spec/ports/dashboard=8070
Environment/demo/spec/ports/stub-bar=8092
QualityGate/code/spec/afterSteps/0=static-check
PROPS
  [ "$(cfg QualityGate security spec/thresholds/freshness/maxMajorBehind)" = 1 ]
  [ "$(cfg QualityGate security spec/thresholds/missing/max 0)" = 0 ]
  [ "$(cfg_list Pipeline pipeline spec/steps | paste -sd, -)" = static-check,unit-tests,contract-test,release ]
  [ "$(cfg_keys Environment demo spec/ports | paste -sd, -)" = dashboard,stub-bar ]
  [ "$(cfg_names QualityGate | paste -sd, -)" = security,code ]
}

@test "freshness: the threshold of the configuration decides, per part" {
  CFG=$(mktemp); R_DIR=$(mktemp -d)
  printf 'QualityGate/security/spec/thresholds/freshness/maxMajorBehind=1\nQualityGate/security/spec/thresholds/freshness/undetermined=warn\n' >"$CFG"
  ci_freshness() { printf 'freshness|backend (maven)|a:b|1.5.9|3.0.9\nfreshness|frontend (npm)|@angular/core|21.2.0|22.3.0\n'; }
  step_state() { printf '%s=%q\n' "$1" "$2" >>"$R_DIR/.state"; }
  freshness
  . "$R_DIR/.state"
  [[ "$GATE_REASONS" == *"versheid backend (maven): meer dan 1 major"* ]]
  [[ "$GATE_REASONS" != *"versheid frontend"* ]]
}

@test "ver_ge: the new log lines only for a Dashboard of 0.4.0 or higher" {
  ver_ge 0.4.0 0.4.0
  ver_ge 0.10.0 0.4.0
  ! ver_ge 0.3.1 0.4.0
  ! ver_ge "" 0.4.0
}

@test "start of a run: steps of this run in order, also with --until, only for a Dashboard that knows them" {
  R_STEPS=$'static-check\nunit-tests\ncontract-test\nbuild'
  R_LIVE=1
  [ "$(run_steps_json 999)" = ',"steps":["static-check","unit-tests","contract-test","build"]' ]
  [ "$(run_steps_json 2)" = ',"steps":["static-check","unit-tests"]' ]
  R_LIVE=0
  [ -z "$(run_steps_json 999)" ]
}

@test "excerpt: the first line with FAIL or ERROR, without colours, secrets masked" {
  SC_HOME=$(mktemp -d); f=$(mktemp)
  printf '\033[31m[INFO] build\033[0m\n  [ERROR] OrderServiceTest failed password=hunter2\nlast\n' >"$f"
  [ "$(step_excerpt "$f")" = '[ERROR] OrderServiceTest failed password=***' ]
}

@test "excerpt: else the last non-empty line, at most 300 characters" {
  SC_HOME=$(mktemp -d); f=$(mktemp)
  printf 'one\nthe last line\n\n\n' >"$f"
  [ "$(step_excerpt "$f")" = 'the last line' ]
  printf '%0400d\n' 0 >"$f"
  [ "$(step_excerpt "$f" | wc -c | tr -d ' ')" = 300 ]
}

@test "mask_secrets: secrets of the showcase, tokens, credentials in URLs and key=value pairs" {
  SC_HOME=$(mktemp -d); mkdir -p "$SC_HOME/secrets"; printf 'S3cr3tValue123' >"$SC_HOME/secrets/dashboard-db"
  out=$(mask_secrets 'db S3cr3tValue123 url https://app:pw@host/x Token: abc Authorization: Bearer eyJ.x ghp_abcdefghijklmnopqrstuvwxyz0123 ok')
  [ "$out" = 'db *** url https://***@host/x Token: *** Authorization: *** *** *** ok' ]
}

@test "a gate sends its start, only for a Dashboard that knows it" {
  R_DIR=$(mktemp -d)
  emit() { printf '%s %s\n' "$1" "$3" >>"$R_DIR/lines"; }
  R_LIVE=0; gate_started code afterSteps static-check
  [ ! -s "$R_DIR/lines" ]
  R_LIVE=1; gate_started code afterSteps static-check,unit-tests
  grep -qx 'dev.cdeventsx.fcd-qualitygate.started.0.1.0 {"gate":"code","afterSteps":"static-check,unit-tests"}' "$R_DIR/lines"
}

@test "human gate on the werkplek: waits for the approver when a merge would release" {
  CFG=$(mktemp); R_DIR=$(mktemp -d); R_REPO=$(mktemp -d); git -C "$R_REPO" init -q
  printf 'QualityGate/human/spec/beforeSteps/0=release\nQualityGate/human/spec/approval=merge-on-main-with-higher-version\nQualityGate/human/spec/approver=Johannes\n' >"$CFG"
  emit() { printf '%s %s\n' "$1" "$3" >>"$R_DIR/lines"; }
  R_ENV=werkplek R_VERSION=0.2.0 R_LIVE=1
  human_gate human
  grep -qx 'dev.cdeventsx.fcd-qualitygate.started.0.1.0 {"gate":"human","beforeSteps":"release","waitingFor":{"kind":"human","name":"Johannes","action":"merge op main met een hogere versie"}}' "$R_DIR/lines"
  [ "$R_RELEASE" != 1 ]
}

@test "human gate on the werkplek: without an approver in the configuration, the product owner" {
  CFG=$(mktemp); R_DIR=$(mktemp -d); R_REPO=$(mktemp -d); git -C "$R_REPO" init -q
  printf 'QualityGate/human/spec/beforeSteps/0=release\nQualityGate/human/spec/approval=merge-on-main-with-higher-version\n' >"$CFG"
  emit() { printf '%s\n' "$3" >>"$R_DIR/lines"; }
  R_ENV=werkplek R_VERSION=0.2.0 R_LIVE=1
  human_gate human
  grep -q '"name":"product owner"' "$R_DIR/lines"
}

@test "test counts so far from the list reporter of Playwright" {
  f=$(mktemp)
  printf '  ✓  1 [chromium] › a.spec.ts:3:1 › a (1.1s)\n  ✘  2 [chromium] › b\n  -  3 [chromium] › c\n  ✓  4 [chromium] › d\n' >"$f"
  [ "$(playwright_counts "$f")" = "2 1 1" ]
}

@test "cfg_load reads all declarative files of a showcase with yq" {
  command -v docker >/dev/null || skip "no docker in the test container"
}
