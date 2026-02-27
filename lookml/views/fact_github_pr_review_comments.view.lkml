# fact_github_pr_review_comments.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# PR inline comments and PR description. One row per comment.
# Aliased as `pr_comments` in the fact_pull_requests explore via `from:`.
#
# Key design decisions:
#   - comment_count_excluding_description uses source_object_id (hidden) to
#     exclude the PR description row, which is stored here for convenience but
#     is not a "comment" in the analyst sense.
#   - is_bot carried through from source to allow filtering comment metrics
#     to human commenters only.
# ─────────────────────────────────────────────────────────────────────────────

view: fact_github_pr_review_comments {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.FACT_GITHUB_PR_REVIEW_COMMENTS ;;


  dimension: pk {
    primary_key: yes
    hidden:      yes
    type:        number
    sql:         ${TABLE}.PK ;;
  }

  dimension: pr_id {
    type:        number
    hidden:      yes
    sql:         ${TABLE}.PR_ID ;;
  }

  dimension: comment_type {
    type:        string
    sql:         ${TABLE}.COMMENT_TYPE ;;
    label:       "Comment Type"
    description: "inline_review | pr_description | issue_comment"
  }

  dimension: commenter_ldap {
    type:        string
    sql:         ${TABLE}.COMMENTER_LDAP ;;
    label:       "Commenter LDAP"
  }

  dimension: commenter_login {
    type:        string
    sql:         ${TABLE}.COMMENTER_LOGIN ;;
    label:       "Commenter GitHub Login"
  }

  dimension: author_ldap {
    type:        string
    sql:         ${TABLE}.AUTHOR_LDAP ;;
    label:       "PR Author LDAP"
    description: "LDAP of the PR author (for self-review detection)."
  }

  dimension: self_review {
    type:        yesno
    sql:         ${TABLE}.SELF_REVIEW ;;
    label:       "Is Self Comment"
  }

  dimension: is_bot {
    type:        yesno
    sql:         ${TABLE}.IS_BOT ;;
    label:       "Is Bot Commenter"
  }

  dimension_group: commented_at {
    type:       time
    datatype:   timestamp
    timeframes: [time, hour_of_day, day_of_week, date, week, month, quarter, year]
    sql:        ${TABLE}.COMMENTED_AT ;;
    label:      "Commented"
  }

  dimension: body {
    type:        string
    sql:         ${TABLE}.BODY ;;
    label:       "Comment Body"
    hidden:      yes
  }

  # Used only for the excluding_description measure below — hidden from UI
  dimension: source_object_id {
    type:        string
    hidden:      yes
    sql:         ${TABLE}.SOURCE_OBJECT_ID ;;
  }


  # ── Measures ──────────────────────────────────────────────────────────────────

  measure: comment_count {
    type:        count_distinct
    sql:         ${pk} ;;
    label:       "Comment Count (all)"
    drill_fields: [body]
  }

  # The recommended metric for comment volume — excludes the PR description row
  # which inflates counts by 1 per PR when included.
  measure: comment_count_excl_description {
    type:        count_distinct
    sql:         ${source_object_id} ;;
    filters:     [comment_type: "-pr_description"]
    label:       "Comment Count (excl. description)"
    description: "Inline review comments and issue comments, excluding the PR description body."
  }

  measure: pr_count {
    type:        count_distinct
    sql:         ${pr_id} ;;
    label:       "PRs with Comments"
    drill_fields: [body]
  }
}
