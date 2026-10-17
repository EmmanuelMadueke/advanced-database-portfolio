# Assessment deliverable audit

Owner, author, and maintainer: **Emmanuel Madueke**.

Audit date: **17 October 2026**. Baseline: commit `45087be`, plus the documentation corrections recorded in this audit.

## Finding and scope

All five portfolio activities have retained evidence corresponding to section 4 of the supplied MIT 8103 assessment brief. **The repository is not yet ready for final submission:** the 2–3 page LMS summary, individual reflection, final reference/declaration review, and repository-access verification remain pending.

The source is *MIT 8103 Advanced Database Systems, September cohort 2026*, sections 2–12, retained locally as `guide/mit-8103-advanced-database-systems-ca-september-cohort-2026.pdf`. This audit checks deliverable coverage against that brief, reads activity documentation and selected saved outputs, and checks local documentation paths. It is not a new execution of database tests, a grade prediction, or a claim of Emmanuel's independent verification.

## Case-study consistency

The [case study](case-study.md) names the online fashion retail store, its customers and administrators, its catalogue/inventory/order/payment/delivery data, and its browsing, checkout, fulfilment, and reporting operations. [Requirements](requirements.md) expand the users and business needs.

All five activities use that scenario: relational product variants and purchases; store reports and optimisation; competing purchases of scarce inventory; MongoDB enrichment for the same SQL-linked products; and proposed distributed operation of those stores. The deliberately unsafe race is an isolated teaching model, not an alternative production schema. MongoDB profiles supplement SQL ownership rather than replacing transactional stock. Portfolio 5 explicitly uses the permitted discussion path.

## Section 4 evidence map

| Activity / brief requirement | Evidence inspected or mapped | Finding and limits |
| --- | --- | --- |
| **1 — Case study, ERD, relational schema, keys, constraints, normalisation** | [ERD](../diagrams/conceptual-erd.svg), [schema](relational-schema.md), [dictionary](data-dictionary.md), [normalisation](normalization.md), [SQL and evidence index](../portfolio-1-database-design/README.md), [installation/integrity evidence](../portfolio-1-database-design/evidence/README.md) | Covered. Sixteen tables; saved evidence reports 35 integrity/workflow checks, 10 sample checks, and 4 scale checks. No fresh installation performed in this audit. |
| **2 — SQL, results, execution plans, optimisation evidence, performance analysis** | [Twelve queries and results](../portfolio-2-query-optimisation/README.md), [baseline plans](../portfolio-2-query-optimisation/evidence/baseline/README.md), [controlled comparison](../portfolio-2-query-optimisation/optimisation/README.md), [saved optimisation outputs](../portfolio-2-query-optimisation/evidence/optimisation/README.md) | Covered. Thirty sample checks, repeated measurements for five reports, three indexes and a history rewrite, result equivalence and seven history cases documented. Synthetic workload and warm-cache limitations retained; no production performance claim. |
| **3 — Commit, rollback, isolation, concurrency issue/control, output evidence** | [Activity evidence map](../portfolio-3-transactions-concurrency/README.md), [COMMIT output](../portfolio-3-transactions-concurrency/evidence/commit-verification.txt), [ROLLBACK output](../portfolio-3-transactions-concurrency/evidence/rollback-verification.txt), [isolation](../portfolio-3-transactions-concurrency/isolation.md), [unsafe race](../portfolio-3-transactions-concurrency/unsafe-concurrency.md), [protected race](../portfolio-3-transactions-concurrency/protected-concurrency.md) | Covered. Saved demonstrations report 8, 6, 7, 8, and 11 checks respectively. Text output is accepted evidence under the brief; screenshots are not the only permitted format. Payments are simulated and finalisation replay is narrower than request-level idempotency. |
| **4 — Same-case NoSQL model, example, implementation, suitability** | [Document model](../portfolio-4-nosql/document-model.md), [implementation](../portfolio-4-nosql/implementation.md), [load output](../portfolio-4-nosql/evidence/implementation/load-checks.txt), [queries](../portfolio-4-nosql/queries/README.md), [comparison](../portfolio-4-nosql/sql-nosql-comparison.md) | Covered. Three SQL-linked profiles, 22 load checks, 4 fresh-connection checks, and 16 query/index checks retained. Standalone MongoDB and snapshot reconciliation only; diagnostic hinted index evidence does not establish a speedup. |
| **5 — Distributed/cloud discussion or setup** | [Scope](../portfolio-5-distributed-cloud/scope.md), [replication](../portfolio-5-distributed-cloud/replication-availability.md), [consistency/sharding](../portfolio-5-distributed-cloud/consistency-sharding.md), [diagram and scenarios](../portfolio-5-distributed-cloud/architecture-scenarios.md), [conclusions](../portfolio-5-distributed-cloud/conclusions.md) | Covered through sourced discussion of all four named topics. Proposed three-zone topology and eight scenarios; no deployment, failover test, or measured recovery objective. |

