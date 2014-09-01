# Slightly improved support for cabal
# TODO
#   * currently only a combination of cabal package && cabal sandbox is supported
#       - should I support more (this seems suitable for my projects
#       - it is not sure how I could support more
#   * add abbreviation for project names, as some might get quite long
#   * improve handling of multiple status lines in the prompt

# Warning, this might change directory
function _find_cabal_file() {
    local cabal_files
    while [ $PWD != "/" ]; do
        cabal_files=(*.cabal(N))
        if [ $#cabal_files -gt 0 ]; then
            for cabal in $cabal_files; do
                [ -s $cabal ] && echo "$PWD/$cabal" && return true
            done
        fi
        cd ..
    done
    return false
}

# Bear in mind that cabal does not know about a sandbox in the parent directory
function cabal_sandbox_info() {
    # Find cabal file
    local cabal_file=$(_find_cabal_file) cabal_dir
    local cabal_prefix=" λ:(" cabal_suffix="%{$fg[blue]%})%{$reset_color%}"
    local cabal_name="" cabal_box

    if [ -n "$cabal_file" ]; then
        # Getting the name of the project
        cabal_name=$(sed -n -e 's/^name:[   ]*\([^  ]*\)[   ]*/\1/p' $cabal_file)

        if [ -z "$cabal_name" ]; then
            cabal_name="ε"
        elif [ $#cabal_name -gt 5 ]; then
            cabal_name="$cabal_name[1,5]…"
        fi

        cabal_dir=$(dirname $cabal_file)
        if [ -f "$cabal_dir/cabal.sandbox.config" ]; then
            cabal_box="%{$fg[green]%}"
        else
            cabal_box="%{$fg[red]%}"
        fi

        echo "$cabal_prefix$cabal_box$cabal_name$cabal_suffix"
    fi
}

# Sandbox aware ghci
# taken from: http://ro-che.info/articles/2014-03-05-cabal-sandbox-tips.html
function _find_cabal_db() {
    local cabal_file=$(_find_cabal_file) cabal_sandbox_config

    if [ -n "$cabal_file" ]; then
        cabal_sandbox_config="$(dirname $cabal_file)/cabal.sandbox.config"

        if [ -f "$cabal_sandbox_config" ]; then
            echo $(sed -n -e 's/^package-db: \(.*\)/\1/p' "$cabal_sandbox_config")
        fi
    fi
}

# Translate absolute path to relative path
# taken from: http://stackoverflow.com/a/12498485
_absolute_to_real() {
    # both $1 and $2 are absolute paths beginning with /
    # returns relative path to $2/$target from $1/$source
    local source=$1
    local target=$2

    local common_part=$source # for now
    local result="" # for now

    while [[ "${target#$common_part}" == "${target}" ]]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        common_part="$(dirname $common_part)"
        # and record that we went back, with correct / handling
        if [[ -z $result ]]; then
            result=".."
        else
            result="../$result"
        fi
    done

    if [[ $common_part == "/" ]]; then
        # special case for root (no common path)
        result="$result/"
    fi

    # since we now have identified the common part,
    # compute the non-common part
    local forward_part="${target#$common_part}"

    # and now stick all parts together
    if [[ -n $result ]] && [[ -n $forward_part ]]; then
        result="$result$forward_part"
    elif [[ -n $forward_part ]]; then
        # extra slash removal
        result="${forward_part:1}"
    fi

    echo $result
}

# Simple Sandbox aware GHCi wrapper
function ghci() {
    local db=$(_find_cabal_db)
    if [ -n "$db" ]; then
        echo "$fg_bold[blue]Using Cabal Sandbox:$reset_color $(_absolute_to_real $PWD $db)"
        command ghci -no-user-package-db -package-db "$db" $@
    else
        command ghci $@
    fi
}

# Simple Sandbox aware GHC wrapper
function ghc() {
    local db=$(_find_cabal_db)
    if [ -n "$db" ]; then
        echo "$fg_bold[blue]Using Cabal Sandbox:$reset_color $(_absolute_to_real $PWD $db)"
        command ghc -no-user-package-db -package-db "$db" $@
    else
        command ghc $@
    fi
}

function _cabal_commands() {
    local ret=1 state
    _arguments ':subcommand:->subcommand' && ret=0

    case $state in
      subcommand)
        subcommands=(
          "bench:Run the benchmark, if any (configure with UserHooks)."
          "build:Compile all targets or specific targets."
          "check:Check the package for common mistakes."
          "clean:Clean up after a build."
          "configure:Prepare to build the package."
          "copy:Copy the files into the install locations."
          "exec:Run a command with the cabal environment"
          "fetch:Downloads packages for later installation."
          "freeze:Freeze dependencies."
          "get:Gets a package's source code."
          "haddock:Generate Haddock HTML documentation."
          "help:Help about commands."
          "hscolour:Generate HsColour colourised code, in HTML format."
          "info:Display detailed information about a particular package."
          "init:Interactively create a .cabal file."
          "install:Installs a list of packages."
          "list:List packages matching a search string."
          "register:Register this package with the compiler."
          "repl:Open an interpreter session for the given target."
          "report:Upload build reports to a remote server."
          "run:Runs the compiled executable."
          "sandbox:Create/modify/delete a sandbox."
          "sdist:Generate a source distribution file (.tar.gz)."
          "test:Run the test suite, if any (configure with UserHooks)."
          "update:Updates list of known packages."
          "upload:Uploads source packages to Hackage."
        )
        _describe -t subcommands 'cabal subcommands' subcommands && ret=0
    esac

    return ret
}

compdef _cabal_commands cabal
