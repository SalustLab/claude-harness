# Builder-readiness review

Use for a substantial written design, with an independent reviewer when
available and authorized, or as a self-review otherwise. Supply the document
path and domain. Review only; do not edit files or execute implementation.

Read the design as a competent builder who must plan the work without asking
its author for background. Report questions that still require a consequential
guess, ranked by impact, with the document location and why the answer changes
the plan. Check contradictions, missing requirements and oversized scope.

Skip stylistic preferences, decisions explicitly left to implementation and
choices a competent builder can safely make. If no consequential uncertainty
remains, say so. The caller resolves facts from existing context, records minor
implementation calls, and asks the user only about remaining product decisions.
