#!/usr/bin/env sh

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: path to solution folder
# $3: path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer path/to/solution/folder/ path/to/output/directory/

# Parse the unit test configuration file, and syntax check each function
#  invocation.
#  - Successful check (zero return code) sees not output emitted
#  - Failing check (1 return code) sees metadata of failing function
#     call assembled, and returned to the results file in JSON format
syntax_check_slug() {
    local slug="${1}"
    local results_file="${2}"
    local test_number=0
    # Check for an empty slug (after stripping comments, and blank lines)
    local slug_code_lines=$(sed -r ':a; s%(.*)/\*.*\*/%\1%; ta; /\/\*/ !b; N; ba' ${slug}.rexx | sed -r '/^\s*$/d' | wc -l)
    if [ $slug_code_lines -lt 1 ] ; then
        message='Empty solution file may not be submitted'
        jq -n --arg message "${message}" '{version: 3, status: "error", message: $message}' > ${results_file}
        return 1
    fi
    # Parse, extract, and execute each function call
    sed -n '/\/\* Test Variables \*\//,/\/\* Unit tests \*\//p' ${slug}-check.rexx > ${slug}-vars.rexx
    sed '/check/!d' ${slug}-check.rexx | sed -E "s/.*\s+'(.*)',,/\1/g" \
      | while read func_call ; do
            test_number=$(( test_number += 1 ))
            echo 'result = '"${func_call}"';say result;exit 0' \
               | cat ${slug}-toplevel.rexx ${slug}-vars.rexx - ${slug}.rexx testlib/${slug}-funcs.rexx | regina 2>/dev/null >/dev/null
            # Trap the first failing execution
            if [ $? -ne 0 ] ; then
                # Re-run function call, capture output to file
                echo 'result = '"${func_call}"'; say result; exit 0' \
                   | cat ${slug}-toplevel.rexx ${slug}-vars.rexx - ${slug}.rexx testlib/${slug}-funcs.rexx > bad_file.rexx
                regina bad_file.rexx 2>bad_output >/dev/null
                # Assemble return data
                echo "Test Number: ${test_number}" > output_file
                cat bad_output >> output_file
                echo 'Context:' >> output_file
                cat -n bad_file.rexx >> output_file
                # NOTE: Since using jq to generate JSON from text, no
                #  need to escape double quotes, or replace newlines
                ##  sed -i 's/"/\\"/g' output_file
                ##  message=$(awk '{printf "%s\\n", $0}' output_file)
                message=$(cat output_file)
                jq -n --arg message "${message}" '{version: 3, status: "error", message: $message}' > ${results_file}
                # Cleanup temporary files
                rm -f bad_file.rexx bad_output output_file ${slug}-vars.rexx 2>&1 >/dev/null
                # Ensure failing code returned
                return 1
            fi
        done
        # Cleanup temporary file
        rm -f ${slug}-vars.rexx 2>&1 >/dev/null
}

# Solution directory is copied to a build directory where:
# - Solution is first syntax checked
# - Failing syntax check sees results of first failing check emitted
# - Successful syntax check sees unit tests executed, and test results
#    emitted
test_slug() {
    local slug="${1}"
    local solution_dir="${2}"
    local results_file="${3}"
    # Copy exercise directory contents to temporary build directory
    local build_dir="$(mktemp -d)"
    cp -rp "${solution_dir}"/* "${build_dir}"/
    # Run tests, generate and emit output, collect result code
    cd "${build_dir}"/ 2>&1 >/dev/null
    # Perform check for syntax and runtime errors
    if syntax_check_slug ${slug} ${results_file} ; then
      # Perform the unit tests proper on 'error'-free code
      ./test-${slug} --regina --json > ${results_file}
    fi
    local result=$?
    cd - 2>&1 >/dev/null
    # Cleanup and return result code
    rm -rf "${build_dir}" 2>&1 >/dev/null
    return ${result}
}

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug path/to/solution/folder/ path/to/output/directory/"
    exit 1
fi

slug="$1"
solution_dir=$(realpath "${2%/}")
output_dir=$(realpath "${3%/}")
results_file="${output_dir}/results.json"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

# Run the tests, generating appropriate output
echo "${slug}: testing..."
test_slug ${slug} ${solution_dir} ${results_file}
echo "${slug}: done"

