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

# PHP
alias pa='php artisan'

# Terraform
alias tf='terraform'
alias tff='terraform fmt -recursive'

# AWS
alias asl='aws sso login'
alias assume-unilorn='aws sso login --profile=unilorn && set -gx AWS_PROFILE unilorn'

# GitHub CLI
alias ghb='gh browse'

# Git
alias gpush='git push origin HEAD'
alias gpushf='git push --force-with-lease origin HEAD'
alias gpull='git pull origin'
alias gitb-del='git branch | xargs git branch -d'
alias gs='git switch'

# Git Worktree
alias gw='git worktree'
alias gwa='git worktree add'
alias gwb='git worktree add ../work/(basename $PWD)/'

# AI Commit (gcm)
if command -sq gcm
    alias gc-claude='gcm --provider=claudecode --model="haiku-4.5"'
    alias gc-copilot='gcm --provider=copilotcli --model="gpt-5.3-codex"'
    alias gc-gemini='gcm --provider=geminicli'
    alias gc-codex='gcm --provider=codexcli --model="gpt-5.4-mini"'

    alias gca='git commit -m "$(gc-claude | gsed -z "s/---.*//g")"; git log -n 1; git log --oneline -n 1'
    alias gca-copilot='git commit -m "$(gc-copilot | gsed -z "s/---.*//g")"; git log -n 1; git log --oneline -n 1'
    alias gca-gemini='git commit -m "$(gc-gemini | gsed -z "s/---.*//g")"; git log -n 1; git log --oneline -n 1'
    alias gca-codex='git commit -m "$(gc-codex | gsed -z "s/---.*//g")"; git log -n 1; git log --oneline -n 1'
end

#
# AWS auto complete
#
if command -sq aws_completer
    complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed "s/ $//"; end)'
end

#
# mise
#
if command -sq mise
    mise activate fish | source
end

#
# Local bin
#
fish_add_path $HOME/.local/bin

if test -f "$HOME/.local/bin/env.fish"
    source "$HOME/.local/bin/env.fish"
end
