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
flowchart TD
    subgraph SF["❄️  Snowflake · GITHUB_INSIGHTS.REPORTING"]
        T1[(FACT_PULL_REQUESTS)]
        T2[(FACT_COMMIT_FILES)]
        T3[(FACT_GITHUB_PR_REVIEWS)]
        T4[(FACT_GITHUB_PR_REVIEW_COMMENTS)]
        T5[(GITHUB_PR_TIMES)]
        T6[(BRIDGE_PR_LABELS)]
        T7[(BRIDGE_PR_COMMITS)]
        T8[(DIM_REPOSITORY)]
        T9[(DIM_USERS SCD2)]
        T10[(DIM_LABELS)]
    end

    subgraph EXP["🔍  Explore: fact_pull_requests"]
        E1{{fact_pull_requests\ncore grain}}
        E1 -->|one_to_many| T2
        E1 -->|one_to_many| T3
        E1 -->|one_to_many| T4
        E1 -->|one_to_one| T5
        E1 -->|many_to_one| T8
        E1 -->|one_to_one| T9
        E1 -->|one_to_many| T6
        T6 -->|many_to_one| T10
        E1 -->|one_to_many| T7
    end

    subgraph DORA["🔍  Explore: dora_lead_time"]
        E2{{lead_time_to_deploy}}
        E2 -->|many_to_one| E1
        E2 -->|many_to_one| T9
    end

    T1 --- E1
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
├── github_insights.model.lkml           Two explores + all join definitions
├── views/
│   ├── fact_pull_requests.view.lkml     Core PR grain · cycle time · bot detection
│   ├── fact_commit_files.view.lkml      File churn · UI-accurate line counts · PR size
│   ├── fact_github_pr_reviews.view.lkml Review events · approvals · changes requested
│   ├── fact_github_pr_review_comments   Inline + issue comments · excl. description
│   ├── github_pr_times.view.lkml        Pre-computed lifecycle timing (time to review, etc.)
│   ├── dim_repository.view.lkml         Repo metadata · owning team · language
│   ├── dim_users.view.lkml              SCD Type 2 engineer dimension · org hierarchy
│   ├── dim_labels.view.lkml             GitHub label dimension
│   ├── bridge_pr_labels.view.lkml       M:M bridge · PR ↔ labels
│   └── bridge_pr_commits_current.view   M:M bridge · PR ↔ commits (fan-out guard)
└── dashboards/
    └── dora_metrics.dashboard.lkml      DORA KPIs · trend · bucket dist · by service/team
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
