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
# The git status glyphs are deliberately plain single-column characters (see
# issue #7): the previous emoji were double-width and complicated the
# right-alignment width calculation (issue #1).
S_ADDED=$(echo "A")
S_BRANCH=$(echo "")
S_DELETED=$(echo "D")
S_DIRTY=$(echo "*")
S_MODIFIED=$(echo "M")
S_PULL=$(echo "↓")
S_PUSH=$(echo "↑")
S_RADIUS_B=$(echo "└")
S_RADIUS_T=$(echo "┌")
S_TAG=$(echo ":")
S_UNTRACKED=$(echo "U")

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
# A clean repo shows no marker; the dirty marker "*" prepends the branch name
# ("*master", issue #7), so it carries no leading space.
PROMPT_DIRTY="%{$fg[red]%}${S_DIRTY}%{$reset_color%}"


# Git info
git_info='$(git_prompt_info)'
git_status='$(git_prompt_status)'
git_behind='$(git_commits_behind)'
git_ahead='$(git_commits_ahead)'
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[magenta]%}${S_PUSH}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_ADDED="%{$fg_bold[green]%}${S_ADDED}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[magenta]%}${S_PULL}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="${PROMPT_DIRTY}"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg_bold[grey]%}${S_DELETED}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg_bold[yellow]%}${S_MODIFIED}%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_PREFIX=" ${PROMPT_PREFIX1}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${PROMPT_SUFFIX}"
ZSH_THEME_GIT_PROMPT_TAG_PREFIX="${S_TAG}"
ZSH_THEME_GIT_PROMPT_TAG_SUFFIX=""
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[red]%}${S_UNTRACKED}%{$reset_color%}"

# Nearest tag reachable from HEAD, shown alongside the branch. A tag belongs to
# a commit, not a branch, so this single rule covers both the common case (a
# release tag on main, even when HEAD sits a few commits past it) and the rare
# case (a tag on a feature branch's history). We use `git describe --tags
# --abbrev=0`, i.e. the most recent tag that is an ancestor of HEAD, name only —
# no commit-distance suffix. When HEAD is *detached and sitting exactly on a
# tag*, _0x6d6c_git_info already uses that tag as the ref, so we skip that one
# case to avoid printing it twice. On a normal branch checkout the ref is the
# branch name and the tag is appended as ":<tag>".
_0x6d6c_git_tag() {
  local g
  if (( $+functions[__git_prompt_git] )); then
    g=__git_prompt_git
  else
    g="command git"
  fi
  $g rev-parse --git-dir &> /dev/null || return 0
  # Detached HEAD exactly on a tag → it is already the ref. Skip.
  if ! $g symbolic-ref --quiet HEAD &> /dev/null \
     && $g describe --tags --exact-match HEAD &> /dev/null; then
    return 0
  fi
  local tag
  tag=$($g describe --tags --abbrev=0 2> /dev/null) || return 0
  [[ -n $tag ]] && echo "${ZSH_THEME_GIT_PROMPT_TAG_PREFIX}${tag//\%/%%}${ZSH_THEME_GIT_PROMPT_TAG_SUFFIX}"
}

# Full branch segment: " <icon> [*]<ref>[:<tag>]". The dirty marker "*" PREPENDS
# the ref (issue #7); a clean repo shows no marker at all. omz's git_prompt_info
# can only append the dirty marker, so the segment is assembled here instead.
# Rendered synchronously via __git_prompt_git, sidestepping omz's async git
# cache exactly like _0x6d6c_git_tag (see _0x6d6c_set_prompt for why).
_0x6d6c_git_info() {
  local g
  if (( $+functions[__git_prompt_git] )); then
    g=__git_prompt_git
  else
    g="command git"
  fi
  $g rev-parse --git-dir &> /dev/null || return 0
  [[ "$($g config --get oh-my-zsh.hide-info 2> /dev/null)" == 1 ]] && return 0

  # ref: branch name, else the tag we sit exactly on, else short SHA (mirrors omz).
  local ref
  ref=$($g symbolic-ref --short HEAD 2> /dev/null) \
    || ref=$($g describe --tags --exact-match HEAD 2> /dev/null) \
    || ref=$($g rev-parse --short HEAD 2> /dev/null) \
    || return 0

  # Dirty state via omz's parse_git_dirty (honours its config/flags). A clean
  # repo shows nothing; a dirty one prepends "*" to the ref.
  local pre=""
  if (( $+functions[parse_git_dirty] )) \
     && [[ "$(parse_git_dirty)" == "$ZSH_THEME_GIT_PROMPT_DIRTY" ]]; then
    pre="$ZSH_THEME_GIT_PROMPT_DIRTY"
  fi

  echo "${ZSH_THEME_GIT_PROMPT_PREFIX}${pre}${PROMPT_PREFIX2}${ref//\%/%%}%{$reset_color%}$(_0x6d6c_git_tag)${ZSH_THEME_GIT_PROMPT_SUFFIX}"
}

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
  # >= 5.0.6) makes git_prompt_status merely echo a cache that is only filled
  # when the literal string "$(git_prompt_status)" is found in $PS1. We build
  # $PS1 here with the value already expanded, so that detection never fires and
  # the cache stays empty. Call the synchronous worker directly instead; fall
  # back to the public function on setups that predate the async refactor. The
  # branch/tag/dirty segment is built by _0x6d6c_git_info (also synchronous, via
  # __git_prompt_git) so it can prepend the dirty marker and join the tag.
  local gitinfo gitstatus
  gitinfo="$(_0x6d6c_git_info)"
  if (( $+functions[_omz_git_prompt_status] )); then
    gitstatus="$(_omz_git_prompt_status)"
  else
    gitstatus="$(git_prompt_status)"
  fi

  # Left side of the first line: ┌user@host: cwd <git_info> <git_status>
  local left="${S_RADIUS_T}${_USER}@${(e)host_full}: %B${(e)cwd}%b${gitinfo} ${gitstatus}"

  # Right side of the first line. Non-zero exit codes show on a red background.
  local exit_code="$exit_status"
  (( exit_status != 0 )) && exit_code="%{$bg[red]%}%{$fg_bold[white]%} ${exit_status} %{$reset_color%}"
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
  # which counts display columns via wcwidth(). The status glyphs are now plain
  # single-column characters (issue #7), so (m) currently matches a plain count;
  # it is kept as a safeguard because the earlier emoji glyphs were double-width
  # and a plain ${#…} undercounted them, overflowing the right edge.
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
