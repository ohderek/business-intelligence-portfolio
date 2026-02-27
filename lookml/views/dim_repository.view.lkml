# dim_repository.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# Repository dimension. One row per GitHub repository.
# Joined to fact_pull_requests on repo_id (many_to_one).
#
# Exposes repository metadata: language, visibility, topics, and the owning
# team as recorded in the internal service registry.
# ─────────────────────────────────────────────────────────────────────────────

view: dim_repository {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.DIM_REPOSITORY ;;

  dimension: id {
    primary_key: yes
    hidden:      yes
    type:        number
    sql:         ${TABLE}.ID ;;
  }

  dimension: full_name {
    type:        string
    sql:         ${TABLE}.FULL_NAME ;;
    label:       "Repository (full)"
    link: {
      label:    "View on GitHub"
      url:      "https://github.com/{{ value }}"
      icon_url: "https://github.com/favicon.ico"
    }
  }

  dimension: name {
    type:        string
    sql:         ${TABLE}.NAME ;;
    label:       "Repository"
  }

  dimension: org {
    type:        string
    sql:         ${TABLE}.ORG ;;
    label:       "Organisation"
  }

  dimension: primary_language {
    type:        string
    sql:         ${TABLE}.PRIMARY_LANGUAGE ;;
    label:       "Primary Language"
  }

  dimension: visibility {
    type:        string
    sql:         ${TABLE}.VISIBILITY ;;
    label:       "Visibility"
    description: "public | private | internal"
  }

  dimension: is_archived {
    type:        yesno
    sql:         ${TABLE}.IS_ARCHIVED ;;
    label:       "Is Archived"
  }

  dimension: owning_team {
    type:        string
    sql:         ${TABLE}.OWNING_TEAM ;;
    label:       "Owning Team"
    description: "Team registered as the repository owner in the service registry."
  }

  dimension: owning_service {
    type:        string
    sql:         ${TABLE}.OWNING_SERVICE ;;
    label:       "Owning Service"
  }

  dimension_group: created_at {
    type:       time
    timeframes: [date, month, year]
    sql:        ${TABLE}.CREATED_AT ;;
    label:      "Repo Created"
  }

  measure: repository_count {
    type:        count_distinct
    sql:         ${id} ;;
    label:       "Repository Count"
  }
}
