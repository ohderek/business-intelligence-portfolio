# fact_commit_files.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# Commit-level file churn. One row per file × commit × PR.
# Joined to fact_pull_requests on pr_id (one_to_many).
#
# Key design decisions:
#   - is_ui_pr_diff_row filters to only the rows GitHub's PR diff UI counts
#     (merge commits, non-noisy, non-lock-file, valid filepath). All UI-accurate
#     metrics use this flag so totals match what engineers see in GitHub.
#   - pr_size is a PR-level derived dimension that classifies PRs by total
#     additions + deletions, pre-computed in the Snowflake table to avoid a
#     correlated subquery at query time.
#   - sql_distinct_key on sum measures prevents double-counting when the view
#     is joined alongside other one_to_many tables (reviews, comments).
# ─────────────────────────────────────────────────────────────────────────────

view: fact_commit_files {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.FACT_COMMIT_FILES ;;


  # ── Primary key ──────────────────────────────────────────────────────────────

  dimension: pk {
    primary_key: yes
    hidden:      yes
    type:        string
    sql:         ${TABLE}.PK ;;
  }


  # ── Join key ──────────────────────────────────────────────────────────────────

  dimension: pull_request_id {
    type:        string
    sql:         ${TABLE}.PULL_REQUEST_ID ;;
    hidden:      yes
    group_label: "PR"
  }


  # ── Committer ─────────────────────────────────────────────────────────────────

  dimension: committer_ldap {
    type:        string
    sql:         ${TABLE}.COMMITTER_LDAP ;;
    label:       "Committer LDAP"
  }

  dimension: committer_email {
    type:        string
    sql:         ${TABLE}.COMMITTER_EMAIL ;;
    label:       "Committer Email"
  }

  dimension_group: committed_at {
    type:       time
    timeframes: [time, hour_of_day, day_of_week, date, week, month, quarter, year]
    sql:        ${TABLE}.COMMITTER_DATE ;;
    label:      "Committed"
  }

  dimension: commit_sha {
    type:        string
    sql:         ${TABLE}.COMMIT_SHA ;;
    group_label: "Commit"
    label:       "Commit SHA"
    drill_fields: [folder, sub_folder, filename]
  }


  # ── File path ─────────────────────────────────────────────────────────────────

  dimension: folder {
    type:        string
    sql:         ${TABLE}.FOLDER ;;
    group_label: "Path"
    label:       "Folder"
  }

  dimension: sub_folder {
    type:        string
    sql:         ${TABLE}.SUB_FOLDER ;;
    group_label: "Path"
    label:       "Sub-folder"
  }

  dimension: filename {
    type:        string
    sql:         ${TABLE}.FILENAME ;;
    group_label: "Path"
    label:       "Filename"
  }

  dimension: full_filepath {
    type:        string
    sql:         ${TABLE}.FULL_FILEPATH ;;
    group_label: "Path"
    label:       "Full Filepath"
  }


  # ── File metadata ─────────────────────────────────────────────────────────────

  dimension: language {
    type:        string
    sql:         ${TABLE}.LANGUAGE ;;
    label:       "Language"
  }

  dimension: service {
    type:        string
    sql:         ${TABLE}.SERVICE ;;
    label:       "Service"
    description: "Service inferred from filepath via service registry mapping."
    drill_fields: [pull_request_id, full_filepath]
  }

  dimension: has_service {
    type:        yesno
    sql:         ${TABLE}.HAS_SERVICE ;;
    label:       "Has Service Mapping"
  }

  dimension: change_type {
    type:        string
    sql:         ${TABLE}.CHANGE_TYPE ;;
    label:       "Change Type"
    description: "added | modified | deleted | renamed"
  }


  # ── Noise / exclusion flags ───────────────────────────────────────────────────

  dimension: is_noisy_merge_commit {
    type:        yesno
    sql:         COALESCE(${TABLE}.IS_NOISY_MERGE_COMMIT, FALSE) ;;
    label:       "Is Noisy Merge Commit"
    description: "TRUE for merge commits that bring in many files not authored in this PR."
  }

  dimension: is_pr_merge_commit {
    type:        yesno
    sql:         COALESCE(${TABLE}.IS_PR_MERGE_COMMIT, FALSE) ;;
    label:       "Is PR Merge Commit"
  }

  dimension: is_lock_file {
    type:        yesno
    sql:         COALESCE(${TABLE}.IS_LOCK_FILE, FALSE) ;;
    label:       "Is Lock File"
    description: "TRUE for package-lock.json, yarn.lock, etc. Excluded from UI-accurate line counts."
  }

  # The UI-accurate row definition:
  # Matches exactly what GitHub shows in the PR diff — merge commits only,
  # minus noisy merges and lock files, with a valid filepath.
  dimension: is_ui_pr_diff_row {
    type:        yesno
    hidden:      yes
    sql: (
      COALESCE(${TABLE}.IS_PR_MERGE_COMMIT, FALSE) = TRUE
      AND COALESCE(${TABLE}.IS_NOISY_MERGE_COMMIT, FALSE) = FALSE
      AND COALESCE(${TABLE}.IS_LOCK_FILE, FALSE) = FALSE
      AND ${TABLE}.FULL_FILEPATH IS NOT NULL
    ) ;;
  }


  # ── Line change dimensions ────────────────────────────────────────────────────

  dimension: additions {
    type:             number
    sql:              ${TABLE}.ADDITIONS ;;
    label:            "Lines Added"
    value_format_name: decimal_0
    group_label:      "Churn"
  }

  dimension: deletions {
    type:             number
    sql:              ${TABLE}.DELETIONS ;;
    label:            "Lines Deleted"
    value_format_name: decimal_0
    group_label:      "Churn"
  }


  # ── PR size tier (pre-computed in Snowflake) ──────────────────────────────────
  # Classifies each PR by total diff size. Computed upstream to avoid a
  # correlated subquery per row at Looker query time.

  dimension: pr_size {
    type:        string
    sql:         ${TABLE}.PR_SIZE ;;
    label:       "PR Size"
    description: "small (<25 lines) | medium (<100 lines) | large (100+ lines)"
    order_by_field: pr_size_sort

    case: {
      when: { sql: ${pr_size} = 'small'  ;; label: "Small  (< 25 lines)"  }
      when: { sql: ${pr_size} = 'medium' ;; label: "Medium (< 100 lines)" }
      when: { sql: ${pr_size} = 'large'  ;; label: "Large  (100+ lines)"  }
      else: "Unknown"
    }
  }

  dimension: pr_size_sort {
    hidden:      yes
    type:        number
    sql: CASE ${TABLE}.PR_SIZE WHEN 'small' THEN 1 WHEN 'medium' THEN 2 WHEN 'large' THEN 3 ELSE 4 END ;;
  }


  # ── Measures ──────────────────────────────────────────────────────────────────

  measure: prs {
    type:        count_distinct
    sql:         ${pull_request_id} ;;
    label:       "PRs (with file data)"
    group_label: "Stats"
    value_format_name: decimal_0
  }

  # sql_distinct_key prevents inflation when reviews or comments are also joined.
  measure: pr_lines_added {
    type:        sum
    label:       "PR Lines Added"
    description: "UI-accurate: merge commits only, excluding noisy merges and lock files."
    sql:         CASE WHEN ${is_ui_pr_diff_row} THEN COALESCE(${additions}, 0) ELSE 0 END ;;
    sql_distinct_key: ${pk}
    value_format_name: decimal_0
    group_label: "Churn"
  }

  measure: pr_lines_removed {
    type:        sum
    label:       "PR Lines Removed"
    sql:         CASE WHEN ${is_ui_pr_diff_row} THEN COALESCE(${deletions}, 0) ELSE 0 END ;;
    sql_distinct_key: ${pk}
    value_format_name: decimal_0
    group_label: "Churn"
  }

  measure: pr_net_lines {
    type:        number
    label:       "PR Net Lines"
    sql:         COALESCE(${pr_lines_added}, 0) - COALESCE(${pr_lines_removed}, 0) ;;
    value_format_name: decimal_0
    group_label: "Churn"
  }

  measure: files_changed {
    type:        count_distinct
    label:       "Files Changed"
    sql:         CASE WHEN ${is_ui_pr_diff_row} THEN ${full_filepath} ELSE NULL END ;;
    value_format_name: decimal_0
    group_label: "Churn"
  }
}
