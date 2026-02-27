# fact_github_pr_reviews.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# PR review events. One row per review submission.
# Grain: pr_id × reviewer × review_state × submitted_at.
#
# Aliased as `pr_reviews` in the fact_pull_requests explore via `from:`.
# ─────────────────────────────────────────────────────────────────────────────

view: fact_github_pr_reviews {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.FACT_GITHUB_PR_REVIEWS ;;


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

  dimension: org {
    type:        string
    sql:         ${TABLE}.ORG ;;
    label:       "Organisation"
  }

  dimension: reviewer_ldap {
    type:        string
    sql:         ${TABLE}.REVIEWER_LDAP ;;
    label:       "Reviewer LDAP"
  }

  dimension: reviewer_login {
    type:        string
    sql:         ${TABLE}.REVIEWER_LOGIN ;;
    label:       "Reviewer GitHub Login"
  }

  dimension: pr_author_ldap {
    type:        string
    sql:         ${TABLE}.PR_AUTHOR_LDAP ;;
    label:       "PR Author LDAP"
  }

  dimension: state {
    type:        string
    sql:         ${TABLE}.STATE ;;
    label:       "Review State"
    description: "approved | changes_requested | commented | dismissed"
  }

  dimension: self_review {
    type:        yesno
    sql:         ${TABLE}.SELF_REVIEW ;;
    label:       "Is Self Review"
    description: "TRUE when the PR author reviewed their own PR."
  }

  dimension: commit_id {
    type:        string
    sql:         ${TABLE}.COMMIT_ID ;;
    hidden:      yes
    group_label: "Metadata"
  }

  dimension: submitted_at {
    type:        number
    sql:         ${TABLE}.SUBMITTED_AT ;;
    label:       "Submitted At (epoch)"
    hidden:      yes
  }

  dimension: body {
    type:        string
    sql:         ${TABLE}.BODY ;;
    label:       "Review Body"
    hidden:      yes
  }


  # ── Measures ──────────────────────────────────────────────────────────────────

  measure: review_count {
    type:        count
    label:       "Reviews"
    drill_fields: [pk, reviewer_ldap, state]
  }

  measure: approvals {
    type:        count_distinct
    sql:         CASE WHEN ${state} = 'approved' THEN ${pk} END ;;
    label:       "Approvals"
    description: "Distinct review events with state = approved."
    group_label: "Review Quality"
  }

  measure: changes_requested {
    type:        count_distinct
    sql:         CASE WHEN ${state} = 'changes_requested' THEN ${pk} END ;;
    label:       "Changes Requested"
    group_label: "Review Quality"
  }

  measure: review_comments {
    type:        count_distinct
    sql:         CASE WHEN ${state} = 'commented' THEN ${pk} END ;;
    label:       "Review Comments"
    group_label: "Review Quality"
  }

  measure: unique_reviewers {
    type:        count_distinct
    sql:         ${reviewer_ldap} ;;
    label:       "Unique Reviewers"
    description: "Distinct engineers who submitted at least one review."
    group_label: "Review Quality"
  }
}
