#!/bin/sh

set -e

assert_in_file () {
  filename="$1"
  test_string="$2"

  file=$(find . -type f -iname $(basename "$filename"))

  if ! grep -q "$test_string" $file; then
    cat <<-EOT
		Error:
		Expected $test_string to be found in $file but was not:
		`cat $file`
		EOT

    return 1
  fi
}

assert_not_in_file () {
  filename="$1"
  test_string="$2"

  file=$(find . -type f -iname $(basename "$filename"))

  if grep -q "$test_string" $file; then
    cat <<-EOT
		Error:
		Expected $test_string not to be found in $file but was found:
		`cat $file`
		EOT

    return 1
  fi
}
