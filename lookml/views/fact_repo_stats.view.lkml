# fact_repo_stats.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# Repository-level aggregate statistics. One row per repository.
# Joined to dim_repository one_to_one on repo id.
# ─────────────────────────────────────────────────────────────────────────────

view: fact_repo_stats {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.FACT_REPO_STATS ;;

  dimension: id {
    primary_key: yes
    hidden:      yes
    type:        number
    sql:         ${TABLE}.ID ;;
  }

  dimension: stargazers_count {
    type:        number
    sql:         ${TABLE}.STARGAZERS_COUNT ;;
    label:       "Stars"
    group_label: "Repo Stats"
  }

  dimension: watchers_count {
    type:        number
    sql:         ${TABLE}.WATCHERS_COUNT ;;
    label:       "Watchers"
    group_label: "Repo Stats"
  }

  dimension: maintainers_count {
    type:        number
    sql:         ${TABLE}.MAINTAINERS_COUNT ;;
    label:       "Maintainers"
    group_label: "Repo Stats"
  }

  measure: total_stars {
    type:        sum
    sql:         ${stargazers_count} ;;
    label:       "Total Stars"
    group_label: "Repo Stats"
  }

  measure: avg_maintainers {
    type:        average
    sql:         ${maintainers_count} ;;
    label:       "Avg Maintainers per Repo"
    value_format: "0.0"
    group_label: "Repo Stats"
  }
}
