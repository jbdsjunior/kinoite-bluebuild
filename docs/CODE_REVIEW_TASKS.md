# Codebase Review — Suggested Tasks

## 1) Typo/structure correction
**Observed issue:** In `README.md`, the **Quick Start** section uses `##` for both the section title and numbered steps (`## Quick Start` followed by `## 1) ...`), which creates inconsistent heading hierarchy.

**Suggested task:** Change step headings to `### 1)`, `### 2)`, etc., while keeping `## Quick Start` as the parent heading.

**Impact:** Better readability and cleaner navigation in generated tables of contents.

---

## 2) Bug fix
**Observed issue:** `files/scripts/setup-kvm.sh` adds group membership with `usermod -aG` without explicit prior validation that the target user exists.

**Suggested task:** Add an explicit user existence validation (for example `id "$TARGET_USER" >/dev/null 2>&1`) before running `usermod`, and return a clear error message.

**Impact:** More predictable failure mode and better operator experience during post-install setup.

---

## 3) Documentation/comment alignment
**Observed issue:** The `tmpfiles-system` alias in `files/system/etc/profile.d/kinoite-aliases.sh` includes an explicit config path, while the summary table in `AGENTS.md` used a generic command form.

**Suggested task:** Align `AGENTS.md` with the exact command used by the shipped alias.

**Impact:** More accurate operational documentation and reduced ambiguity.

---

## 4) Test improvement
**Observed issue:** There was no dedicated CI workflow for fast syntax/lint validation of shell scripts and YAML files.

**Suggested task:** Add a lightweight lint workflow with:
- `shellcheck` for `files/scripts/*.sh` and `files/system/etc/profile.d/*.sh`;
- `yamllint` for `recipes/*.yml` and `.github/workflows/*.yml`.

**Impact:** Earlier detection of simple regressions before longer image build workflows.
