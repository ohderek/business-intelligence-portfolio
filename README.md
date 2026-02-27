<div align="center">

<img src="https://capsule-render.vercel.app/api?type=rect&color=0d0d0d&height=180&text=Business+Intelligence&fontSize=58&fontColor=ff6b35&fontAlignY=52&animation=fadeIn&desc=Looker+%C2%B7+Tableau+%C2%B7+Mode+%C2%B7+Thoughtspot&descSize=19&descAlignY=75&descColor=c9a84c" />

<br/>

<img src="https://readme-typing-svg.demolab.com?font=IBM+Plex+Mono&weight=600&size=19&duration=3200&pause=900&color=ff6b35&center=true&vCenter=true&width=700&height=45&lines=The+dashboard+is+the+answer.+The+model+is+the+question.;LookML%3A+one+definition.+Zero+drift.;42%25+Elite+DORA+%E2%80%94+measured%2C+not+guessed.;Looker+%C2%B7+Tableau+%C2%B7+Mode+%C2%B7+Thoughtspot." alt="Typing SVG" />

</div>

<br/>

---

## ◈ The BI Stack

> Not all BI tools are created equal. Each occupies a distinct position across the **self-serve ↔ code-first** and **query ↔ visualise** axes. Knowing where to reach for which tool — and when to layer them — is the discipline.

```mermaid
quadrantChart
    title BI Tools — Interaction Model
    x-axis "Self-serve" --> "Code-first"
    y-axis "Query" --> "Visualise"
    quadrant-1 Governed Analytics
    quadrant-2 Business Self-serve
    quadrant-3 Exploration
    quadrant-4 Engineering BI
    Thoughtspot: [0.10, 0.65]
    Tableau: [0.28, 0.88]
    Mode: [0.78, 0.35]
    Looker: [0.68, 0.72]
    LookML: [0.90, 0.18]
```

**Looker** sits in governed analytics — business logic defined once in LookML, self-served across the org without analyst mediation. **Thoughtspot** achieves the same self-serve outcome through natural language search. **Mode** is the engineering analyst's tool: SQL-first, Python-ready, reproducible. **Tableau** excels where narrative and visual design matter most.

---

## ◈ LookML — GitHub Insights Model

The LookML project exposes the [GitHub Insights](https://github.com/ohderek/data-engineering-portfolio/tree/main/github-insights) pipeline as a governed Looker semantic layer — two explores, eleven joined tables, DORA lead time metrics, and code churn analysis built directly into the BI layer.

### DORA Lead Time Distribution

```mermaid
xychart-beta
    title "DORA Lead Time — Deployment Distribution (%)"
    x-axis ["Elite  < 1h", "High  < 24h", "Medium  < 1wk", "Low  > 1wk"]
    y-axis "% of Deployments" 0 --> 55
    bar [42, 31, 18, 9]
```

**42% Elite tier** — consistent with mature CI/CD and small-PR discipline. The 9% Low outliers trace to services with complex cross-repo deployment dependencies, surfaced directly by the `pct_sha_matched` quality KPI baked into the model.

### Key Design Decisions

| Decision | Rationale |
|---|---|
| `sql_always_where: is_bot = FALSE` | Bots excluded at the explore level — analysts physically cannot inflate PR counts |
| `is_ui_pr_diff_row` flag | Matches GitHub's PR diff UI exactly — merge commits only, lock files stripped |
| `sql_distinct_key` on churn sums | Prevents fan-out when reviews and commit files are simultaneously joined |
| Commit counts via bridge table | Stable COUNT DISTINCT regardless of which other one_to_many tables are in scope |
| `dora_bucket_sort` hidden dimension | Forces Elite → High → Medium → Low ordering — LookML has no native sort-by-field |

---

## ◈ Tableau — Data Storytelling

<div align="center">

**[Full portfolio story →](https://public.tableau.com/app/profile/derek.o.halloran/viz/Portfolio_54/Story1)**&nbsp;&nbsp;&nbsp;**[All vizzes →](https://public.tableau.com/app/profile/derek.o.halloran/vizzes)**

</div>

### Visualisation Mix

```mermaid
pie title Tableau Portfolio — Visualisation Types
    "Comparative Analysis" : 30
    "KPI & Operations" : 25
    "Geospatial" : 20
    "Statistical Clustering" : 15
    "Flow & Sankey" : 10
```

Comparative and geospatial pieces dominate — both require deliberate design choices that summary tables obscure. The 10% Sankey slice belies its impact: **WorldWealthSankey** is the most-viewed piece in the portfolio.

### Featured Vizzes

| Viz | Category | What makes it land |
|---|---|---|
| **WorldWealthSankey** ⭐ | Flow & Sankey | Custom flow weighting · single annotated insight: 12 nations hold more than all of Africa |
| **Food Delivery KPIs** | KPI & Operations | Heat map calendar + scorecards — operations managers get the full picture in one view |
| **Messi vs Ronaldo** | Comparative | Mirrored bar chart — visual symmetry makes the comparison feel definitive |
| **GDP & Happiness** | Statistical | k-means clustering reveals three distinct wealth regimes with diminishing happiness returns |
| **Bridges to Prosperity** | Geospatial | Map + KPI tiles — 1.14M people served made tangible, not just counted |
| **Gender Pay Inequality** | Comparative | Diverging area chart — the gap becomes visceral, not statistical |

---

## ◈ Tech Stack

<div align="center">

![Looker](https://img.shields.io/badge/Looker-4285F4?style=for-the-badge&logo=looker&logoColor=white)
![LookML](https://img.shields.io/badge/LookML-0d0d0d?style=for-the-badge&logoColor=ff6b35)
![Tableau](https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white)
![Mode](https://img.shields.io/badge/Mode-1A1A1A?style=for-the-badge&logoColor=white)
![Thoughtspot](https://img.shields.io/badge/Thoughtspot-0068D9?style=for-the-badge&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

</div>

---

<div align="center">

<a href="https://www.linkedin.com/in/derek-o-halloran/">
  <img src="https://img.shields.io/badge/LINKEDIN-0d0d0d?style=for-the-badge&logo=linkedin&logoColor=ff6b35" />
</a>&nbsp;
<a href="mailto:ohalloran.derek@gmail.com">
  <img src="https://img.shields.io/badge/EMAIL-0d0d0d?style=for-the-badge&logo=gmail&logoColor=ff6b35" />
</a>&nbsp;
<a href="https://public.tableau.com/app/profile/derek.o.halloran/viz/Portfolio_54/Story1">
  <img src="https://img.shields.io/badge/TABLEAU-E97627?style=for-the-badge&logo=tableau&logoColor=white" />
</a>&nbsp;
<a href="https://github.com/ohderek/data-engineering-portfolio">
  <img src="https://img.shields.io/badge/DATA_PORTFOLIO-0d0d0d?style=for-the-badge&logo=github&logoColor=ff6b35" />
</a>

<br/><br/>

<img src="https://capsule-render.vercel.app/api?type=waving&color=0,0d0d0d,100,1a1a2e&height=100&section=footer" />

</div>
