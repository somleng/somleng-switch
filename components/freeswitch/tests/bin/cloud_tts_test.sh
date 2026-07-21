#!/usr/bin/env bash
set -euo pipefail

# Path to the script being tested
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cloud_tts="${script_dir}/../../bin/cloud_tts"

# Mock functions to intercept calls to subcommands
mock_calls=()
mock_polly() {
  mock_calls+=("$*")
}
mock_azure_speech() {
  mock_calls+=("$*")
}

# Export the mocks so subshells (like cloud_tts) can use them
export -f mock_polly mock_azure_speech

# Tell cloud_tts to use the mocks instead of the real commands
export AWS_POLLY_CMD="mock_polly"
export AZURE_SPEECH_CMD="mock_azure_speech"

# Use a temporary directory for test files
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

assert_last_call() {
  local voice="$1"
  local provider="$2"
  local expected_call="$3"

  local last_call=""
  local call_count="${#mock_calls[@]}"
  if (( call_count > 0 )); then
    local last_index=$((call_count - 1))
    last_call="${mock_calls[$last_index]}"
  fi

  if [[ "$last_call" == "$expected_call" ]]; then
    echo "✅ PASS: $voice → $provider called with: $expected_call"
  else
    echo "❌ FAIL: $voice → expected: '$expected_call' but got '$last_call'"
    echo "mock_calls: ${mock_calls[*]:-empty}"
    exit 1
  fi
}

run_cloud_tts() {
  local voice="$1"

  text="Hello world"
  file="${tmp_dir}/output.mp3"
  cache_file="${tmp_dir}/cache"

  mock_calls=()

  # Source the cloud_tts script in the current shell so it can see the mocks
  source "$cloud_tts" "$text" "$file" "$voice" "$cache_file"
}

run_polly_test() {
  local voice="$1"
  local voice_id="$2"
  local engine="$3"

  run_cloud_tts "$voice"
  assert_last_call "$voice" "aws_polly" "$text $file $voice_id $engine $cache_file"
}

run_azure_test() {
  local voice="$1"
  local voice_id="$2"
  local voice_lang="$3"

  run_cloud_tts "$voice"

  assert_last_call "$voice" "azure_speech" "$text $file $voice_id $voice_lang $cache_file"
}

# Run tests
run_polly_test "Polly.Matthew" "Matthew" "standard"
run_polly_test "Polly.Joanna-Neural" "Joanna" "neural"
run_polly_test "Polly.Joanna-Generative" "Joanna" "generative"

run_azure_test "Azure.en-US-JennyNeural" "en-US-JennyNeural" "en-US"
run_azure_test "Azure.fr-FR-DeniseNeural" "fr-FR-DeniseNeural" "fr-FR"

echo "🎉 All tests passed!"
