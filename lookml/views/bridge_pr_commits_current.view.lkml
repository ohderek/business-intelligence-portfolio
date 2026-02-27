# bridge_pr_commits_current.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# Bridge table linking PRs to their constituent commits (current snapshot).
# Used exclusively for commit count measures in fact_pull_requests to prevent
# fan-out inflation when commit files, reviews, and comments are all joined
# simultaneously.
#
# Routing commit counts through this bridge (rather than counting directly on
# fact_commit_files) ensures DISTINCT commit_sha counts are stable regardless
# of how many other one_to_many tables are joined in the same query.
# ─────────────────────────────────────────────────────────────────────────────

view: bridge_pr_commits_current {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.BRIDGE_PR_COMMITS_CURRENT ;;

  dimension: pk {
    primary_key: yes
    hidden:      yes
    type:        string
    sql:         ${TABLE}.PK ;;
  }

  dimension: pull_request_id {
    type:        string
    hidden:      yes
    sql:         ${TABLE}.PULL_REQUEST_ID ;;
  }

  dimension: commit_sha {
    type:        string
    hidden:      yes
    sql:         ${TABLE}.COMMIT_SHA ;;
  }

  measure: commit_count {
    type:        count_distinct
    sql:         ${commit_sha} ;;
    label:       "Commits (bridge)"
    description: "Distinct commits via bridge — safe to aggregate alongside other one_to_many joins."
  }
}
