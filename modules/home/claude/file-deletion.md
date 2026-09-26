# Filesystem deletion

- Never delete any file or directory on this machine, including temporary files created during a task. Never move anything to Trash.
- Never run `rm`, `rmdir`, `unlink`, `find -delete`, `git clean`, or any other command, script, API, or tool whose purpose or effect is deleting files or directories.
- Do not work around this rule through a shell, a programming language, a GUI, or an indirect cleanup command. If a command combines deletion with other actions, do not run it.
- When removal or cleanup is appropriate, first use read-only commands to identify the exact targets. Then report those targets and give the exact deletion commands for the user to run. Do not run them.
- Leave task-created temporary files and directories in place, and report their paths when relevant.
- Internal cleanup of non-filesystem cache or index records is allowed only when it cannot delete underlying files, such as a search tool removing orphaned index records.

## The one exception

If the user explicitly tells you to delete a specific thing, you may delete exactly that, and nothing more. The instruction has to name what to delete. General wording such as "clean up" or "tidy the repo" is not permission. It covers only that request; it does not carry over to later tasks.
