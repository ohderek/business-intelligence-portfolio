<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0,0a1628,50,152a4a,100,0a1628&height=200&section=header&text=Business+Intelligence&fontSize=50&fontColor=dcc99a&fontAlignY=52&animation=fadeIn&desc=Looker+LookML+%7C+Tableau+%7C+Derek+OHalloran&descSize=18&descAlignY=72&descColor=7da8cc" />

<br/>

<img src="https://readme-typing-svg.demolab.com?font=IBM+Plex+Mono&weight=500&size=20&duration=3500&pause=800&color=0a1628&center=true&vCenter=true&width=700&height=50&lines=Data+tells+a+story.+Dashboards+make+it+undeniable.;LookML%3A+business+logic+in+version+control.;DORA+metrics+that+drive+engineering+decisions.;Tableau%3A+from+raw+numbers+to+clear+narrative." alt="Typing SVG" />

</div>

---

> **Good BI isn't about charts. It's about removing the space between a question and an answer.**
>
> This portfolio covers two layers of that: **Looker / LookML** for governed, self-serve analytics — and **Tableau** for data storytelling that makes insights land with stakeholders.

---

## LookML — GitHub Insights Model

The LookML project models GitHub PR and deployment data from the [GitHub Insights](https://github.com/ohderek/data-engineering-portfolio/tree/main/github-insights) pipeline into a governed Looker semantic layer.

Two explores: `fact_pull_requests` (PR velocity, code churn, review quality) and `dora_lead_time` (DORA metrics, SHA match quality gates).

### Model Architecture

```mermaid
erDiagram
    FACT_PULL_REQUESTS ||--o{ FACT_PR_REVIEW_COMMENTS : "pr_id"
    FACT_PULL_REQUESTS ||--o{ FACT_PR_REVIEWS : "pr_id"
    FACT_PULL_REQUESTS ||--|| FACT_PR_TIMES : "pr_id"
    FACT_PULL_REQUESTS ||--o{ FACT_COMMIT_FILES : "pr_id"
    FACT_PULL_REQUESTS ||--o{ BRIDGE_PR_LABELS : "pr_id"
    FACT_PULL_REQUESTS ||--o{ LEAD_TIME_TO_DEPLOY : "pr_id"
    FACT_PULL_REQUESTS }o--|| DIM_USER : "user_ldap"
    FACT_PULL_REQUESTS }o--|| DIM_REPOSITORY : "repo_id"
    BRIDGE_PR_LABELS }o--|| DIM_LABELS : "label_id"
    DIM_REPOSITORY ||--|| FACT_REPO_STATS : "repo_id"

    FACT_PULL_REQUESTS {
        number PK_pk
        number pr_id
        string org
        string repo_full_name
        number repo_id
        string user_ldap
        string user_login
        string author_type
        string state
        boolean merged
        boolean draft
        string base_ref
        string head_ref
        timestamp created_at
        timestamp merged_at
        timestamp closed_at
        string merge_commit_sha
    }

    FACT_PR_TIMES {
        number PK_pk
        number FK_pr_id
        timestamp branch_created_at
        timestamp ready_for_review_at
        timestamp first_reviewed_at
        timestamp first_approved_at
        timestamp last_approved_at
        timestamp merged_at
        number time_to_review_epoch
        number time_to_approve_epoch
        number time_to_merge_epoch
        number reviewers_requested_count
    }

    FACT_PR_REVIEWS {
        number PK_pk
        number FK_pr_id
        string reviewer_ldap
        string reviewer_login
        string pr_author_ldap
        string state
        boolean self_review
        timestamp submitted_at_ts
    }

    FACT_PR_REVIEW_COMMENTS {
        number PK_pk
        number FK_pr_id
        string commenter_ldap
        string commenter_login
        string comment_type
        timestamp commented_at
        boolean is_bot
        boolean self_review
        string source_object_id
    }

    FACT_COMMIT_FILES {
        string PK_pk
        string FK_pull_request_id
        string commit_sha
        string committer_ldap
        string folder
        string sub_folder
        string filename
        string full_filepath
        string language
        string service
        number additions
        number deletions
        boolean is_lock_file
        boolean is_pr_merge_commit
        boolean is_noisy_merge_commit
    }

    LEAD_TIME_TO_DEPLOY {
        string PK_pk
        number FK_pull_request_id
        string service
        timestamp first_commit_date
        timestamp merged_at
        timestamp first_staging_deploy
        timestamp first_prod_deploy_time
        string prod_match_scenario
        number lead_time_to_prod_hours
        number lead_time_to_prod_days
        number time_on_staging_hours
        number merge_to_prod_hours
    }

    BRIDGE_PR_LABELS {
        string PK_pk
        string FK_pull_request_id
        number FK_label_id
    }

    DIM_LABELS {
        number PK_id
        string name
        string description
        string color
    }

    DIM_USER {
        string FK_ldap
        string full_name
        string email
        string org_l1_name
        string org_l2_name
        string org_l3_name
        string function_l2_name
        string core_lead
        string core_plus_1
        string job_family
        string brand_name
        boolean is_current
        date effective_start_date
        date effective_end_date
    }

    DIM_REPOSITORY {
        number PK_pk
        string name
        string full_name
        boolean is_archived
        boolean is_private
        string default_branch
        string mpoc
        boolean pci
        boolean sox
        boolean general_rules_required
    }

    FACT_REPO_STATS {
        number PK_id
        number stargazers_count
        number watchers_count
        number maintainers_count
    }
```

### DORA Lead Time Distribution

```mermaid
xychart-beta
    title "DORA Lead Time — Deployment Distribution (%)"
    x-axis ["Elite  < 1h", "High  < 24h", "Medium  < 1wk", "Low  > 1wk"]
    y-axis "% of Deployments" 0 --> 55
    bar [42, 31, 18, 9]
```

**42% of deployments in the Elite tier** (<1 hour lead time). The `pct_sha_matched` quality KPI is surfaced directly in the BI layer — if it drops below 80%, the deployment tooling needs attention before the metric can be trusted.

### Key Design Decisions

| Decision | Why |
|---|---|
| `sql_always_where: is_bot = FALSE` on explore | Bot commits excluded by default — analysts can't accidentally inflate PR counts |
| `is_ui_pr_diff_row` flag in `fact_commit_files` | Matches exactly what GitHub shows in the PR diff UI — merge commits only, minus noisy merges and lock files |
| `sql_distinct_key` on churn measures | Prevents double-counting when commit files, reviews, and comments are all joined in the same query |
| Commit counts via `bridge_pr_commits_current` | Isolates commit COUNT DISTINCT from the commit files join, keeping measures stable regardless of which other tables are joined |
| `dora_bucket_sort` hidden dimension | Forces Elite → High → Medium → Low sort order (LookML has no native "sort by field" for strings) |
| `from:` aliases for reviewer/commenter dims | Reuses `dim_users` twice with different join aliases — avoids schema duplication while preserving team context for both reviewer and commenter breakdowns |
| SCD Type 2 `dim_users` | Point-in-time reports use a date-range join; current dashboards use `is_current = TRUE` |
| Dashboard-as-code | DORA dashboard versioned in LookML — deployed identically across dev / staging / prod |

### File Structure

```
lookml/
├── github_insights.model.lkml               Two explores + all join definitions
├── views/
│   ├── fact_pull_requests.view.lkml         Core PR grain · cycle time · bot detection
│   ├── fact_pr_times.view.lkml              Epoch-based lifecycle timing · first review/approval
│   ├── fact_commit_files.view.lkml          File churn · UI-accurate line counts · PR size
│   ├── fact_github_pr_reviews.view.lkml     Review events · approvals · changes requested
│   ├── fact_github_pr_review_comments.view  Inline + issue comments · excl. description
│   ├── fact_repo_stats.view.lkml            Stars · watchers · maintainers per repo
│   ├── lead_time_to_deploy.view.lkml        DORA lead time · SHA match · staging timing
│   ├── dim_user.view.lkml                   SCD2 engineer · full org hierarchy L1–L3
│   ├── dim_repository.view.lkml             Repo metadata · PCI/SOX compliance flags
│   ├── dim_labels.view.lkml                 GitHub label dimension
│   ├── bridge_pr_labels.view.lkml           M:M bridge · PR ↔ labels
│   └── bridge_pr_commits_current.view.lkml  M:M bridge · PR ↔ commits (fan-out guard)
└── dashboards/
    └── dora_metrics.dashboard.lkml          DORA KPIs · trend · bucket dist · by service/team
```

---

## Tableau — Data Storytelling

<div align="center">

**[View full portfolio story →](https://public.tableau.com/app/profile/derek.o.halloran/viz/Portfolio_54/Story1)**&nbsp;&nbsp;&nbsp;**[Browse all vizzes →](https://public.tableau.com/app/profile/derek.o.halloran/vizzes)**

</div>

<br/>

| Viz | Theme | Signature technique |
|---|---|---|
| **WorldWealthSankey** ⭐ | Global wealth distribution | Sankey flow with custom weighting · annotated insight: 12 nations hold more than all of Africa |
| **Food Delivery KPIs** | Operational performance | Heat map calendar · KPI scorecards · parameter-driven date selection |
| **Messi vs Ronaldo** | Sports analytics | Mirrored bar chart · image integration · calculated career totals |
| **GDP & Happiness** | Economics · well-being | k-means clustering · logarithmic axis · reference band annotations |
| **Bridges to Prosperity** | Humanitarian impact | Filled map + bar combo · 313 bridges · 1.14M people served · 22 nations |
| **Gender Pay Inequality** | Social data | Diverging area chart · trend annotations · time-series comparative storytelling |

---

## Tech Stack

<div align="center">

![Looker](https://img.shields.io/badge/Looker-4285F4?style=for-the-badge&logo=looker&logoColor=white)
![LookML](https://img.shields.io/badge/LookML-1a3a5c?style=for-the-badge&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

</div>

---

<div align="center">

<a href="https://www.linkedin.com/in/derek-o-halloran/">
  <img src="https://img.shields.io/badge/LINKEDIN-0a1628?style=for-the-badge&logo=linkedin&logoColor=dcc99a" />
</a>&nbsp;
<a href="mailto:ohalloran.derek@gmail.com">
  <img src="https://img.shields.io/badge/EMAIL-0a1628?style=for-the-badge&logo=gmail&logoColor=dcc99a" />
</a>&nbsp;
<a href="https://public.tableau.com/app/profile/derek.o.halloran/viz/Portfolio_54/Story1">
  <img src="https://img.shields.io/badge/TABLEAU-E97627?style=for-the-badge&logo=tableau&logoColor=white" />
</a>&nbsp;
<a href="https://github.com/ohderek/data-engineering-portfolio">
  <img src="https://img.shields.io/badge/DATA_PORTFOLIO-0a1628?style=for-the-badge&logo=github&logoColor=dcc99a" />
</a>

<br/><br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0,0a1628,50,152a4a,100,0a1628&height=100&section=footer" />

</div>
