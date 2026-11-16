# Fork notes

This is a fork of [mattpocock/skills](https://github.com/mattpocock/skills), kept as a git remote
named `upstream`. The fork exists for one reason: the skills are written for an English reader,
and some of them state English assumptions as instructions. Here those clauses are softened so
that a Russian session behaves the same way an English one does.

Rules for this fork:

1. **Nothing is translated.** Wording stays upstream's.
2. **One clause per site.** No paragraph is rewritten, no file is restructured.
3. **Everything else comes from upstream**, even where a local version felt nicer.

Sync:

```bash
cd ~/skills/matt-pocock-skills
git fetch upstream --prune
git merge upstream/main          # resolve conflicts in favour of upstream
# re-apply any clause from the table below that the merge lost
git diff upstream/main           # must list only the files in that table
bash scripts/link-skills.sh
```

## Divergences

| File | What the fork changes | Why |
|---|---|---|
| `skills/productivity/wait-what/SKILL.md` | One added sentence: answer in the language of the request, with Simplified Technical English kept as the register. Recorded in `metadata.local_edit`. | The body demanded ASD-STE100 Simplified Technical English, an English-only register, so a Russian request came back in English. |
| `skills/engineering/code-review/SKILL.md` | One added sentence above the two sub-agent briefs: write the brief in the user's language and ask for the report in it; read the 400-word caps as roughly a fifth more in a language that runs longer. | Both briefs are literal English strings handed to a fresh sub-agent, so their language came from the text rather than from the conversation, and 400 words is an English calibration. |
| `skills/engineering/improve-codebase-architecture/HTML-REPORT.md` | Two clauses: the tone section reads "plain, concise prose in the language the user is writing in" instead of "Plain English", and the six-word bullet cap gets the same fifth allowance. | "Plain English" names a language where the intent is plainness; a per-word cap is per-English-word. |
| `skills/engineering/to-tickets/SKILL.md` | One clause: both slugs are ASCII Latin, transliterated when the title is not. | `.scratch/<feature-slug>/issues/<NN>-<slug>.md` built from a Russian title produced Cyrillic paths. |
| `skills/productivity/to-questionnaire/SKILL.md` | Same clause: the slug in `to-questionnaire-<slug>.md` is ASCII Latin. | Same reason. |
| `skills/engineering/domain-modeling/ADR-FORMAT.md` | Same clause: the slug in `0001-slug.md` is ASCII Latin. | Same reason. |
| `skills/productivity/teach/LEARNING-RECORD-FORMAT.md` | Same clause: the slug in `0001-slug.md` is ASCII Latin. | Same reason. |
| `skills/engineering/wayfinder/SKILL.md` | One clause: the `research/<name>` branch name is ASCII Latin, transliterated when the ticket title is not. | A branch name taken from a Russian title lands in `git branch`, PR URLs and CI. |
| `skills/productivity/writing-for-agents/SKILL.md` | One clause: pick the leading word in the language the document is read in. | A leading word works by recruiting pretrained priors, and those do not carry across languages. |
| `CLAUDE.md` | The `link-skills.sh` paragraph gains one sentence about `in-progress/` being skipped and `~/.claude/skills` being conditional. | The script diverges; a contract that says "every skill outside deprecated/ and misc/" would send the next agent to revert the script. |
| `scripts/link-skills.sh` | Five differences, all listed in the file header as `FORK(RarogCmex)`: beta skills are not linked, leftover beta links are removed, broken links in `~/.pi/agent/skills` are pruned, `~/.claude/skills` needs the `claude` CLI, and `LINK_IN_PROGRESS=1` restores upstream's behaviour for a feedback session. | pi reads `~/.agents/skills` directly, so a linked beta skill sits in the model's skill list on every task instead of only during a feedback session. |

## History

- `2026-11-16` merged 28 upstream commits. Before that merge the fork carried a full Russian
  translation of `wait-what`, Russian descriptions for `grill-me` and `grill-with-docs`, and a
  `/skill:<name>` rewording of the `implement` skill. All of it was reverted in `ffac96c` and
  replaced by the clauses above, on the owner's rule that nothing is translated.
- Two earlier attempts to place the language rules outside the skills were reverted: a
  hand-written `~/.pi/agent/AGENTS.md` and a generated block installed by `link-skills.sh`
  (`e84a23f`, reverted in `98c42e3`). The repo is deployed on several machines, and the owner
  wants no reliance on per-machine global instruction files.

## Checked and deliberately left alone

These look like language conflicts and are not. Each one was read, and the reason is recorded so
the next sync does not reopen it.

| Candidate | Why it is not a conflict |
|---|---|
| 25 "Call the Skill tool with X" instructions across 13 files | In pi this resolves to loading the skill, either through `debi_skill` or by reading `SKILL.md`. The instruction stays meaningful, so upstream's wording is kept. |
| `grilling`: "Word each question so yes accepts your recommended answer" | The yes/no framing transfers to Russian intact. |
| `teach` | No language is hardcoded; the docs already cite Korean and Japanese use. |
| `skills/engineering/wizard/template.sh` | Ships UTF-8 glyphs and `read -e` already, and no text handling depends on locale. |
| Triage labels (`needs-triage`, `needs-info`, `ready-for-agent`) | They are identifiers for `gh`; translating them would break the commands. |
| `docs/productivity/wait-what.md`, `README.md`, `ask-matt` saying "in plain English" | Human-facing prose. The model runs the skill body, which is edited separately. |
| `skills/engineering/triage/OUT-OF-SCOPE.md` and the remaining slug templates | Its examples are English and short. Add the same one-clause rule there if a Cyrillic path ever shows up in practice. |
| `.agents/writing-docs.md`, `AGENTS.md` in the parent repo | Repo conventions, not run-time instructions. |

## Verified

- `git diff upstream/main` lists exactly the files in the divergence table.
- Every `SKILL.md` keeps valid frontmatter, with `name` matching its directory.
- `node scripts/sync-plugin-version.mjs --check` reports plugin and package versions in sync.
- `bash -n scripts/link-skills.sh`, then a run: 27 links into `~/.agents/skills`, zero beta links,
  no `~/.claude` created on a machine without the `claude` CLI, no broken links under
  `~/.pi/agent/skills`.
- No em-dashes in the edited English prose, per this repo's own rule.
