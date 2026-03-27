#
# Exports
#
set -gx GPG_TTY (tty)
set -gx LSCOLORS gxfxcxdxbxegedabagacad

set -l go_bin_path
if set -q GOBIN
    set go_bin_path "$GOBIN"
else if command -sq go
    set -l go_path (go env GOPATH 2>/dev/null)
    if test -n "$go_path"
        set go_bin_path "$go_path/bin"
    end
else if test -d "$HOME/go/bin"
    set go_bin_path "$HOME/go/bin"
end

if test -n "$go_bin_path"
    if not contains -- "$go_bin_path" $PATH
        set -gx PATH "$go_bin_path" $PATH
    end
end

#
# pnpm
#
if test (uname -s) = Darwin
    set -gx PNPM_HOME "$HOME/Library/pnpm"
else
    if set -q XDG_DATA_HOME
        set -gx PNPM_HOME "$XDG_DATA_HOME/pnpm"
    else
        set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    end
end

if test -d "$PNPM_HOME"
    fish_add_path --prepend "$PNPM_HOME"
end

#
# Aliases
#
alias pa='php artisan'
alias tf='terraform'
alias tff='terraform fmt -recursive'

#
# AWS auto complete
#
if command -sq aws_completer
    complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed "s/ $//"; end)'
end
