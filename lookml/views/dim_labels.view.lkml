# dim_labels.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# GitHub label dimension. Joined via bridge_pr_labels (M:M bridge table).
# One row per unique label across all repositories.
# ─────────────────────────────────────────────────────────────────────────────

view: dim_labels {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.DIM_LABELS ;;

  dimension: id {
    primary_key: yes
    type:        number
    sql:         ${TABLE}.ID ;;
    hidden:      yes
  }

  dimension: name {
    type:        string
    sql:         ${TABLE}.NAME ;;
    label:       "Label Name"
  }

  dimension: description {
    type:        string
    sql:         ${TABLE}.DESCRIPTION ;;
    label:       "Label Description"
  }

  dimension: color {
    type:        string
    sql:         ${TABLE}.COLOR ;;
    label:       "Label Colour (hex)"
    group_label: "Metadata"
  }

  measure: label_count {
    type:        count_distinct
    sql:         ${id} ;;
    label:       "Distinct Labels"
  }
}
