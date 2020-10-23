# Retries a command on failure.
# $1 - the max number of attempts
# $2... - the command to run
retry() {
    local -r -i max_attempts="$1"; shift
    local -r cmd="$@"
    local -i attempt_num=1

    until $cmd
    do
        if (( attempt_num == max_attempts ))
        then
            echo "Failed: No success after $max_attempts attempts"
            return 1
        else
            (( attempt_num++ ))
            sleep 20
        fi
    done

}
