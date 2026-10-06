---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
metadata:
  fork: RarogCmex/matt-pocock-skills
  upstream: mattpocock/skills
  localized_at: "2026-10-05"
  local_edit: "ссылки на скиллы переведены в синтаксис pi: /tdd → /skill:tdd, /code-review → /skill:code-review. Апстрим с #878 пишет 'Call the Skill tool'; в pi такого инструмента нет, его роль играет /skill:<имя>"
---

Implement the work described by the user in the spec or tickets.

Use `/skill:tdd` where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, use `/skill:code-review` to review the work.

Commit your work to the current branch.
