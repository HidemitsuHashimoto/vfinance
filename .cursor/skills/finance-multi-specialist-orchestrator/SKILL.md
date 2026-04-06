---
name: finance-multi-specialist-orchestrator
description: >-
  Orchestrates four specialists (Product Owner Finance, Flutter Dev Finance,
  QA Automation, Financial Math) for every implementation task. Uses
  subagents when available; otherwise executes a structured fallback workflow.
---

# Finance multi-specialist orchestrator

## Purpose

Use this skill for any implementation in this project when subagents are not
available, or as a consolidation framework after subagent outputs.

This orchestrator enforces four specialist perspectives:

1. ProductOwnerFinanceSpecialist
2. FlutterFinanceDevelopmentSpecialist
3. FinancialMathSpecialist
4. QaAutomationSpecialist

## Mandatory execution policy

- Always run all four specialists for implementation work.
- If subagents are available in the environment, use the agent role files in
  `.cursor/agents` and execute specialists as subagents.
- If subagents are unavailable, execute the fallback workflow in this skill.
- Do not skip specialist stages even for small implementation tasks.

## Sources of truth and trusted references

- Flutter architecture and testing:
  - https://docs.flutter.dev/app-architecture
  - https://docs.flutter.dev/testing/overview
- Financial consumer protection:
  - https://www.fsb.org/2022/12/cos_111104a/
- Risk assessment:
  - https://csrc.nist.gov/pubs/sp/800/30/r1/final
- Brazil financial/open finance references:
  - https://dadosabertos.bcb.gov.br/
  - https://openfinancebrasil.org.br/atos-normativos/
- Test automation strategy:
  - https://www.istqb.org/certifications/certified-tester-test-automation-strategy-ct-tas/

## Subagent-first workflow

When subagents are available, run these specialists and merge outcomes:

1. ProductOwnerFinanceSpecialist
2. FlutterFinanceDevelopmentSpecialist
3. FinancialMathSpecialist
4. QaAutomationSpecialist

Use these files as role definitions:

- `.cursor/agents/product-owner-finance-agent.md`
- `.cursor/agents/flutter-finance-development-agent.md`
- `.cursor/agents/financial-math-agent.md`
- `.cursor/agents/qa-automation-agent.md`

Expected merged output:

- domain scope and acceptance criteria;
- architecture and implementation decisions;
- financial math validation and assumptions;
- automated test strategy and scenarios.

## Fallback workflow (no subagents)

### Stage 1: Product Owner Finance review

- Define the business objective and user value.
- Write clear acceptance criteria.
- Identify financial consumer risks, fairness, transparency, and data/privacy
  concerns.
- Confirm whether regulatory/open finance constraints apply.

### Stage 2: Flutter Finance implementation design

- Propose architecture aligned with project rules.
- List files to change and why.
- Define error handling and resilience strategy.
- Ensure values and financial calculations are testable and deterministic.

### Stage 3: Financial Math validation

- Validate formulas and conventions.
- Validate precision and rounding expectations.
- Validate edge cases (zero, negative values, long periods, very large values).
- Approve or reject mathematical assumptions.

### Stage 4: QA automation strategy

- Define risk-based test strategy (unit/widget/integration).
- Prioritize critical paths (money movement, balances, statements, sync).
- Define deterministic test data and expected outcomes.
- Define regression checks and minimum coverage targets.

## Output template

Use this structure before coding and before final delivery:

1. Scope and acceptance criteria
2. Implementation plan
3. Financial math validation notes
4. Automated testing plan
5. Go/No-go decision with open risks

## Specialist playbooks

Detailed specialist responsibilities and prompts are defined in:

- `specialists.md`
