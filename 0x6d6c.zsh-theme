# vim:ft=zsh ts=2 sw=2 sts=2

setopt prompt_subst
autoload -U add-zsh-hook

# Variables
cwd='${PWD/#$HOME/~}'
background_jobs='%(1j.%{$fg_bold[green]%}%j%{$reset_color%}.%j)'
host_full='$(hostname --long)'

# Symbols
# Stored as literal single-column glyphs (not \u escapes) so they render
# correctly *and* count as one column when the visible prompt width is measured
# for right-alignment below — the (%%) width flag used there does not interpret
# \u escapes. (echo is kept for parity with the original radius definitions.)
S_ADDED=$(echo "●")
S_BRANCH=$(echo "")
S_CLEAN=$(echo "✓")
S_DELETED=$(echo "➖")
S_DIRTY=$(echo "✘")
S_MODIFIED=$(echo "➕")
S_PULL=$(echo "⮟")
S_PUSH=$(echo "⮝")
S_RADIUS_B=$(echo "└")
S_RADIUS_T=$(echo "┌")
S_TAG=$(echo "↹")
S_UNTRACKED=$(echo "❓")

# Colors and command prompts for root and regular user
if [[ $UID = 0 ]]; then
  _USER="%{$fg_bold[red]%}%n%{$reset_color%}"
  _SIGN="%{$fg_bold[red]%}#%{$reset_color%}"
else
  _USER="%{$fg_bold[green]%}%n%{$reset_color%}"
  _SIGN="%{$fg_bold[green]%}$%{$reset_color%}"
fi

# Partial prompts
PROMPT_PREFIX1="${S_BRANCH} "
PROMPT_PREFIX2="%{$fg_bold[yellow]%}"
PROMPT_SUFFIX="%{$reset_color%}"
PROMPT_CLEAN=" %{$fg[green]%}${S_CLEAN}"
PROMPT_DIRTY=" %{$fg[red]%}${S_DIRTY}"


# Git info
git_info='$(git_prompt_info)'
git_status='$(git_prompt_status)'
git_behind='$(git_commits_behind)'
git_ahead='$(git_commits_ahead)'
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}${S_PUSH}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}${S_ADDED}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}${S_PULL}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN="${PROMPT_CLEAN}"
ZSH_THEME_GIT_PROMPT_DIRTY="${PROMPT_DIRTY}"
ZSH_THEME_GIT_PROMPT_DELETED="${S_DELETED}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[blue]%}${S_MODIFIED}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_PREFIX=" ${PROMPT_PREFIX1}${PROMPT_PREFIX2}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${PROMPT_SUFFIX}"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[red]%}${S_UNTRACKED}%{$reset_color%}"

# Zero-width prompt escapes, stripped when measuring the visible prompt width.
_ZERO='%([BSUbfksu]|([FK]|){*})'

# The status info (exit code, background-job count, history event number, time)
# is right-aligned on the FIRST prompt line instead of in RPROMPT. RPROMPT
# always renders on the cursor's line, so selecting the command line would copy
# it too; keeping it on the first line leaves the command line clean to copy.
_0x6d6c_set_prompt() {
  # Capture the real exit status before the commands below clobber $?.
  local exit_status=$?

  # Render git info synchronously. Oh My Zsh's async git prompt (default on zsh
  # >= 5.0.6) makes git_prompt_info merely echo a cache that is only filled when
  # the literal string "$(git_prompt_info)" is found in $PS1. We build $PS1 here
  # with the value already expanded, so that detection never fires and the cache
  # stays empty. Call the synchronous worker functions directly instead; fall
  # back to the public functions on setups that predate the async refactor.
  local gitinfo gitstatus
  if (( $+functions[_omz_git_prompt_info] )); then
    gitinfo="$(_omz_git_prompt_info)"
    gitstatus="$(_omz_git_prompt_status)"
  else
    gitinfo="$(git_prompt_info)"
    gitstatus="$(git_prompt_status)"
  fi

  # Left side of the first line: ┌user@host: cwd <git_info> <git_status>
  local left="${S_RADIUS_T}${_USER}@${(e)host_full}: %B${(e)cwd}%b${gitinfo} ${gitstatus}"

  # Right side of the first line. Non-zero exit codes show on a red background.
  local exit_code="$exit_status"
  (( exit_status != 0 )) && exit_code="%{$bg_bold[red]%}${exit_status}%{$reset_color%}"
  # Pre-expand the clock to a literal "HH:MM:SS" string. %D{%H:%M:%S} keeps the
  # hour zero-padded (01..23) for constant width, but it must NOT survive into
  # the width measurement below: the strftime "%S" (seconds) collides with the
  # zero-width strip pattern (S is one of [BSUbfksu]), which would silently eat
  # the seconds and undercount the width by two columns. Expanding it here to
  # plain digits sidesteps that — and the clock only updates per prompt anyway.
  local clock_fmt='%D{%H:%M:%S}'
  local clock=${(%%)clock_fmt}
  local right="${exit_code} ${background_jobs} !%h ${clock}"

  # Pad between the two sides so `right` hugs the terminal's right edge. Widths
  # are measured with zero-width escapes stripped (see $_ZERO) and the (m) flag,
  # which counts display columns via wcwidth() — required because several status
  # glyphs (➕ ➖ ❓) are emoji-width and occupy two columns each.
  local lwidth=${(m)#${(S%%)left//$~_ZERO/}}
  local rwidth=${(m)#${(S%%)right//$~_ZERO/}}
  local pad=$(( COLUMNS - lwidth - rwidth ))
  (( pad < 1 )) && pad=1
  local gap=
  gap=${(l:$pad:)gap}

  PROMPT="
${left}${gap}${right}
${S_RADIUS_B}${_SIGN} "
}
add-zsh-hook precmd _0x6d6c_set_prompt

# Status info now lives on the first prompt line (see _0x6d6c_set_prompt).
RPROMPT=""

# This prompt uses shirnk path plugin
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/shrink-path
# Produced output:
# * tilde for home directory
# * last directory name is output in full name
# * directory names are shrinked to 3 characters
# * there is an asterisk added to the shrinked directory names
#PROMPT="
#${S_RADIUS_T}$_USER@$host_full: \
#%B$(shrink_path -l -t -g)%b \
#${git_info} \
#${git_status}
#${S_RADIUS_B}$_SIGN "
