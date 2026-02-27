# fact_pr_times.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# PR lifecycle timing table. One row per PR (one_to_one with fact_pull_requests).
#
# All durations are stored as both epoch seconds (raw, for arithmetic) and
# computed as hour-level measures for analyst-facing tiles. Epoch storage avoids
# Snowflake's DATEDIFF precision issues when timestamps are stored as strings.
#
# Key fields:
#   - BRANCH_CREATED_AT: when the source branch was created (true start of work)
#   - READY_FOR_REVIEW_AT: when draft was converted, or created_at if never draft
#   - FIRST_REVIEWED_AT / FIRST_APPROVED_AT / LAST_APPROVED_AT: review lifecycle
#   - TIME_TO_*_EPOCH: pre-computed durations in seconds — used for median/P75
#   - REVIEWERS_REQUESTED_COUNT: how many reviewers were explicitly requested
# ─────────────────────────────────────────────────────────────────────────────

view: fact_pr_times {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.FACT_PR_TIMES ;;


  # ── Primary key ──────────────────────────────────────────────────────────────

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


  # ── Lifecycle timestamps ──────────────────────────────────────────────────────

  dimension_group: created_at {
    type:       time
    timeframes: [raw, date, week, month]
    sql:        ${TABLE}.CREATED_AT ;;
    label:      "PR Created"
    group_label: "Lifecycle Timestamps"
  }

  dimension_group: branch_created_at {
    type:       time
    timeframes: [raw, date, week, month]
    sql:        ${TABLE}.BRANCH_CREATED_AT ;;
    label:      "Branch Created"
    description: "When the source branch was first created. True start of the work clock."
    group_label: "Lifecycle Timestamps"
  }

  dimension_group: ready_for_review_at {
    type:       time
    timeframes: [raw, date, week, month]
    sql:        ${TABLE}.READY_FOR_REVIEW_AT ;;
    label:      "Ready for Review"
    description: "When the PR was converted from draft, or CREATED_AT if it was never a draft."
    group_label: "Lifecycle Timestamps"
  }

  dimension_group: first_commented_at {
    type:       time
    timeframes: [raw, date]
    sql:        ${TABLE}.FIRST_COMMENTED_AT ;;
    label:      "First Comment"
    group_label: "Lifecycle Timestamps"
  }

  dimension_group: first_reviewed_at {
    type:       time
    timeframes: [raw, date]
    sql:        ${TABLE}.FIRST_REVIEWED_AT ;;
    label:      "First Review"
    group_label: "Lifecycle Timestamps"
  }

  dimension_group: first_approved_at {
    type:       time
    timeframes: [raw, date]
    sql:        ${TABLE}.FIRST_APPROVED_AT ;;
    label:      "First Approval"
    group_label: "Lifecycle Timestamps"
  }

  dimension_group: last_approved_at {
    type:       time
    timeframes: [raw, date]
    sql:        ${TABLE}.LAST_APPROVED_AT ;;
    label:      "Last Approval"
    group_label: "Lifecycle Timestamps"
  }

  dimension_group: merged_at {
    type:       time
    timeframes: [raw, date, week, month]
    sql:        ${TABLE}.MERGED_AT ;;
    label:      "Merged"
    group_label: "Lifecycle Timestamps"
  }

  dimension_group: first_response_at {
    type:       time
    timeframes: [raw, date]
    sql:        ${TABLE}.FIRST_RESPONSE_AT ;;
    label:      "First Response"
    description: "Earlier of first comment and first review event."
    group_label: "Lifecycle Timestamps"
  }


  # ── Epoch durations (seconds) — raw, used for median/percentile calculations ─

  dimension: time_as_draft_epoch {
    type:        number
    sql:         ${TABLE}.TIME_AS_DRAFT_EPOCH ;;
    label:       "Time as Draft (seconds)"
    hidden:      yes
    group_label: "Epoch Durations"
  }

  dimension: time_to_open_epoch {
    type:        number
    sql:         ${TABLE}.TIME_TO_OPEN_EPOCH ;;
    label:       "Time to Open (seconds)"
    description: "Seconds from branch creation to PR open."
    hidden:      yes
    group_label: "Epoch Durations"
  }

  dimension: time_to_review_epoch {
    type:        number
    sql:         ${TABLE}.TIME_TO_REVIEW_EPOCH ;;
    label:       "Time to First Review (seconds)"
    hidden:      yes
    group_label: "Epoch Durations"
  }

  dimension: time_to_approve_epoch {
    type:        number
    sql:         ${TABLE}.TIME_TO_APPROVE_EPOCH ;;
    label:       "Time to First Approval (seconds)"
    hidden:      yes
    group_label: "Epoch Durations"
  }

  dimension: time_to_merge_epoch {
    type:        number
    sql:         ${TABLE}.TIME_TO_MERGE_EPOCH ;;
    label:       "Time to Merge (seconds)"
    hidden:      yes
    group_label: "Epoch Durations"
  }

  dimension: time_to_first_response_epoch {
    type:        number
    sql:         ${TABLE}.TIME_TO_FIRST_RESPONSE_EPOCH ;;
    label:       "Time to First Response (seconds)"
    hidden:      yes
    group_label: "Epoch Durations"
  }


  # ── Review request metadata ───────────────────────────────────────────────────

  dimension: reviewers_requested_count {
    type:        number
    sql:         ${TABLE}.REVIEWERS_REQUESTED_COUNT ;;
    label:       "Reviewers Requested"
    description: "Number of reviewers explicitly requested on this PR."
  }


  # ── Measures — averages (hours) ───────────────────────────────────────────────
  # Epoch durations converted to hours for analyst-friendly display.

  measure: avg_time_to_review_hours {
    type:        average
    sql:         ${time_to_review_epoch} / 3600.0 ;;
    label:       "Avg Time to First Review (hours)"
    value_format: "0.0"
    group_label: "PR Timing"
  }

  measure: median_time_to_review_hours {
    type:        median
    sql:         ${time_to_review_epoch} / 3600.0 ;;
    label:       "Median Time to First Review (hours)"
    value_format: "0.0"
    group_label: "PR Timing"
  }

  measure: avg_time_to_approve_hours {
    type:        average
    sql:         ${time_to_approve_epoch} / 3600.0 ;;
    label:       "Avg Time to First Approval (hours)"
    value_format: "0.0"
    group_label: "PR Timing"
  }

  measure: median_time_to_merge_hours {
    type:        median
    sql:         ${time_to_merge_epoch} / 3600.0 ;;
    label:       "Median Time to Merge (hours)"
    value_format: "0.0"
    group_label: "PR Timing"
  }

  measure: p75_time_to_merge_hours {
    type:        percentile
    percentile:  75
    sql:         ${time_to_merge_epoch} / 3600.0 ;;
    label:       "P75 Time to Merge (hours)"
    value_format: "0.0"
    group_label: "PR Timing"
  }

  measure: avg_reviewers_requested {
    type:        average
    sql:         ${reviewers_requested_count} ;;
    label:       "Avg Reviewers Requested"
    value_format: "0.00"
    group_label: "PR Timing"
  }
}
