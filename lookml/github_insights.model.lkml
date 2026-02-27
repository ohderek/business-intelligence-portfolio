# github_insights.model.lkml
# ─────────────────────────────────────────────────────────────────────────────
# Looker model for the GitHub Insights subject area.
#
# Exposes two explores:
#   1. fact_pull_requests   — PR velocity, code churn, review quality, commits
#   2. dora_lead_time       — DORA lead time to deploy, deployment frequency
#
# Both explores exclude bots by default via sql_always_where.
# The SCD2 dim_users join uses is_current = TRUE for current-state reports.
# For point-in-time attribution, replace with a date-range join on effective dates.
# ─────────────────────────────────────────────────────────────────────────────

connection: "snowflake_github_insights"

include: "/views/*.view.lkml"
include: "/dashboards/*.dashboard.lkml"


# ── Explore: Pull Requests ────────────────────────────────────────────────────
# Central explore for all PR analysis. Joins commit files, reviews, comments,
# labels, timing, repository metadata, and the SCD2 user dimension.

explore: fact_pull_requests {
  label:       "GitHub Insights — Pull Requests"
  description: "PR velocity, code churn, review quality, and commit metrics. Grain: one row per PR."

  # Exclude bot authors from all velocity metrics by default.
  # Analysts who need bot data can remove this filter in the Explore UI.
  sql_always_where: ${fact_pull_requests.is_bot} = FALSE ;;


  # ── Commit-level file churn ─────────────────────────────────────────────────
  join: fact_commit_files {
    view_label:   "Commit Files"
    type:         left_outer
    sql_on:       ${fact_pull_requests.pr_id} = ${fact_commit_files.pull_request_id} ;;
    relationship: one_to_many
  }

  # ── PR review data ──────────────────────────────────────────────────────────
  join: pr_reviews {
    view_label:   "PR Reviews"
    from:         fact_github_pr_reviews
    type:         left_outer
    sql_on:       ${fact_pull_requests.pr_id} = ${pr_reviews.pr_id} ;;
    relationship: one_to_many
  }

  # ── PR review comments ──────────────────────────────────────────────────────
  join: pr_comments {
    view_label:   "PR Comments"
    from:         fact_github_pr_review_comments
    type:         left_outer
    sql_on:       ${fact_pull_requests.pr_id} = ${pr_comments.pr_id} ;;
    relationship: one_to_many
  }

  # ── PR timing metrics (first review, first approval, time to review, etc.) ──
  join: github_pr_times {
    view_label:   "PR Timing"
    type:         left_outer
    sql_on:       ${fact_pull_requests.pr_id} = ${github_pr_times.pr_id} ;;
    relationship: one_to_one
  }

  # ── Repository dimension ────────────────────────────────────────────────────
  join: dim_repository {
    view_label:   "Repository"
    type:         left_outer
    sql_on:       ${fact_pull_requests.repo_id} = ${dim_repository.id} ;;
    relationship: many_to_one
  }

  # ── PR author — SCD2 user dimension ─────────────────────────────────────────
  # is_current = TRUE for current-state team attribution.
  join: dim_users {
    view_label:   "Author"
    type:         left_outer
    sql_on:       ${fact_pull_requests.user_ldap} = ${dim_users.ldap}
                  AND ${dim_users.is_current} = TRUE ;;
    relationship: one_to_one
  }

  # ── Reviewer dimension ───────────────────────────────────────────────────────
  # Re-uses dim_users via `from:` alias so reviewer team context is available
  # without conflicting with the author join.
  join: reviewer_dim_users {
    view_label:   "Reviewer"
    from:         dim_users
    type:         left_outer
    sql_on:       ${pr_reviews.reviewer_ldap} = ${reviewer_dim_users.ldap}
                  AND ${reviewer_dim_users.is_current} = TRUE ;;
    relationship: one_to_one
  }

  # ── Commenter dimension ──────────────────────────────────────────────────────
  join: commenter_dim_users {
    view_label:   "Commenter"
    from:         dim_users
    type:         left_outer
    sql_on:       ${pr_comments.commenter_ldap} = ${commenter_dim_users.ldap}
                  AND ${commenter_dim_users.is_current} = TRUE ;;
    relationship: one_to_one
  }

  # ── Labels — bridge → dimension ─────────────────────────────────────────────
  join: bridge_pr_labels {
    view_label:   "Labels (Bridge)"
    type:         left_outer
    sql_on:       ${fact_pull_requests.pr_id} = ${bridge_pr_labels.pull_request_id} ;;
    relationship: one_to_many
  }

  join: dim_labels {
    view_label:   "Labels"
    type:         left_outer
    sql_on:       ${bridge_pr_labels.label_id} = ${dim_labels.id} ;;
    relationship: many_to_one
  }

  # ── Commit bridge (used for commit count measures) ───────────────────────────
  join: bridge_pr_commits_current {
    view_label:   "Commits (Bridge)"
    type:         left_outer
    sql_on:       ${fact_pull_requests.pr_id} = ${bridge_pr_commits_current.pull_request_id} ;;
    relationship: one_to_many
  }
}


# ── Explore: DORA Lead Time ───────────────────────────────────────────────────
# DORA lead time from first commit to production deployment, per PR × service.
# Joined to PR facts and the SCD2 user dimension for team-level reporting.

explore: dora_lead_time {
  label:       "GitHub Insights — DORA Lead Time"
  description: "Lead time from first commit to production deployment, by service and team. Grain: one row per PR × service."

  # Default to SHA-matched records only for high-confidence DORA metrics.
  # Analysts can remove this filter to include time-based fallback matches.
  sql_always_where: ${lead_time_to_deploy.prod_match_scenario} = 'sha_match' ;;

  join: fact_pull_requests {
    view_label:   "Pull Request"
    type:         left_outer
    sql_on:       ${lead_time_to_deploy.pull_request_id} = ${fact_pull_requests.pr_id} ;;
    relationship: many_to_one
  }

  join: dim_users {
    view_label:   "Author"
    type:         left_outer
    sql_on:       ${fact_pull_requests.user_ldap} = ${dim_users.ldap}
                  AND ${dim_users.is_current} = TRUE ;;
    relationship: one_to_one
  }
}
