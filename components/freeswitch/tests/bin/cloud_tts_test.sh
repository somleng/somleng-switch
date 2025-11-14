#!/usr/bin/env bash
set -euo pipefail

# Path to the script being tested
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cloud_tts="${script_dir}/../../bin/cloud_tts"

# Mock function to intercept calls to aws_polly
mock_calls=()
mock_polly() {
  mock_calls+=("$*")
}

# Export the mock so subshells (like cloud_tts) can use it
export -f mock_polly

# Tell cloud_tts to use the mock instead of aws_polly
export AWS_POLLY_CMD="mock_polly"

# Use a temporary directory for test files
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

run_test() {
  local voice="$1"
  local expected_voice_id="$2"
  local expected_engine="$3"
  local text="Hello world"
  local file="${tmp_dir}/output.mp3"
  local cache_file="${tmp_dir}/cache"

  mock_calls=()

  # Source the cloud_tts script in the current shell so it can see mock_polly
  source "$cloud_tts" "$text" "$file" "$voice" "$cache_file"

  local last_call=""
  local call_count="${#mock_calls[@]}"
  if (( call_count > 0 )); then
    local last_index=$((call_count - 1))
    last_call="${mock_calls[$last_index]}"
  fi

  local expected_call="$text $file $expected_voice_id $expected_engine $cache_file"

  if [[ "$last_call" == "$expected_call" ]]; then
    echo "✅ PASS: $voice → aws_polly called with: $expected_call"
  else
    echo "❌ FAIL: $voice → expected: '$expected_call' but got '$last_call'"
    echo "mock_calls: ${mock_calls[*]:-empty}"
    exit 1
  fi
}

# Run tests
run_test "Polly.Matthew" "Matthew" "standard"
run_test "Polly.Joanna-Neural" "Joanna" "neural"
run_test "Polly.Joanna-Generative" "Joanna" "generative"

echo "🎉 All tests passed!"
