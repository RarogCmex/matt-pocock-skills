# Language rules for these skills

`scripts/link-skills.sh` installs this file into each harness's global instruction file,
between `matt-pocock-skills:language-begin` and `matt-pocock-skills:language-end` markers.
This copy is the source of truth: edit here, re-run the script, and every machine picks the
change up on its next run.

The skills are written in English and several of them assume an English reader. When the work
is done in another language, those assumptions must not drag the output into English. Five
rules, ordered by how often they bite.

## 1. Output language

The reply, the files, the commits, the reviews, the tickets, the lesson text and the sub-agent
reports use the language of the user's request. A skill asking for "plain English",
"Simplified Technical English" or "plain technical" prose is naming a register, not a
language: keep the register, keep the language. A sub-agent brief is written in the
conversation's language and asks for the report in the same one.

## 2. Numeric limits

Limits such as "Under 400 words" (`code-review`) and "bullets, ≤6 words each" or "one
sentence" (`improve-codebase-architecture`) are calibrated on English. Text in other languages
runs 10 to 15 percent longer for the same content. Keep the content, allow up to 20 percent
more length, and cut filler rather than meaning.

## 3. Slugs, file names, branch names

Slugs stay ASCII Latin even when the topic is not: `<feature-slug>`, `NN-<slug>.md`,
`to-questionnaire-<slug>.md`, `0001-slug.md`, `research/<name>`. Transliterate them. File
contents stay in the working language; only the path is Latin.

## 4. Terms and leading words

Take terms from the project's `GLOSSARY.md` as written instead of translating them mid
sentence. A leading word (`writing-for-agents`) works by recruiting priors, so it has to be a
word the model holds in the language being written: a Russian document wants a Russian term,
because an English one recruits nothing there.

## 5. Punctuation

The no-em-dash rule in this repo's `CLAUDE.md` governs this repo's English prose. A language
with its own dash convention uses that convention in its own text: Russian sets a dash between
subject and predicate with no copula, after a conditional clause, and in place of an omitted
member.
