# Global directory for notes.
# declare-option str notes_root_dir "%sh{ echo $HOME/notes }"
declare-option str notes_root_dir %sh{
    dir=${NOTES_DIR:-$SCRATCH/notes}
    mkdir -p $dir
    echo $dir
}


# Active directory.
#
# Global directory (`notes_root_dir`) or a local override.
declare-option str notes_active_dir "%opt{notes_root_dir}"

declare-option str notes_sym_todo 'TODO'
declare-option str notes_sym_wip 'WIP'
declare-option str notes_sym_done 'DONE'
declare-option str notes_sym_wontdo 'WONTDO'
declare-option str notes_sym_idea 'IDEA'
declare-option str notes_sym_question 'QUESTION'
declare-option str notes_sym_hold 'HOLD'
declare-option str notes_sym_review 'REVIEW'
declare-option str notes_sym_note 'NOTE'
declare-option str notes_find 'fd -t file .md'
declare-option -hidden str notes_tasks_list_current_line
declare-option -hidden str notes_journal_now

# Main notes mode.
declare-user-mode notes

# Mode to edit tasks.
declare-user-mode notes-tasks

# Mode to list tasks.
declare-user-mode notes-tasks-list

# Mode to navigate journal.
declare-user-mode notes-journal-nav

# Mode to navigate journal (last journals).
declare-user-mode notes-journal-nav-last

declare-user-mode notes-open-link

set-face global notes_todo green
set-face global notes_wip blue
set-face global notes_done rgb:ffffff
set-face global notes_wontdo red
set-face global notes_idea green
set-face global notes_question cyan
set-face global notes_hold red
set-face global notes_review yellow

set-face global notes_issue cyan+u
set-face global notes_subtask_uncheck green
set-face global notes_subtask_check rgb:ffffff
set-face global notes_subtask_check_partial yellow
set-face global notes_tag blue+i

# Open the daily journal.
define-command notes-journal-open -docstring 'open daily journal' %{
  evaluate-commands %{
    edit "%opt{notes_active_dir}/journal/%sh{ date '+%Y-%m-%d' }.md"
    set-option buffer notes_journal_now %sh{ date }
  }
}

# Open a journal relative to today.
define-command -hidden notes-journal-open-rel -params -1 %{
  evaluate-commands %{
    edit -existing "%opt{notes_active_dir}/journal/%sh{ date -d ""$kak_opt_notes_journal_now $1"" ""+%Y-%m-%d"" }.md"
    set-option buffer notes_journal_now %sh{ date -d """$kak_opt_notes_journal_now $1""" }
  }
}

# Open a note by prompting the user with a menu.
define-command notes-open -docstring 'open note' %{
  prompt -menu -shell-script-candidates "$kak_opt_notes_find $kak_opt_notes_active_dir/notes" 'open note:' %{
    edit %sh{
      echo "${kak_text%.md}.md"
    }
  }
}

# Create a new note by prompting the user for its text.
define-command notes-new-note -docstring 'new note' %{
  prompt note: %{
    edit %sh{
      echo "$kak_opt_notes_active_dir/notes/${kak_text%.md}.md"
    }
  }
}

# Archive a note by prompting the user for which note to operate on.
define-command notes-archive-note -docstring 'archive note' %{
  prompt -menu -shell-script-candidates "$kak_opt_notes_find $kak_opt_notes_active_dir/notes" archive: %{
    nop %sh{
      mkdir -p "$kak_opt_notes_active_dir/archives"
      mv "$kak_text" "$kak_opt_notes_active_dir/archives/"
    }
  }
}

# Prompt the user to pick and open an archived note.
define-command notes-archive-open -docstring 'open archive' %{
  prompt -menu -shell-script-candidates "$kak_opt_notes_find $kak_opt_notes_active_dir/archives" 'open archive:' %{
    edit %sh{
      echo "${kak_text%.md}.md"
    }
  }
}

# Capture a new note for the current git branch.
define-command notes-branch-capture -docstring 'capture note for current git branch' %{
  prompt capture: %{
    nop %sh{
      dir="$kak_opt_notes_active_dir/$(git branch --show-current 2>/dev/null)"
      mkdir -p $dir
      echo "> $(date '+%a %b %d %Y, %H:%M:%S')\n$kak_text\n" >> "$dir/notes.md"
    }
  }
}

# Open the capture file for current git branch.
define-command notes-branch-open -docstring 'open notes for current git branch' %{
  edit %sh{
    dir="$kak_opt_notes_active_dir/$(git branch --show-current 2>/dev/null)"
    mkdir -p $dir
    echo "$dir/notes.md"
  }
}

