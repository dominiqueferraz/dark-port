# Project instructions

- Respond in English unless the user asks for another language.

## Commits

- Write each commit message with a subject of at most 80 characters. Add a body only when necessary to explain the change beyond the title, and limit it to at most three sentences. Separate any body from the subject with a blank line and keep every body line at most 80 characters. Use concise, concrete language matching repository terminology. Validate every line of the exact message before each commit or amend. Use a message file for multiline messages so the validated text is the text Git receives. Never add `Co-Authored-By` or other attribution trailers.
- Preserve unrelated work in every checkout and commit only paths you changed for the task.
- Make one commit per cohesive, reviewable outcome. Keep its source, tests, documentation and plan progress together under a subject that names the outcome. Amend the unpromoted commit to fix defects found during verification or review. Once a commit is on `main`, use a new commit for later fixes.
- Commit a plan or its progress on its own only when the user asks for it or when the plan is itself the change.
- Include version changes in the related source commit. Leave version-only archive updates uncommitted for the next related source change.
- Develop in a separate `codex/*` branch or worktree unless the user explicitly authorizes work directly on `main`. Get explicit authorization before promoting to `main` or opening a pull request.
