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

function cabal_sandbox_info() {
    # Find cabal file
    local cabal_file=$(_find_cabal_file) cabal_dir
    local cabal_prefix="λ:(" cabal_suffix="%{$fg[blue]%})%{$reset_color%}"
    local cabal_name="" cabal_box

    if [ -n "$cabal_file" ]; then
        # Getting the name of the project
        cabal_name=$(sed -n -e 's/^name:[   ]*\([^  ]*\)[   ]*/\1/p' $cabal_file)

        if [ -z "$cabal_name" ]; then
            cabal_name="ε"
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