# Capture a new note.
define-command notes-capture -docstring 'capture' %{
  prompt capture: %{
    nop %sh{
      echo "> $(date '+%a %b %d %Y, %H:%M')\n$kak_text\n" >> "$kak_opt_notes_active_dir/notes.md"
    }
  }
}

# Open the capture file.
define-command notes-open-capture -docstring 'open capture' %{
  edit "%opt{notes_active_dir}/notes.md"
}

# Switch the status of a note to the input parameter.
# define-command notes-task-switch-status -params 1 -docstring 'switch task' %{
#   execute-keys -draft "git:c%arg{1}"
# }
# define-command notes-task-switch-status -params 1 -docstring 'switch task' %{
#   execute-keys -draft "<a-i>p<a-;>jwc%arg{1}"
# }
define-command notes-task-switch-status -params 1 -docstring 'switch task' %{
  # NOTE: this doesn't work if the `<status>:` is the first line in the file.
  # But when you search, it finds the first result starting *after* the current position
  # of the cursor, which is why I use the `k` to move above the top of the selected paragraph
  # before searcing for the status.
  execute-keys -draft "<a-i>p<a-;>k/^[A-Z]+:<ret>c%arg{1}"
}

# View links
define-command -hidden notes-task-open-link -params 1 -docstring 'open link' %{
  evaluate-commands -save-regs 'i' %{
    execute-keys -draft '<a-i><a-w>"iy'
    evaluate-commands %sh{
        tmux_cmd=$1
        # match #<num> for GH pr
        # [[ "$kak_reg_i" =~ ^#[0-9]+$ ]] && printf "tmux-terminal-window zsh -c 'gh pr view ${kak_reg_i:1}; zsh'"
        [[ "$kak_reg_i" =~ ^#[0-9]+$ ]] && printf "$tmux_cmd zsh -c 'gh pr view ${kak_reg_i:1}; zsh'"
        # match AAAA-NNNN for jira issue (A = alphanumeric, N = numeric)
        [[ "$kak_reg_i" =~ ^[A-Z0-9]{2,4}-[0-9]+$ ]] && printf "$tmux_cmd zsh -c 'source ~/.config/zsh/.zshrc; jira issue view --comments 5 $kak_reg_i; zsh'"
    }
  }
}

define-command -hidden notes-link-tmux-vertical %{
    notes-task-open-link tmux-terminal-vertical
}
define-command -hidden notes-link-tmux-horizontal %{
    notes-task-open-link tmux-terminal-horizontal
}
define-command -hidden notes-link-tmux-window %{
    notes-task-open-link tmux-terminal-window
}

# define-command -hidden notes-tasks-open-link-tmux -params 2 %{
#   edit -scratch *notes-tasks-list*
#   unset-option buffer notes_tasks_list_current_line
#   # execute-keys "%%d|ag --filename --numbers --column '%arg{1}' '%opt{notes_active_dir}/'<ret>|sort<ret>gg"
#   execute-keys "%%d|cd '%opt{notes_active_dir}/'; rg -n -e '%arg{1}' .<ret>|perl -pe 's|(.*?)/notes.md|\1|' | sort<ret>gg"
# }

define-command -hidden notes-tasks-list-by-regex -params 1 -docstring 'list tasks by status' %{
  edit -scratch *notes-tasks-list*
  unset-option buffer notes_tasks_list_current_line
  # execute-keys "%%d|ag --filename --numbers --column '%arg{1}' '%opt{notes_active_dir}/'<ret>|sort<ret>gg"
  execute-keys "%%d|cd '%opt{notes_active_dir}/'; rg -n -e '%arg{1}' .<ret>|perl -pe 's|(.*?)/notes.md|\1|' | sort<ret>gg"
}

# List all tasks.
define-command notes-tasks-list-all -docstring 'list all tasks' %{
  notes-tasks-list-by-regex "%opt{notes_sym_todo}|%opt{notes_sym_wip}|%opt{notes_sym_done}|%opt{notes_sym_wontdo}|%opt{notes_sym_idea}|%opt{notes_sym_question}|%opt{notes_sym_hold}"
}

# Command executed when pressing <ret> in a *notes-tasks-list* buffer.
define-command -hidden notes-tasks-list-open %{
  set-option buffer notes_tasks_list_current_line %val{cursor_line}
  execute-keys -with-hooks -save-regs 'flc' 'giT:"fyllT:"ly:edit "%opt{notes_active_dir}/%reg{f}/notes.md" %reg{l}<ret>'
}

# Run a grepper with the provided arguments as search query.
define-command -hidden notes-grepcmd -params 2 %{
  # Initial implementation based on rg <pattern> <path>.
  execute-keys ":grep %arg{2} %arg{1}<ret>"
}

# Prompt the user for terms to search in notes, journals, archives and the
# capture file.
define-command notes-search -docstring 'search notes' %{
  prompt 'search notes:' %{
    notes-grepcmd "%opt{notes_active_dir}" "%val{text}"
  }
}

# Synchronize notes remotely.
define-command notes-sync -docstring 'synchronize notes' %{
  # First, we always check-in new modifications; then, we check whether we have anything else to send
  info -title 'notes' 'starting synchronizing…'

  nop %sh{
    cd $kak_opt_notes_active_dir
    git fetch --prune origin
    git rebase --autostash origin/master
    git add -A .
    git commit -m "$(date +'Sync update %a %b %d %Y')"
    git push origin
  }

  info -title 'notes' 'finished synchronizing'
}

# Toggle overriding the active directory with pwd and vice versa.
define-command notes-override-active-dir -docstring 'override the active directory with PWD' %{
  set-option global notes_active_dir %sh{
    dir=$(pwd)
    if [ "$kak_opt_notes_active_dir" == "$dir" ]; then
      echo "$kak_opt_notes_root_dir"
    else
      echo "$dir"
    fi
  }

  info -title notes "active dir: %opt{notes_active_dir}"
}

add-highlighter shared/notes-tasks group
add-highlighter shared/notes-tasks/todo regex "(%opt{notes_sym_todo})"         1:notes_todo
add-highlighter shared/notes-tasks/wip regex "(%opt{notes_sym_wip})"           1:notes_wip
add-highlighter shared/notes-tasks/done regex "(%opt{notes_sym_done})"         1:notes_done
add-highlighter shared/notes-tasks/wontdo regex "(%opt{notes_sym_wontdo})"     1:notes_wontdo
add-highlighter shared/notes-tasks/idea regex "(%opt{notes_sym_idea})"         1:notes_idea
add-highlighter shared/notes-tasks/question regex "(%opt{notes_sym_question})" 1:notes_question
add-highlighter shared/notes-tasks/hold regex "(%opt{notes_sym_hold})"         1:notes_hold
add-highlighter shared/notes-tasks/review regex "(%opt{notes_sym_review})"     1:notes_review
add-highlighter shared/notes-tasks/note regex "(%opt{notes_sym_note})"         1:notes_note
add-highlighter shared/notes-tasks/issue regex " (#[0-9]+)"                    1:notes_issue
add-highlighter shared/notes-tasks/subtask-uncheck regex "-\s* (\[ \])[^\n]*"  1:notes_subtask_uncheck
add-highlighter shared/notes-tasks/subtask-check regex "-\s* (\[x\])\s*([^\n]*)"\
  1:notes_subtask_check
add-highlighter shared/notes-tasks/subtask-check-partial regex "-\s* (\[/\])\s*([^\n]*)"\
  1:notes_subtask_check_partial

add-highlighter shared/notes-tasks-list group
add-highlighter shared/notes-tasks-list/path regex "^((?:\w:)?[^:\n]+):(\d+):(\d+)?" 1:green 2:blue 3:blue
add-highlighter shared/notes-tasks-list/current-line line %{%opt{notes_tasks_list_current_line}} default+b

map global notes A ':notes-archive-note<ret>'                -docstring 'archive note'
map global notes a ':notes-archive-open<ret>'                -docstring 'open archived note'
map global notes B ':notes-branch-capture<ret>'              -docstring 'capture note for current git branch'
map global notes b ':notes-branch-open<ret>'                 -docstring 'open notes for current git branch'
map global notes C ':notes-capture<ret>'                     -docstring 'capture'
map global notes c ':notes-open-capture<ret>'                -docstring 'open capture'
map global notes j ':notes-journal-open<ret>'                -docstring 'open journal'
map global notes J ':enter-user-mode notes-journal-nav<ret>' -docstring 'navigate journals'
map global notes l ':enter-user-mode notes-tasks-list<ret>'  -docstring 'tasks list'
map global notes n ':notes-new-note<ret>'                    -docstring 'new note'
map global notes N ':notes-open<ret>'                        -docstring 'open note'
map global notes / ':notes-search<ret>'                      -docstring 'search in notes'
map global notes S ':notes-sync<ret>'                        -docstring 'synchronize notes'
map global notes t ':enter-user-mode notes-tasks<ret>'       -docstring 'tasks'
map global notes z ':notes-override-active-dir<ret>'         -docstring 'switch notes dir with PWD'

map global notes-journal-nav l ':enter-user-mode notes-journal-nav-last<ret>' -docstring 'last…'
map global notes-journal-nav d ':notes-journal-open-rel "-1 day"<ret>'        -docstring 'day before'
map global notes-journal-nav D ':notes-journal-open-rel "+1 day"<ret>'        -docstring 'day after'
map global notes-journal-nav w ':notes-journal-open-rel "-1 week"<ret>'       -docstring 'week before'
map global notes-journal-nav W ':notes-journal-open-rel "+1 week"<ret>'       -docstring 'week after'
map global notes-journal-nav m ':notes-journal-open-rel "-1 month"<ret>'      -docstring 'month before'
map global notes-journal-nav M ':notes-journal-open-rel "+1 month"<ret>'      -docstring 'month after'

map global notes-journal-nav-last m ':notes-journal-open-rel "last monday"<ret>'    -docstring 'monday'
map global notes-journal-nav-last t ':notes-journal-open-rel "last tuesday"<ret>'   -docstring 'tuesday'
map global notes-journal-nav-last w ':notes-journal-open-rel "last wednesday"<ret>' -docstring 'wednesday'
map global notes-journal-nav-last h ':notes-journal-open-rel "last thursday"<ret>'  -docstring 'thursday'
map global notes-journal-nav-last f ':notes-journal-open-rel "last friday"<ret>'    -docstring 'friday'
map global notes-journal-nav-last T ':notes-journal-open-rel "last saturday"<ret>'  -docstring 'saturday'
map global notes-journal-nav-last S ':notes-journal-open-rel "last sunday"<ret>'    -docstring 'sunday'

map global notes-tasks-list a ":notes-tasks-list-all<ret>"                               -docstring 'list all tasks'
map global notes-tasks-list d ":notes-tasks-list-by-regex %opt{notes_sym_done}<ret>"     -docstring 'list done tasks'
map global notes-tasks-list h ":notes-tasks-list-by-regex %opt{notes_sym_hold}<ret>"     -docstring 'list hold tasks'
map global notes-tasks-list i ":notes-tasks-list-by-regex %opt{notes_sym_idea}<ret>"     -docstring 'list ideas'
map global notes-tasks-list l ":notes-tasks-list-by-regex '\ :[^:]+:'<ret>"              -docstring 'list tasks by labels'
map global notes-tasks-list o ":notes-tasks-list-by-regex %opt{notes_sym_wontdo}<ret>"   -docstring 'list wontdo tasks'
map global notes-tasks-list q ":notes-tasks-list-by-regex %opt{notes_sym_question}<ret>" -docstring 'list questions'
map global notes-tasks-list r ":notes-tasks-list-by-regex %opt{notes_sym_review}<ret>"   -docstring 'list reviews'
map global notes-tasks-list n ":notes-tasks-list-by-regex %opt{notes_sym_note}<ret>"     -docstring 'list notes'
map global notes-tasks-list t ":notes-tasks-list-by-regex %opt{notes_sym_todo}<ret>"     -docstring 'list todo tasks'
map global notes-tasks-list w ":notes-tasks-list-by-regex %opt{notes_sym_wip}<ret>"      -docstring 'list wip tasks'

hook -group notes-tasks global WinCreate \*notes-tasks-list\* %{
  map buffer normal '<ret>' ':notes-tasks-list-open<ret>'
  add-highlighter window/ ref notes-tasks
  add-highlighter window/ ref notes-tasks-list
}

hook -group notes-tasks global WinCreate .*\.md %{
  add-highlighter window/ ref notes-tasks

  map window notes-tasks d  ":notes-task-switch-status %opt{notes_sym_done}<ret>"     -docstring 'switch task to done'
  map window notes-tasks h  ":notes-task-switch-status %opt{notes_sym_hold}<ret>"     -docstring 'switch task to hold'
  map window notes-tasks i  ":notes-task-switch-status %opt{notes_sym_idea}<ret>"     -docstring 'switch task to idea'
  map window notes-tasks o  ":notes-task-switch-status %opt{notes_sym_wontdo}<ret>"   -docstring 'switch task to wontdo'
  map window notes-tasks q  ":notes-task-switch-status %opt{notes_sym_question}<ret>" -docstring 'switch task to question'
  map window notes-tasks r  ":notes-task-switch-status %opt{notes_sym_review}<ret>"   -docstring 'switch task to review'
  map window notes-tasks n  ":notes-task-switch-status %opt{notes_sym_note}<ret>"     -docstring 'switch task to note'
  map window notes-tasks t  ":notes-task-switch-status %opt{notes_sym_todo}<ret>"     -docstring 'switch task to todo'
  map window notes-tasks w  ":notes-task-switch-status %opt{notes_sym_wip}<ret>"      -docstring 'switch task to wip'

  map window notes-tasks o             ':enter-user-mode notes-open-link<ret>' -docstring 'open link'
  map window notes-open-link '\'       ':notes-link-tmux-horizontal<ret>'      -docstring 'horizontal split'
  map window notes-open-link '<minus>' ':notes-link-tmux-vertical<ret>'        -docstring 'vertical split'
  map window notes-open-link c         ':notes-link-tmux-window<ret>'          -docstring 'new window'
}
