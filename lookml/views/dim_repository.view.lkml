# dim_repository.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# Repository dimension. One row per GitHub repository.
# Includes compliance metadata (PCI, SOX, MPOC) from the internal service registry.
# ─────────────────────────────────────────────────────────────────────────────

view: dim_repository {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.DIM_REPOSITORY ;;


  dimension: pk {
    primary_key: yes
    hidden:      yes
    type:        number
    sql:         ${TABLE}.PK ;;
  }

  dimension: name {
    type:        string
    sql:         ${TABLE}.NAME ;;
    label:       "Repository"
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

  dimension: description {
    type:        string
    sql:         ${TABLE}.DESCRIPTION ;;
    label:       "Description"
  }

  dimension: default_branch {
    type:        string
    sql:         ${TABLE}.DEFAULT_BRANCH ;;
    label:       "Default Branch"
    description: "e.g. main, master"
    group_label: "Metadata"
  }

  dimension: is_archived {
    type:        yesno
    sql:         ${TABLE}.IS_ARCHIVED ;;
    label:       "Is Archived"
    group_label: "Metadata"
  }

  dimension: is_private {
    type:        yesno
    sql:         ${TABLE}.IS_PRIVATE ;;
    label:       "Is Private"
    group_label: "Metadata"
  }


  # ── Compliance flags (from service registry) ──────────────────────────────────

  dimension: mpoc {
    type:        string
    sql:         ${TABLE}.MPOC ;;
    label:       "MPOC"
    description: "Main Point of Contact — team or engineer responsible for the repository."
    group_label: "Compliance"
  }

  dimension: pci {
    type:        yesno
    sql:         ${TABLE}.PCI ;;
    label:       "Is PCI"
    description: "TRUE when the repository is in scope for PCI DSS compliance."
    group_label: "Compliance"
  }

  dimension: sox {
    type:        yesno
    sql:         ${TABLE}.SOX ;;
    label:       "Is SOX"
    description: "TRUE when the repository is in scope for SOX compliance."
    group_label: "Compliance"
  }

  dimension: general_rules_required {
    type:        yesno
    sql:         ${TABLE}.GENERAL_RULES_REQUIRED ;;
    label:       "General Rules Required"
    group_label: "Compliance"
  }

  dimension: maintainer_allowed {
    type:        yesno
    sql:         ${TABLE}.MAINTAINER_ALLOWED ;;
    label:       "Maintainer Access Allowed"
    group_label: "Compliance"
  }


  # ── Measures ──────────────────────────────────────────────────────────────────

  measure: repository_count {
    type:        count_distinct
    sql:         ${pk} ;;
    label:       "Repository Count"
  }

  measure: pci_repo_count {
    type:        count_distinct
    sql:         CASE WHEN ${pci} THEN ${pk} END ;;
    label:       "PCI Repos"
    group_label: "Compliance"
  }

  measure: sox_repo_count {
    type:        count_distinct
    sql:         CASE WHEN ${sox} THEN ${pk} END ;;
    label:       "SOX Repos"
    group_label: "Compliance"
  }
}
