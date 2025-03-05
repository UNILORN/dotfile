#
# Exports
#
export GPG_TTY=(tty)
export LSCOLORS=gxfxcxdxbxegedabagacad
export PATH="$PATH:$(go env GOPATH)/bin"

#
# pnpm
#
set -gx PNPM_HOME "$HOME/Library/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end


#
# Aliases
#
alias pa='php artisan'


alias tf='terraform'
alias tff='terraform fmt -recursive'

alias asl-b='aws sso login --profile bedrock'

#
# AWS auto complete
#
test -x (which aws_completer); and complete --command aws --no-files --arguments '(begin; set --local --export COMP_SHELL fish; set --local --export COMP_LINE (commandline); aws_completer | sed \'s/ $//\'; end)'