“Covered” means the required type of work and supporting evidence are present, not that every implementation detail has been independently proved correct. The subsequent reproduction results are linked below.

## Repository and documentation review

- Five activity directories and READMEs exist, with SQL, models, scripts, actual outputs, plans, and analysis linked from their respective activity documentation.
- The initial local-path check examined **40 tracked Markdown files and 295 relative link targets**, with none missing. This establishes path existence only, not external URL availability or the correctness of every anchor.
- Local Git history shows focused stages through `45087be`; that commit was pushed successfully. This does not establish repository privacy or assessor access.
- The repository link for the submission is [EmmanuelMadueke/advanced-database-portfolio](https://github.com/EmmanuelMadueke/advanced-database-portfolio). It is derived from the configured remote; access as the assessor has not been tested.
- Root README corrections replace the illustrative directory layout with the actual main directories, record the verified MongoDB technology, and distinguish completed transaction work from pending final reproducibility testing. Old activity “next” pointers now link to completed later work.
- The assessment brief and working checklist stay in the ignored local guide directory. The submitted summary must be self-contained and must not require access to that directory.

## Reproducibility follow-up

After the coverage audit, a [fresh reproduction](../evidence/reproducibility-2026-10-17/README.md) passed all 52 recorded commands using disposable PostgreSQL and MongoDB environments. This completes the reproduction task for the documented workflows; historical evidence and the audit scope above remain distinct.

## Outstanding submission work

| Item | Required action / completion evidence |
| --- | --- |
| **Fresh reproducibility review — completed** | [Fresh results](../evidence/reproducibility-2026-10-17/README.md) cover the implemented workflows and documentation checks. No implementation correction was needed. Future changes may require targeted revalidation. |
| **2–3 page LMS summary** | Produce and check a paginated artifact covering the scenario/users/data/operations, all five activities, repository link, selected evidence, reflection, and references/declaration as required by sections 4 and 6. A [three-page PDF summary](../submission/lms-summary.pdf) and [editable source](../submission/lms-summary.html) are now supplied. Technical content and pagination were checked; a reflection based on Emmanuel’s recorded direction is now included, with tool-run checks distinguished from his review. The summary was subsequently finalised at Emmanuel’s request with a reflection and scoped declaration; the historical working-record review remains separate. |
| **Individual reflection and understanding** | Obtain Emmanuel's actual design decisions, challenges, corrections, lessons, and verification experience. Tool-run checks cannot substitute for personal reflection or proof of understanding. |
| **References and AI declaration** | Review the final declaration against section 11: tool, purpose, and how Emmanuel reviewed/corrected/tested/verified outputs. The working AI-use record is not a completed final declaration; Portfolio 5 assistance is absent from that record under the current instruction. Leave the file unchanged now and resolve final declaration coverage with Emmanuel before submission. Review external documentation, libraries/tools, and synthetic dataset attribution. |
| **Private repository and assessor access** | Verify privacy, the submitted URL, progressive history, and actual assessor access before submission. A successful push alone is insufficient evidence of access. |
| **LMS submission** | Upload the reviewed summary and required evidence, then retain the submission confirmation. No upload has been performed. |
| **Possible technical verification** | Emmanuel should be able to explain the design, plans, transaction schedules, NoSQL choices, and distributed trade-offs; record preparation without inventing a viva or review. |

No additional activity implementation gap was identified by this coverage audit. The fresh reproduction passed, but the final summary, reflection, declaration review, access verification, and submission checklist remain open.
