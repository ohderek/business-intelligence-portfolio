# bridge_pr_labels.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# Bridge table resolving the many-to-many relationship between PRs and labels.
# A PR can have zero or more labels; a label can be applied to many PRs.
#
# Join pattern in the explore:
#   fact_pull_requests  →(one_to_many)→  bridge_pr_labels  →(many_to_one)→  dim_labels
# ─────────────────────────────────────────────────────────────────────────────

view: bridge_pr_labels {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.BRIDGE_PR_LABELS ;;

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

  dimension: label_id {
    type:        number
    hidden:      yes
    sql:         ${TABLE}.LABEL_ID ;;
  }

  measure: labelled_pr_count {
    type:        count_distinct
    sql:         ${pull_request_id} ;;
    label:       "PRs with Labels"
  }
}
