# vim:ft=zsh ts=2 sw=2 sts=2

# Variables
local cwd='${PWD/#$HOME/~}'
local exit_code='%(?.%?.%{$bg_bold[red]%}%?%{$reset_color%})'
local background_jobs='%(1j.%{$fg_bold[green]%}%j%{$reset_color%}.%j)'
local host_full='$(hostname --long)'

# Symbols
S_ADDED='\u25cf'
S_BRANCH='\ue0a0'
S_CLEAN='\u2713'
S_DELETED='\u2796'
S_DIRTY='\u2718'
S_MODIFIED='\u2795'
S_PULL="\u2b9f"
S_PUSH="\u2b9d"
S_RADIUS_B=$(echo "\u2514")
S_RADIUS_T=$(echo "\u250C")
S_TAG='\u21b9'
S_UNTRACKED='\u2753'

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
local git_info='$(git_prompt_info)'
local git_status='$(git_prompt_status)'
local git_behind='$(git_commits_behind)'
local git_ahead='$(git_commits_ahead)'
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

# Prompt format: \n User@Host: CWD Branch GitStatus \n PROMPT
#PROMPT="
#${S_RADIUS_T}$_USER@$host_full: \
#%B${cwd}%b\
#${git_info} \
#${git_behind}\
#${git_ahead}\
#${git_status}
#${S_RADIUS_B}$_SIGN "


PROMPT="
${S_RADIUS_T}$_USER@$host_full: \
%B${cwd}%b\
${git_info} \
${git_status}
${S_RADIUS_B}$_SIGN "

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

# RPROMPT format: ExitCode BackgroundJobsCount HistoryEventNumber Time
RPROMPT="$exit_code \
$background_jobs \
!%h \
%*"
