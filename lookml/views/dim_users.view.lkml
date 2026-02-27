# dim_users.view.lkml
# ─────────────────────────────────────────────────────────────────────────────
# SCD Type 2 engineer dimension. One row per LDAP per snapshot period.
#
# Current-state queries:     WHERE is_current = TRUE
# Point-in-time attribution: JOIN ON ldap = fact.user_ldap
#                              AND fact.merged_date BETWEEN effective_start_date
#                              AND effective_end_date
#
# Org hierarchy exposed at four levels (L1–L3 + CORE_PLUS chain) so dashboards
# can slice at any level without schema changes.
# ─────────────────────────────────────────────────────────────────────────────

view: dim_users {
  sql_table_name: GITHUB_INSIGHTS.REPORTING.DIM_USER ;;


  # ── Primary key ──────────────────────────────────────────────────────────────

  dimension: pk {
    primary_key: yes
    hidden:      yes
    type:        string
    sql:         ${TABLE}.PK ;;
  }


  # ── Identity ──────────────────────────────────────────────────────────────────

  dimension: ldap {
    type:        string
    sql:         ${TABLE}.LDAP ;;
    label:       "LDAP"
    description: "Internal employee identifier. Primary join key to all fact tables."
  }

  dimension: employee_id {
    type:        string
    sql:         ${TABLE}.EMPLOYEE_ID ;;
    label:       "Employee ID"
    group_label: "Identity"
  }

  dimension: full_name {
    type:        string
    sql:         ${TABLE}.FULL_NAME ;;
    label:       "Full Name"
  }

  dimension: email {
    type:        string
    sql:         ${TABLE}.EMAIL ;;
    label:       "Email"
    group_label: "Identity"
  }

  dimension: active_status {
    type:        string
    sql:         ${TABLE}.ACTIVE_STATUS ;;
    label:       "Active Status"
    description: "active | terminated | leave_of_absence"
    group_label: "Identity"
  }


  # ── Job information ───────────────────────────────────────────────────────────

  dimension: job_profile_set {
    type:        string
    sql:         ${TABLE}.JOB_PROFILE_SET ;;
    label:       "Job Profile Set"
    group_label: "Job Info"
  }

  dimension: job_family {
    type:        string
    sql:         ${TABLE}.JOB_FAMILY ;;
    label:       "Job Family"
    description: "e.g. Software Engineering, Data Engineering, Product Management"
    group_label: "Job Info"
  }

  dimension: job_family_group {
    type:        string
    sql:         ${TABLE}.JOB_FAMILY_GROUP ;;
    label:       "Job Family Group"
    group_label: "Job Info"
  }


  # ── Management chain (CORE_PLUS) ──────────────────────────────────────────────
  # CORE_LEAD is the direct manager; CORE_PLUS_1–4 are the management chain above.
  # Use CORE_PLUS_N to filter by a specific skip-level manager's full organisation.

  dimension: lead_name {
    type:        string
    sql:         ${TABLE}.LEAD_NAME ;;
    label:       "Manager Name"
    group_label: "Management Chain"
  }

  dimension: core_lead {
    type:        string
    sql:         ${TABLE}.CORE_LEAD ;;
    label:       "Manager LDAP"
    group_label: "Management Chain"
  }

  dimension: core_plus_1 {
    type:        string
    sql:         ${TABLE}.CORE_PLUS_1 ;;
    label:       "Skip +1 LDAP"
    group_label: "Management Chain"
  }

  dimension: core_plus_2 {
    type:        string
    sql:         ${TABLE}.CORE_PLUS_2 ;;
    label:       "Skip +2 LDAP"
    group_label: "Management Chain"
  }

  dimension: core_plus_3 {
    type:        string
    sql:         ${TABLE}.CORE_PLUS_3 ;;
    label:       "Skip +3 LDAP"
    group_label: "Management Chain"
  }

  dimension: core_plus_4 {
    type:        string
    sql:         ${TABLE}.CORE_PLUS_4 ;;
    label:       "Skip +4 LDAP"
    group_label: "Management Chain"
  }

  dimension: sup_org_hierarchy {
    type:        string
    sql:         ${TABLE}.SUP_ORG_HIERARCHY ;;
    label:       "Supervisor Org Hierarchy"
    description: "Full flattened management chain string. Useful for ILIKE filters across a subtree."
    group_label: "Management Chain"
  }


  # ── Org hierarchy (L1–L3) ────────────────────────────────────────────────────

  dimension: org_l1_id {
    type:        string
    sql:         ${TABLE}.ORG_L1_ID ;;
    hidden:      yes
    group_label: "Org Hierarchy"
  }

  dimension: org_l1_name {
    type:        string
    sql:         ${TABLE}.ORG_L1_NAME ;;
    label:       "Org L1 (Division)"
    description: "Top-level business division."
    group_label: "Org Hierarchy"
  }

  dimension: org_l2_id {
    type:        string
    sql:         ${TABLE}.ORG_L2_ID ;;
    hidden:      yes
    group_label: "Org Hierarchy"
  }

  dimension: org_l2_name {
    type:        string
    sql:         ${TABLE}.ORG_L2_NAME ;;
    label:       "Org L2 (Sub-org)"
    group_label: "Org Hierarchy"
  }

  dimension: org_l3_id {
    type:        string
    sql:         ${TABLE}.ORG_L3_ID ;;
    hidden:      yes
    group_label: "Org Hierarchy"
  }

  dimension: org_l3_name {
    type:        string
    sql:         ${TABLE}.ORG_L3_NAME ;;
    label:       "Org L3 (Team)"
    description: "Immediate team."
    group_label: "Org Hierarchy"
  }

  dimension: brand_id {
    type:        string
    sql:         ${TABLE}.BRAND_ID ;;
    hidden:      yes
    group_label: "Org Hierarchy"
  }

  dimension: brand_name {
    type:        string
    sql:         ${TABLE}.BRAND_NAME ;;
    label:       "Brand"
    group_label: "Org Hierarchy"
  }


  # ── Function hierarchy (L2–L3) ────────────────────────────────────────────────

  dimension: function_l2_id {
    type:        string
    sql:         ${TABLE}.FUNCTION_L2_ID ;;
    hidden:      yes
    group_label: "Function Hierarchy"
  }

  dimension: function_l2_name {
    type:        string
    sql:         ${TABLE}.FUNCTION_L2_NAME ;;
    label:       "Function L2"
    description: "e.g. Engineering, Data, Design"
    group_label: "Function Hierarchy"
  }

  dimension: function_l3_id {
    type:        string
    sql:         ${TABLE}.FUNCTION_L3_ID ;;
    hidden:      yes
    group_label: "Function Hierarchy"
  }

  dimension: function_l3_name {
    type:        string
    sql:         ${TABLE}.FUNCTION_L3_NAME ;;
    label:       "Function L3"
    group_label: "Function Hierarchy"
  }


  # ── SCD Type 2 validity ────────────────────────────────────────────────────────

  dimension: is_current {
    type:        yesno
    sql:         ${TABLE}.IS_CURRENT ;;
    label:       "Is Current Record"
    description: "TRUE for the latest active snapshot. Always filter on this for current-state dashboards."
  }

  dimension_group: effective_start {
    type:       time
    timeframes: [raw, date]
    sql:        ${TABLE}.EFFECTIVE_START_DATE ;;
    label:      "Effective Start"
    description: "Date this record version became active."
    group_label: "SCD2 Validity"
  }

  dimension_group: effective_end {
    type:       time
    timeframes: [raw, date]
    sql:        ${TABLE}.EFFECTIVE_END_DATE ;;
    label:      "Effective End"
    description: "Date this record was superseded. 9999-12-31 = still active."
    group_label: "SCD2 Validity"
  }


  # ── Measures ──────────────────────────────────────────────────────────────────

  # count_distinct prevents fan-out inflation when joined to one_to_many facts.
  measure: engineer_count {
    type:        count_distinct
    sql:         ${ldap} ;;
    label:       "Engineer Count"
    description: "Distinct engineers. Always apply is_current = TRUE filter for headcount reporting."
  }
}
