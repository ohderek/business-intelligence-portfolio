# fact_pull_requests.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# Central PR grain table. One row per pull request.
#
# Key design decisions:
#   - is_bot derived from login patterns — bots excluded by default in explore
#   - repo_name extracted from repo_full_name with a direct GitHub deep-link
#   - title links directly to the PR on GitHub
#   - commit count measures route through bridge_pr_commits_current to avoid
#     fan-out inflation when commit files and reviews are also joined
#   - set: detail wires drill-to-detail for all count measures
# ─────────────────────────────────────────────────────────────────────────────

view: fact_pull_requests {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.FACT_PULL_REQUESTS ;;


  # ── Primary key ──────────────────────────────────────────────────────────────

  dimension: pk {
    primary_key: yes
    hidden:      yes
    type:        number
    sql:         ${TABLE}.PK ;;
  }


  # ── Identifiers ──────────────────────────────────────────────────────────────

  dimension: pr_id {
    type:        number
    sql:         ${TABLE}.PR_ID ;;
    label:       "PR ID"
    description: "GitHub internal PR ID. Join key to commit files, reviews, and lead time."
  }

  dimension: number {
    type:        number
    sql:         ${TABLE}.NUMBER ;;
    label:       "PR Number"
    description: "Human-readable PR number within the repository (shown in GitHub URL)."
  }

  dimension: url {
    type:        string
    sql:         ${TABLE}.URL ;;
    hidden:      yes
  }

  dimension: title {
    type:        string
    sql:         ${TABLE}.TITLE ;;
    label:       "PR Title"
    link: {
      label:    "Open PR on GitHub"
      url:      "{{ fact_pull_requests.url._value }}"
      icon_url: "https://github.com/favicon.ico"
    }
  }


  # ── Org / repo context ────────────────────────────────────────────────────────

  dimension: org {
    type:        string
    sql:         ${TABLE}.ORG ;;
    label:       "Organisation"
    description: "GitHub organisation the repository belongs to."
  }

  dimension: repo_id {
    type:        number
    sql:         ${TABLE}.REPO_ID ;;
    hidden:      yes
  }

  dimension: repo_full_name {
    type:        string
    sql:         ${TABLE}.REPO_FULL_NAME ;;
    label:       "Repository (full)"
    description: "org/repo format."
  }

  dimension: repo_name {
    type:        string
    sql:         REGEXP_REPLACE(${TABLE}.REPO_FULL_NAME, '(.+)/(.+)', '\\\\2') ;;
    label:       "Repository"
    description: "Short repository name (without org prefix)."
    drill_fields: [dim_users.ldap]
    link: {
      label:    "View on GitHub"
      url:      "https://github.com/{{ fact_pull_requests.org._value }}/{{ value }}"
      icon_url: "https://github.com/favicon.ico"
    }
  }


  # ── Branch context ────────────────────────────────────────────────────────────

  dimension: target_branch {
    type:        string
    sql:         ${TABLE}.BASE_REF ;;
    label:       "Target Branch"
    description: "Branch the PR merges into (e.g. main, master)."
  }

  dimension: source_branch {
    type:        string
    sql:         ${TABLE}.HEAD_REF ;;
    label:       "Source Branch"
    description: "Feature branch the PR was raised from."
  }

  dimension: base_sha {
    type:        string
    sql:         ${TABLE}.BASE_SHA ;;
    hidden:      yes
    group_label: "SHAs"
  }

  dimension: head_sha {
    type:        string
    sql:         ${TABLE}.HEAD_SHA ;;
    hidden:      yes
    group_label: "SHAs"
  }

  dimension: merge_commit_sha {
    type:        string
    sql:         ${TABLE}.MERGE_COMMIT_SHA ;;
    group_label: "SHAs"
    label:       "Merge Commit SHA"
  }


  # ── Author ────────────────────────────────────────────────────────────────────

  dimension: user_ldap {
    type:        string
    sql:         ${TABLE}.USER_LDAP ;;
    label:       "Author LDAP"
    description: "Internal LDAP identifier. Join key to dim_users."
  }

  dimension: user_login {
    type:        string
    sql:         ${TABLE}.USER_LOGIN ;;
    label:       "Author GitHub Login"
  }

  # Derived: classify bots by login patterns.
  # The explore's sql_always_where filters these out by default.
  dimension: is_bot {
    type:        yesno
    label:       "Is Bot"
    description: "TRUE when the author login matches common bot patterns ([bot], -bot, svc-)."
    sql: CASE
           WHEN ${user_login} ILIKE '%[bot]%'
             OR ${user_login} ILIKE '%-bot'
             OR ${user_login} ILIKE 'svc-%'
           THEN TRUE
           ELSE FALSE
         END ;;
  }


  # ── PR state ──────────────────────────────────────────────────────────────────

  dimension: state {
    type:        string
    sql:         ${TABLE}.STATE ;;
    label:       "State"
    description: "open | closed"
  }

  dimension: is_merged {
    type:        yesno
    sql:         ${TABLE}.MERGED ;;
    label:       "Is Merged"
  }

  dimension: is_draft {
    type:        yesno
    sql:         ${TABLE}.DRAFT ;;
    label:       "Is Draft"
  }

  dimension: auto_merge {
    type:        string
    sql:         ${TABLE}.AUTO_MERGE ;;
    label:       "Auto Merge"
    description: "Auto-merge configuration when enabled on the PR."
  }


  # ── Timestamps ────────────────────────────────────────────────────────────────

  dimension_group: created_at {
    type:       time
    timeframes: [time, hour_of_day, day_of_week, date, week, month, quarter, year]
    sql:        ${TABLE}.CREATED_AT ;;
    label:      "Created"
  }

  # Convenience: YYYY-MM string for lightweight month-level grouping
  dimension: created_month {
    type:       string
    sql:        TO_CHAR(TO_TIMESTAMP(${TABLE}.CREATED_AT), 'YYYY-MM') ;;
    label:      "Created Month (YYYY-MM)"
  }

  dimension_group: updated_at {
    type:       time
    timeframes: [time, hour_of_day, day_of_week, date, week, month, quarter, year]
    sql:        ${TABLE}.UPDATED_AT ;;
    label:      "Updated"
  }

  dimension_group: updated_at_pt {
    type:       time
    timeframes: [time, date, week, month]
    sql:        CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', ${TABLE}.UPDATED_AT::TIMESTAMP_NTZ) ;;
    label:      "Updated (PT)"
    group_label: "Updated (Timezones)"
  }

  dimension_group: updated_at_est {
    type:       time
    timeframes: [time, date, week, month]
    sql:        CONVERT_TIMEZONE('UTC', 'America/New_York', ${TABLE}.UPDATED_AT::TIMESTAMP_NTZ) ;;
    label:      "Updated (EST)"
    group_label: "Updated (Timezones)"
  }

  dimension_group: merged_at {
    type:       time
    timeframes: [time, hour_of_day, day_of_week, date, week, month, quarter, year]
    sql:        ${TABLE}.MERGED_AT ;;
    label:      "Merged"
  }

  dimension_group: closed_at {
    type:       time
    timeframes: [time, date, week, month, quarter, year]
    sql:        ${TABLE}.CLOSED_AT ;;
    label:      "Closed"
  }

  dimension_group: data_synced_at {
    type:       time
    timeframes: [time, date]
    sql:        ${TABLE}.DATA_SYNCED_AT ;;
    label:      "Data Synced"
    group_label: "Metadata"
  }


  # ── Measures — PR counts ──────────────────────────────────────────────────────

  measure: total_prs {
    type:        count_distinct
    sql:         ${pk} ;;
    label:       "Total PRs"
    description: "Count of distinct pull requests."
    group_label: "Stats"
    drill_fields: [detail*]
  }

  measure: merged_prs {
    type:        count_distinct
    sql:         CASE WHEN ${is_merged} THEN ${pk} END ;;
    label:       "Merged PRs"
    group_label: "Stats"
    drill_fields: [detail*]
  }

  measure: open_prs {
    type:        count_distinct
    sql:         CASE WHEN ${state} = 'open' THEN ${pk} END ;;
    label:       "Open PRs"
    group_label: "Stats"
  }

  measure: merge_rate {
    type:        number
    label:       "Merge Rate"
    description: "% of PRs that were merged (vs closed without merging)."
    sql:         ${merged_prs} * 1.0 / NULLIF(${total_prs}, 0) ;;
    value_format: "0.0%"
    group_label: "Stats"
  }


  # ── Measures — commit counts (via bridge to avoid fan-out) ───────────────────

  measure: commits {
    type:        count_distinct
    sql:         ${bridge_pr_commits_current.commit_sha} ;;
    label:       "Commits"
    description: "Distinct commit SHAs across all joined PRs. Routes through bridge to prevent double-counting when commit files or reviews are also joined."
    group_label: "Stats"
    value_format_name: decimal_0
  }

  measure: prs_with_commits {
    type:        count_distinct
    sql:         ${pr_id} ;;
    filters:     [bridge_pr_commits_current.commit_sha: "-NULL"]
    label:       "PRs With Commits"
    group_label: "Stats"
    value_format_name: decimal_0
  }


  # ── Measures — cycle time ─────────────────────────────────────────────────────

  measure: avg_time_to_merge_hours {
    type:        average
    label:       "Avg Time to Merge (hours)"
    sql:         DATEDIFF('hour', ${TABLE}.CREATED_AT, ${TABLE}.MERGED_AT) ;;
    filters:     [is_merged: "Yes"]
    value_format: "0.0"
    group_label: "Cycle Time"
  }

  measure: median_time_to_merge_hours {
    type:        median
    label:       "Median Time to Merge (hours)"
    sql:         DATEDIFF('hour', ${TABLE}.CREATED_AT, ${TABLE}.MERGED_AT) ;;
    filters:     [is_merged: "Yes"]
    value_format: "0.0"
    group_label: "Cycle Time"
  }

  measure: p75_time_to_merge_hours {
    type:        percentile
    percentile:  75
    label:       "P75 Time to Merge (hours)"
    sql:         DATEDIFF('hour', ${TABLE}.CREATED_AT, ${TABLE}.MERGED_AT) ;;
    filters:     [is_merged: "Yes"]
    value_format: "0.0"
    group_label: "Cycle Time"
  }


  # ── Drill fields ──────────────────────────────────────────────────────────────

  set: detail {
    fields: [
      pr_id,
      number,
      title,
      url,
      user_ldap,
      repo_full_name,
      state,
      created_at_date
    ]
  }
}
