# github_pr_times.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# PR lifecycle timing metrics. One row per PR (one_to_one with fact_pull_requests).
#
# Pre-computed in Snowflake to avoid expensive DATEDIFF calculations at
# Looker query time across large PR datasets.
#
# Exposes:
#   - time_to_first_review_hours: time from PR open to first review event
#   - time_to_first_approval_hours: time from PR open to first approval
#   - time_open_hours: total time the PR was open (create → close/merge)
#   - review_rounds: number of distinct review submission rounds
# ─────────────────────────────────────────────────────────────────────────────

view: github_pr_times {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.GITHUB_PR_TIMES ;;

  dimension: pk {
    primary_key: yes
    hidden:      yes
    type:        string
    sql:         ${TABLE}.PK ;;
  }

  dimension: pr_id {
    type:        number
    hidden:      yes
    sql:         ${TABLE}.PR_ID ;;
  }


  # ── Lifecycle timing dimensions ───────────────────────────────────────────────

  dimension: time_to_first_review_hours {
    type:        number
    sql:         ${TABLE}.TIME_TO_FIRST_REVIEW_HOURS ;;
    label:       "Time to First Review (hours)"
    value_format: "0.0"
    group_label: "PR Timing"
  }

  dimension: time_to_first_approval_hours {
    type:        number
    sql:         ${TABLE}.TIME_TO_FIRST_APPROVAL_HOURS ;;
    label:       "Time to First Approval (hours)"
    value_format: "0.0"
    group_label: "PR Timing"
  }

  dimension: time_open_hours {
    type:        number
    sql:         ${TABLE}.TIME_OPEN_HOURS ;;
    label:       "Time Open (hours)"
    description: "Total time from PR creation to close or merge."
    value_format: "0.0"
    group_label: "PR Timing"
  }

  dimension: review_rounds {
    type:        number
    sql:         ${TABLE}.REVIEW_ROUNDS ;;
    label:       "Review Rounds"
    description: "Number of distinct review submission rounds before merge."
    group_label: "PR Timing"
  }


  # ── Measures ──────────────────────────────────────────────────────────────────

  measure: avg_time_to_first_review_hours {
    type:        average
    sql:         ${time_to_first_review_hours} ;;
    label:       "Avg Time to First Review (hours)"
    value_format: "0.0"
    group_label: "PR Timing"
  }

  measure: median_time_to_first_review_hours {
    type:        median
    sql:         ${time_to_first_review_hours} ;;
    label:       "Median Time to First Review (hours)"
    value_format: "0.0"
    group_label: "PR Timing"
  }

  measure: avg_review_rounds {
    type:        average
    sql:         ${review_rounds} ;;
    label:       "Avg Review Rounds"
    value_format: "0.00"
    group_label: "PR Timing"
  }
}
