---
name: git-workflow
description: Enforce standard Git commit, branching, staging, and message conventions for the project. Always activate this skill whenever modifying files, creating commits, or preparing changes for upstream push.
---

# Git Workflow and Commit Standards

This skill defines the mandatory Git workflow for all tasks in this repository.

## Invariants and Workflow

1. **Always Commit Completed Changes:**
   - Every task that modifies, creates, refactors, or deletes repository files must conclude with a Git commit.
   - Never leave uncommitted changes or a dirty working tree at the completion of a user request.

2. **Commit Message Standards (Conventional Commits):**
   - Format: `<type>(<scope>): <concise description in present tense>`
   - Allowed types:
     - `feat`: A new feature, enhancement, or capability.
     - `fix`: A bug fix, security correction, or syntax fix.
     - `docs`: Documentation changes only.
     - `refactor`: Structural code changes without changing functional behavior.
     - `chore`: Tooling, workflow, CI, or dependency adjustments.
   - Body: Bulleted list explaining technical rationale, parameters changed, and operational impact.
   - Example:
     ```text
     feat(rclone): optimize VFS cache hygiene and add Google Drive official client parity

     - Parametrize all VFS cache and synchronization flags in rclone@.service
     - Implement hybrid cache eviction policy (24h max-age, 15G cap, 15G min free space guard)
     - Enable Google Drive cloud trash retention (RCLONE_DRIVE_USE_TRASH=true)
     - Update POST_INSTALL.md Section 9 with detailed parameterization
     ```

3. **Staging Discipline:**
   - Explicitly stage relevant files (`git add <file1> <file2>`).
   - Do not stage scratch files, keys, credentials, or temporary logs.
   - Verify staged content with `git status` and `git diff --cached` before creating the commit.

4. **Verification and Tree Integrity:**
   - Execute `git status` post-commit to confirm `working tree clean`.
   - Provide the exact hash and push command (`git push origin <branch>`) to the user.
