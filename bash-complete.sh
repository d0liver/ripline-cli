# vim: set ft=sh

_rl() 
{
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

	case "$COMP_CWORD" in
		1)
			COMPREPLY=($(compgen -W "fetch edit" -- ${cur}))  
			;;
		*)
			if [ -r "$HOME/.cache/ripline/tags" ]; then
				COMPREPLY=( $(compgen -W "--dev $(cat "$HOME/.cache/ripline/tags")" -- ${cur}) )
			fi
			;;
	esac

   return 0
}
complete -F _rl rl
