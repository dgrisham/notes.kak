This is a small plugin to enable note and task taking. Many commands are exposed
by default, but it is recommended to add a mapping on the main user
mode — `kak-notes` — instead for a quicker onboarding.

# Commands and user modes

Commands are documented as Kakoune commands and all start with `notes-`. There
are five user modes:

- `notes`: the entry-point. It has many useful bindings on it, along with
  access to the rest of the modes.
- `notes-journal-nav` (`J` in `notes`): navigate journals via relative jumps
- `notes-journal-nav-last` (`l` in `notes-journal-nav`): navigate last journals
  (last monday to sunday).
- `notes-tasks` (`t` in `notes`): execute various tasks operations, like
  switching states and opening links.
- `notes-tasks-list` (`l` `notes`): list all tasks or by status, by labels, etc.

# Notes locations

Notes, journals, archives and the capture file are located in `$HOME/notes` by
default — you can switch that place by overriding the value of the
`notes_root_dir` option globally.

Inside that directory, the following paths are used:

- `notes/`: directory containing the notes.
- `archives/`: directory containing archived notes.
- `journal/`: directory containing the journal tree. A journal for a given day
  will be located in e.g. `journal/2024/Oct/Sat 05.md`.
- `capture.md`: capture file.

# Highlighters

The plugin inserts two highlighters in the `shared` scope:

- `kak-notes-tasks`, used to highlight tasks like `- TODO stuff` or
  `- WIP blabla`, as well as subtask lists like `- [ ] Do this` or `- [x] Done`.
- `kak-notes-tasks-list`, used for the list view (similar to the `*grep*`
  buffer).

# Configure

Options:

| Option                   |  Default         | Notes                                     |
| ------                   |  -------         | -----                                     |
| `kak_notes_root_dir`     | `$HOME/notes`    | Root directory where to hold all notes.   |
| `kak_notes_sym_todo`     | `'TODO'`         | Text to use for todo tasks.               |
| `kak_notes_sym_wip`      | `'WIP'`          | Text to use for on-going tasks.           |
| `kak_notes_sym_done`     | `'DONE'`         | Text to use for done tasks.               |
| `kak_notes_sym_wontdo`   | `'WONTDO'`       | Text to use for tasks that won’t be done. |
| `kak_notes_sym_question` | `'QUESTION'`     | Text to use for question tasks.           |
| `kak_notes_sym_hold`     | `'HOLD'`         | Text to use for tasks on-hold.            |
| `kak_notes_sym_review`   | `'REVIEW'`       | Text to use for tasks waiting on review.  |
| `notes_find`             | `fd -t file .md` | Command to run when trying to find notes. |
