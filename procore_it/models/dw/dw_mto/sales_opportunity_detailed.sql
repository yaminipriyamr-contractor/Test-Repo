{{ config(materialized='table', schema='dw_mto', tags=['daily', 'hourly', 'x-db-deps'], snowflake_warehouse=var("xlarge_warehouse")) }}

{% set user_role_ids = dbt_utils.get_column_values(table=ref('territory_user_role'), column='user_role_id') %}

{% set user_ids = dbt_utils.get_column_values(table=ref('territory_user_id'), column='user_id') %}

with funnel_data as (
select distinct funnel.opportunity_id
     , funnel.mql_date_time
     , iff(coalesce(funnel.entry_channel,'-') != 'Referral' AND coalesce(funnel.entry_subchannel,'-') NOT IN ('Support', 'Internal') AND funnel.mql_date_time is not null, true, false) as is_marketing_qualified
     , iff(csl.referred_by_role is not null, true, false) as is_cs_created
     , funnel.product_interest       as  funnel_metric_product_interest
  from {{ ref('salesforce_funnel_metric_prep') }} as funnel
    left join  {{ ref('customer_success_lead') }} as csl
        on funnel.referred_by_role ilike '%' || csl.referred_by_role || '%'
)
,  wrk_day_hier as  (
  select employee_id
       , date
       , employee_full_name
       , job_profile_name
       , manager_1_name
       , manager_2_name
       , manager_3_name
       , manager_4_name
       , business_unit
       , segment
       , location_country
       , location_state
       , location_city
       , employee_hire_date
       , employee_termination_date
  from {{ ref('workday_user_hierarchy_daily') }}
)
,  previous_closed_won as  (
  select sales_opportunity.opportunity_id                 as opportunity_id
    , previous_closed_won.opportunity_id                  as previous_closed_won_opportunity_id
    , previous_closed_won.billings_date                   as previous_closed_won_billings_date
    , previous_closed_won.local_commissionable_delta_arr  as previous_closed_won_local_commissionable_delta_arr
  from {{ ref('sales_opportunity') }} as sales_opportunity
         inner join {{ ref('sales_opportunity') }} as previous_closed_won
                   on sales_opportunity.previous_closed_won_opp = previous_closed_won.opportunity_id
)

, de_booked as (
  select sales_opportunity.opportunity_id                 as opportunity_id
       , debook.opportunity_id                            as de_booked_opportunity_id
       , debook.billings_date                             as de_booked_billings_date
       , debook.opportunity_name                          as de_booked_opportunity_name
  from {{ ref('sales_opportunity') }} as sales_opportunity
         inner join {{ ref('sales_opportunity') }} as debook
                   on sales_opportunity.previous_closed_won_opp = debook.opportunity_id
  where sales_opportunity.stage_name = 'De-booked'
)

, partner_old as (
  select opportunity_id, role, is_primary
  from {{ ref('salesforce_partner_prep') }}
  where role != 'Customer/Prospect'
)

, partner_new as (
  select opportunity_id, role, is_primary
  from {{ ref('salesforce_partner_account_prep') }}
  where role != 'Customer/Prospect'
)

, partner_union as (
  select
      coalesce(po.opportunity_id, pn.opportunity_id) as opportunity_id
      , coalesce(po.role, pn.role) as role
      , max(case when po.is_primary is not null then po.is_primary
                  else pn.is_primary end) as is_primary
      , case when coalesce(po.role, pn.role) in ('Reseller', 'Fulfill') then true else false end as is_reseller_flag
  from partner_old po
  full outer join partner_new pn
      on po.opportunity_id = pn.opportunity_id
      and po.role = pn.role
  group by all
)

, partner_tag as (
  select
      opportunity_id
      , max(is_reseller_flag) as is_reseller
  from partner_union
  where role not in ('Customer/Prospect', 'Influenced')
  group by opportunity_id
)

, product_tf as (
    select
        productarr.salesforce_account_id,
        productarr.opportunity_id,
        productarr.product_sku_name,
        productarr.billings_date,
        productarr.product_sku_category,
        productarr.conversion_types,
        productarr.product_solution,
        productarr.corporate_reporting_segment,
        productarr.isproductadd,
        productarr.iscrossselladd,
        productarr.isproductdowngrade,
        productarr.isupselladd,
        productarr.isproductremove,
        productarr.isnewlogoadd,
        productarr.iscancellation,
        productarr.isdebook,
        productarr.isfyexpansion,
        isproductadd or isupselladd as is_add
    from {{ ref('sales_product_arr') }} as productarr
)
, opportunity_tf as (
    select opportunity_id
        , max(isproductadd = true and conversion_types = 'Non Conversion')                                                  as product_added_t_f
        , max(iscrossselladd = true and conversion_types ='Non Conversion')                                                 as product_cross_sell_t_f
        , max(isupselladd = true and  conversion_types = 'Non Conversion')                                                  as product_upsell_t_f
        , max(isproductremove = true and conversion_types = 'Non Conversion')                                               as product_removed_t_f
        , max(isproductdowngrade = true and conversion_types = 'Non Conversion')                                            as product_downgraded_t_f
        , max(iscancellation = true and conversion_types = 'Non Conversion')                                                as product_cancel_t_f
        , max(conversion_types = 'Non Conversion' and is_add = true and product_solution = 'Financial Management')          as product_financials_t_f
        , max(conversion_types = 'Non Conversion' and is_add = true and product_sku_category = 'Quality & Safety')          as product_qs_t_f
        , max(conversion_types = 'Non Conversion' and is_add = true and
            product_solution = 'Financial Management')                                                                      as strategic_product_flag_y_n_1
        , max(conversion_types = 'Non Conversion' and is_add = true and product_sku_category = 'Quality & Safety' and
              corporate_reporting_segment IN ('ANZ','RO - APAC','RO - EMEA','UKI','UAE','Singapore'))                       as strategic_product_flag_y_n_2
        , strategic_product_flag_y_n_1 or strategic_product_flag_y_n_2                                                      as strategic_product_flag_y_n
    from product_tf
    group by opportunity_id
)

, daily_hierarchy as (
  select date_id
        , level_1_id
        
        , sb_level_1  as sb_level_1_c
        , sb_level_2  as sb_level_2_c
        , sb_level_3  as sb_level_3_c
        , sb_level_4  as sb_level_4_c
        , cso_segment as sb_cso_segment      
  from {{ ref('sales_team_reporting_hierarchy_daily') }}
)
,current_daily_hierarchy_date_max as (
  select  level_1_id  as level_1_id
        , max(date_id)     as max_date_id
  from {{ ref('sales_team_reporting_hierarchy_daily') }}
  group by level_1_id
)

, current_daily_hierarchy as (
  select daily.date_id       as date_id
         , daily.level_1_id  as level_1_id
         , daily.comp_plan_display_name
         , daily.sb_level_1  as sb_level_1_c
         , daily.sb_level_2  as sb_level_2_c
         , daily.sb_level_3  as sb_level_3_c
         , daily.sb_level_4  as sb_level_4_c
         , daily.cso_segment as sb_cso_segment 
         , daily.cse_level_1  as cse_level_1
         , daily.cse_level_2  as cse_level_2
         , daily.cse_level_3  as cse_level_3
         , daily.cse_level_4  as cse_level_4
         , daily.cse_cso_segment as cse_cso_segment      
   from {{ ref('sales_team_reporting_hierarchy_daily') }} daily
   inner join current_daily_hierarchy_date_max max
    on daily.date_id = max.max_date_id
      and daily.level_1_id = max.level_1_id
)

--this and next cte is specific to CSE SMB users because they do not have employee ID and Comp plan ID assigned in workday 
, cse_smb as (
  select 
        c.level_1_id
        , case when c.level_1_id = '00534000009Bt3cAAC' then 'CSE_US_SMB_CSE'
               when c.level_1_id = '0053400000CDCYnAAP' then 'CSE_ANZ_SMB_CSE'
               when c.level_1_id = '0052T00000DFD9pQAH' then 'CSE_CAN_SMB_CSE'
               when c.level_1_id = '0052T00000CWP9zQAH' then 'CSE_Europe_SMB_CSE'
          end as comp_plan_reference_id
  from current_daily_hierarchy c
  where c.level_1_id in ('00534000009Bt3cAAC','0053400000CDCYnAAP','0052T00000DFD9pQAH','0052T00000CWP9zQAH') --SMB CSE Salesforce User IDs Only
)

, cse_smb_mapping as (
  select 
          c.level_1_id                                        as level_1_id
        , c.comp_plan_reference_id                            as comp_plan_reference_id
        , seed.cse_level_1                                    as cse_level_1
        , seed.cse_level_2                                    as cse_level_2
        , seed.cse_level_3                                    as cse_level_3
        , seed.cse_level_4                                    as cse_level_4
        , seed.cse_cso_segment                                as cse_cso_segment
  from cse_smb c
  left join {{ref('sales_comp_plan_id_mapping')}} seed
    on c.comp_plan_reference_id = seed.workday_reference_id
)

, cse_daily_hierarchy as (
  select  team_hier.level_1_id                                                as level_1_id
        , coalesce(smb_mapping.cse_level_1,team_hier.cse_level_1)             as cse_level_1
        , coalesce(smb_mapping.cse_level_2,team_hier.cse_level_2)             as cse_level_2
        , coalesce(smb_mapping.cse_level_3,team_hier.cse_level_3)             as cse_level_3
        , coalesce(smb_mapping.cse_level_4,team_hier.cse_level_4)             as cse_level_4
        , coalesce(smb_mapping.cse_cso_segment,team_hier.cse_cso_segment)     as cse_cso_segment      
  from current_daily_hierarchy team_hier
  left join cse_smb_mapping smb_mapping
    on team_hier.level_1_id = smb_mapping.level_1_id
)

, sales_account_daily as (
  select 
      account_id
     ,date
     ,case when acct.account_segment = 'Emerging' then 'SMB'
          when acct.account_segment = 'Mid Market' then 'Commercial'
          when acct.account_segment = 'Majors' then 'Commercial'
          else acct.account_segment
      end as account_segment
  from {{ ref('sales_account_daily') }} acct
)

, historical_st as (
  select 
      a.opportunity_id    as opportunity_id
     ,a.account_id        as account_id
     ,vertical.vertical_c as vertical
     ,account_segmentation.company_type_tier_2 as company_type_tier_2
     ,a.deal_type         as deal_type
     ,a.billings_date     as billings_date
     ,account_segmentation.account_segment   as current_account_segment
     ,b.account_segment   as historical_account_segment
     ,account_segmentation.rev_cycle_segment as current_rev_cycle_segment
     ,c.rev_cycle_segment as historical_rev_cycle_segment
     ,d.sold_to_segment_1 as historical_sold_to_segment_1
     ,d.sold_to_segment_2 as historical_sold_to_segment_2
     ,d.sold_to_segment_3 as historical_sold_to_segment_3
     ,d.sold_to_segment_4 as historical_sold_to_segment_4
     ,d.st_cso_segment as  historical_st_cso_segment
  from  {{ ref('sales_opportunity') }} a
    left join sales_account_daily b
        on a.account_id = b.account_id 
        and a.billings_date = b.date
    left join {{ ref('salesforce_account_formulas_prep') }} as vertical
        on a.account_id = vertical.id
    left join {{ ref('sales_account_segmentation') }} account_segmentation
        on a.account_id = account_segmentation.account_id
    left join {{ ref('sales_rev_cycle_segment') }} c
        on account_segmentation.billing_country = c.billing_country
        and vertical.vertical_c = c.vertical
        and account_segmentation.company_type_tier_2 = c.company_type_tier_2
        and b.account_segment = c.account_segment
    left join  {{ ref('sold_to_segment_level') }} d
        on account_segmentation.rev_cycle_segment = d.rev_cycle_segment
        and a.deal_type = d.deal_type
)

-- Combines quote tables and aligns equivalent concepts - will be revisited with sales_quote overhaul
, select_primary_quotes as (
select distinct * from (
select 
    cpq.sbqq_opportunity_2                                                  as opportunity_id
    , 'sbqq_quote'                                                          as quote_source
    , id                                                                    as quote_id
    , name                                                                  as quote_name
    , created_date                                                          as created_date
    , last_modified_date                                                    as last_modified_date
    
    , ifnull(cpq.sbqq_primary = true,false)                                 as is_primary_quote
    , cpq.approval_status is not null                                       as is_submitted -- has been submitted for approvals
    , coalesce(cpq.approval_status, cpq.sbqq_status, '~') = 'Approved'      as is_approved
    , ifnull(sbqq_ordered,false)                                            as is_ordered
    
    , iff(cpq.cancel_re_write = 'Yes', true ,false)                         as is_cancel_rewrite
    , ifnull(cpq.auto_renewal = 'Yes', false)                               as is_auto_renewal -- If Yes/True, a flat renewal can be processed without signature

      
from {{ ref('salesforce_sbqq_quote_prep') }} cpq
where not is_deleted
    
union all

select 
    zqu.zqu_opportunity                                                   as opportunity_id
    , 'zqu_quote'                                                         as quote_source
    , zqu.id                                                              as quote_id
    , zqu.name                                                            as quote_name
    , zqu.created_date                                                    as created_date
    , zqu.last_modified_date                                              as last_modified_date
    
    , ifnull(zqu_primary = true,false)                                    as is_primary_quote
    , zqu.zqu_approval_status is not null                                 as is_submitted
    , ifnull(zqu.zqu_approval_status = 'Approved', false)                 as is_approved
    , ifnull(zqu_status = 'Sent to Z-Billing', false)                     as is_ordered
    
    , ifnull(opp.cancel_re = 'Cancel Rewrite', false)                     as is_cancel_rewrite
    , ifnull(zqu.zqu_auto_renew, FALSE)                                   as is_auto_renewal
    
from {{ ref('salesforce_zqu_quote_c_prep') }} zqu
left join {{ ref('salesforce_opportunity_prep') }} opp 
    on opp.id = zqu.zqu_opportunity
where not zqu.is_deleted 
)
-- de-dupe 
qualify rank() over( 
    partition by 
        opportunity_id
    order by 
        -- prioritize along QTC chain
        is_primary_quote desc 
        , is_ordered desc
        , is_approved desc
        , is_submitted desc
        
        -- prioritize cpq
        , quote_source = 'sbqq_quote' desc
        
        -- prioritize touch dates
        , last_modified_date desc
        , created_date desc
        
        -- quotes are ordinally numbered, prioritize highest
        , quote_name desc 
    ) = 1

)

-- get consolidation info, show parent for children, self if parent
-- NOTE Object was created 11/2023 and does not include historical consolidations
, consolidations as (
select distinct
    so.account_id                     as consolidation_parent_account_id
    , ca.consolidated_to_opportunity  as consolidation_parent_opportunity_id
    , so.account_id                   as consolidated_salesforce_account_id
    , so.opportunity_id               as consolidated_opportunity_id
    , case 
        when so.opportunity_id = consolidated_from_opportunity 
            then 'Child'
        when so.opportunity_id = consolidated_to_opportunity 
            then 'Parent'
    end                               as consolidation_role
    
from {{ ref('salesforce_consolidated_accounts_prep')}} ca 
left join {{ ref('sales_opportunity')}} so
    on so.opportunity_id in (
        ca.consolidated_from_opportunity
        , ca.consolidated_to_opportunity
    )
where not ca.is_deleted
        
)

select sales_opportunity.opportunity_name
     , sales_opportunity.opportunity_type
     , sales_opportunity.next_step
     , sales_opportunity.next_step_complete_date
     , sales_opportunity.close_date
     , sales_opportunity.stage_name
     , sales_opportunity.created_date
     , sales_opportunity.opportunity_id
     , sales_opportunity.competitor
     , sales_opportunity.forecast_category
     , sales_opportunity.forecast_category_name
     , sales_opportunity.original_role
     , sales_opportunity.service_start_date
     , sales_opportunity.record_type_id
     , sales_opportunity.opportunity_record_type
     , sales_opportunity.original_created_by_role
     , sales_opportunity.owner_role_at_pipeline
     , sales_opportunity.churn_best_case
     , sales_opportunity.churn_worst_case
     , sales_opportunity.churn_at_risk
     , sales_opportunity.churn_at_risk_notes
     , sales_opportunity.recycle_reason
     , sales_opportunity.renewal_forecast_category_at_close
     , sales_opportunity.reason_for_expansion
     , sales_opportunity.reason_for_cancellation
     , sales_opportunity.qualified_referral
     , sales_opportunity.hb_account_id
     , sales_opportunity.test_flight
     , sales_opportunity.implementation_complete_date
     , sales_opportunity.last_modified_date
     , sales_opportunity.demo_meeting_time
     , sales_opportunity.secondary_win_loss_reason
     , sales_opportunity.secondary_reason_for_cancellation
     , sales_opportunity.secondary_competitor
     , sales_opportunity.sales_engineer
     , sales_opportunity.primary_reason_for_win_loss
     , sales_opportunity.qualification_notes
     , sales_opportunity.product_reason_for_win_description
     , sales_opportunity.product_reason_for_win
     , sales_opportunity.original_vp
     , sales_opportunity.original_trial_duration
     , sales_opportunity.original_trial_bundle
     , sales_opportunity.original_qualified_by_role
     , sales_opportunity.original_manager
     , sales_opportunity.number_of_pushes
     , sales_opportunity.last_stage_change_date
     , sales_opportunity.last_meeting_activity_type
     , sales_opportunity.opportunity_last_activity_date
     , sales_opportunity.is_round_robin_opp
     , sales_opportunity.is_deleted
     , sales_opportunity.implementation_stage
     , sales_opportunity.implementation_on_hold_start_date
     , sales_opportunity.implementation_on_hold_reason_notes
     , sales_opportunity.implementation_on_hold_reason
     , sales_opportunity.implementation_notes
     , sales_opportunity.implementation_est_on_hold_end
     , sales_opportunity.implementation_closed_date
     , sales_opportunity.erp_on_hold_start_date
     , sales_opportunity.erp_integration
     , sales_opportunity.erp_install_complete_date
     , sales_opportunity.erp_implementation_stage
     , sales_opportunity.erp_implementation_closed_date
     , sales_opportunity.erp_implementation_days_on_hold
     , sales_opportunity.description
     , sales_opportunity.implementation_days_on_hold
     , sales_opportunity.customer_growth_type
     , sales_opportunity.zuora_renewal_amount
     , sales_opportunity.zuora_product_bundle
     , sales_opportunity.zuora_amount
     , sales_opportunity.trial_start_date
     , sales_opportunity.trial_action_source
     , sales_opportunity.trial_project_cap
     , sales_opportunity.trial_notes
     , sales_opportunity.trial_end_date
     , sales_opportunity.test_flight_expansion
     , sales_opportunity.contract_changes
     , sales_opportunity.confirmed_annual_construction_volume
     , sales_opportunity.champion_vetted
     , sales_opportunity.cancellation_date
     , sales_opportunity.call_notes
     , sales_opportunity.assistant_implementation_manager
     , sales_opportunity.acv_cap
     , sales_opportunity.action_source
     , sales_opportunity.funnel_metric_id
     , sales_opportunity.entry_campaign
     , sales_opportunity.funnel_contact_id
     , sales_opportunity.entry_channel
     , sales_opportunity.entry_subchannel
     , sales_opportunity.no_channel_source
     , sales_opportunity.opportunity_entry_source
     , sales_opportunity.unqualify_reason
     , sales_opportunity.pipeline_creation_by_stage
     , sales_opportunity.pipeline_creation_time
     , sales_opportunity.is_won
     , sales_opportunity.planned_arr
     , sales_opportunity.years_of_service
     , sales_opportunity.new_arr
     , sales_opportunity.mrr
     , sales_opportunity.delta_mrr
     , sales_opportunity.account_last_activity_date
     , sales_opportunity.planned_renewal
     , sales_opportunity.previous_closed_won_opp
     , sales_opportunity.service_end_date
     , sales_opportunity.erp_go_live_date
     , sales_opportunity.provisioned_trial_products
     , sales_opportunity.billing_terms
     , sales_opportunity.edited_msa_sections
     , sales_opportunity.local_delta_out_year_value_growth
     , sales_opportunity.non_standard_terms_and_conditions
     , sales_opportunity.opt_in_date
     , sales_opportunity.opt_out_date
     , sales_opportunity.upsell_contract_type
     , sales_opportunity.usd_out_year_value
     , sales_opportunity.renewal_forecast_category_at_30_days
     , sales_opportunity.renewal_forecast_category_at_60_days
     , sales_opportunity.renewal_forecast_category_at_90_days
     , sales_opportunity.expected_expansion_date
     , sales_opportunity.aos_product_bundle
     , sales_opportunity.ps_scoping_status
     , sales_opportunity.ps_forecast_amount
     , sales_opportunity.sow_services
     , sales_opportunity.sow_services_description
     , sales_opportunity.ps_notes
     , sales_opportunity.gut
     , sales_opportunity.risk_forecast_category
     , sales_opportunity.risk_forecast_primary_reason
     , sales_opportunity.se_deal_score
     , sales_opportunity.referred_partner
     , sales_opportunity.product_interest
     , sales_opportunity.cs_risk_forecast
     , sales_opportunity.loss_disposition
     , sales_opportunity.reason_for_win_loss_description
     , sales_opportunity.per_project
     , sales_opportunity.sales_play
     , sales_opportunity.sales_play_name
    -- Opp Calculated Fields
     , sales_opportunity.is_closed
     , sales_opportunity.billings_date
     , sales_opportunity.true_pipeline_creation_date
     , sales_opportunity.age_custom
     , sales_opportunity.next_step_past_due
     , sales_opportunity.time_as_customer
     , sales_opportunity.new_arr_type
     , sales_opportunity.deal_type
     , sales_opportunity.deal_type_code
     , sales_opportunity.expansion_type
     , sales_opportunity.lapsed_renewal
     , sales_opportunity.zuora_new_arr
     , sales_opportunity.zuora_first_year_value_arr
     , sales_opportunity.zuora_first_year_value_arr_2
     , sales_opportunity.zuora_first_year_value_arr_3
     , sales_opportunity.zuora_original_renewal_book
     , sales_opportunity.zuora_book_won
     , sales_opportunity.zuora_install_base_book_won
     , sales_opportunity.commission_bookings_date
     , sales_opportunity.deal_size
     , sales_opportunity.days_since_last_activity_on_account
     , sales_opportunity.install_base_pipeline
     , sales_opportunity.expansion_arr
     , sales_opportunity.total_new_arr
     , sales_opportunity.debooked_arr
     , sales_opportunity.gross_new_arr
     , sales_opportunity.churn_and_downgrade_arr
     , sales_opportunity.net_new_arr
     , sales_opportunity.zuora_install_base_renewal_amount
     , sales_opportunity.is_retention_opportunity
     , sales_opportunity.is_new_arr_opp_type
     , sales_opportunity.is_new_arr_won
     , sales_opportunity.is_pipeline
     , sales_opportunity.sql_converted_status
     , sales_opportunity.is_sql
     , sales_opportunity.is_new_logo
     , sales_opportunity.is_expansion
     , sales_opportunity.is_open_opportunity
     , sales_opportunity.is_open_pipeline
     , sales_opportunity.is_sdr_created
     , sales_opportunity.is_cs_created_original_created_by_role
     , sales_opportunity.is_ae_created
     , sales_opportunity.is_created_by_owner
     , sales_opportunity.open_pipeline_dollars
     , sales_opportunity.pipeline_dollars
     , sales_opportunity.new_arr_won_dollars
     , sales_opportunity.is_debooked_opportunity
     , sales_opportunity.sql_to_sao_velocity
     , sales_opportunity.sao_to_cw_velocity
     , sales_opportunity.implementation_type
     , sales_opportunity.implementation_duration
     , sales_opportunity.has_completed_implementation
     , sales_opportunity.stage_duration
     , sales_opportunity.erp_go_live_duration
     , sales_opportunity.erp_implementation_duration
     , sales_opportunity.meddiccc_score
     , dim_channel_grouping.channel_subchannel_grouping
     , sales_opportunity.account_id
     , sales_opportunity.manager_next_step
     , sales_opportunity.manager_next_step_update
     , account_segmentation.account_name
     , account_segmentation.billing_country
     , account_segmentation.billing_state
     , account_segmentation.company_type
     , account_segmentation.company_type_tier_2
     , account_segmentation.account_segment
     , account_segmentation.detailed_segment_tier_1
     , account_segmentation.detailed_segment_tier_2
     , account_segmentation.detailed_segment_tier_3
     , account_segmentation.vertical
     , account_segmentation.region
     , account_segmentation.rev_cycle_segment
     , account_segmentation.corporate_reporting_segment
     , account_segmentation.rev_cycle_region
     , master_account.annual_construction_volume_c as annual_construction_volume
     , case when master_account.territory_2 > 0
            then master_account.territory_2
            else 0
        end as new_territory_number

    -- Attributed Quote Data                            
    , pq.quote_id    
    , pq.quote_source                                    
    , pq.is_primary_quote
    , pq.is_cancel_rewrite
    , pq.is_auto_renewal

    -- Consolidation Dims
    , cons.consolidation_role is not null                                   as is_consolidation
    , cons.consolidation_role
    , cons.consolidation_parent_account_id
    , cons.consolidation_parent_opportunity_id
    
    -- custom segmentation for install targets
     , ifnull(rev_cycle_segment_rollup_seed.rev_cycle_segment_rollup, account_segmentation.rev_cycle_segment) as rev_cycle_segment_rollup

    -- user info
     , sales_opportunity.owner_id
     , user_id_reference.opportunity_owner_name                             as owner_name
     , user_id_reference.opportunity_owner_title                            as owner_title
     , user_id_reference.opportunity_owner_role                             as owner_role
     , user_id_reference.opportunity_owner_manager_name                     as manager_name
     , user_id_reference.opportunity_owner_manager_id                       as manager_id
     , user_id_reference.opportunity_owner_svp_name                         as svp_name
     , user_id_reference.opportunity_owner_svp_id                           as svp_id
     , sales_opportunity.created_by_id
     , user_id_reference.created_by_user_name                               as created_by_name
     , sales_opportunity.qualified_by_id
     , user_id_reference.qualified_by_user_name                             as qualified_by_name
     , user_id_reference.qualified_by_manager_name                          as qualified_by_manager_name
     , user_id_reference.qualified_by_user_title                            as qualified_by_title
     , user_id_reference.qualified_by_user_vertical                         as qualified_by_vertical
     , user_id_reference.qualified_by_user_office_location                  as qualified_by_office_location
     , user_id_reference.qualified_by_user_segment                          as qualified_by_segment
     , user_id_reference.qualified_by_user_reporting_role                   as qualified_by_reporting_role
     , user_id_reference.qualified_by_user_continental_region               as qualified_by_continental_region
     , sales_opportunity.customer_success_manager_id
     , user_id_reference.customer_success_manager_user_name                 as customer_success_manager_name
     , user_id_reference.customer_success_manager_manager_name              as csm_manager_name
     , user_id_reference.customer_success_manager_user_reporting_role       as csm_reporting_role
     , sales_opportunity.qualified_by_2
     , user_id_reference.qualified_by_2_user_name                           as qualified_by_2_name
     , user_id_reference.qualified_by_2_user_title                          as qualified_by_2_title
     , user_id_reference.qualified_by_2_user_vertical                       as qualified_by_2_vertical
     , user_id_reference.qualified_by_2_user_office_location                as qualified_by_2_office_location
     , user_id_reference.qualified_by_2_user_segment                        as qualified_by_2_segment
     , user_id_reference.qualified_by_2_manager_name                        as qualified_by_2_manager_name
     , user_id_reference.qualified_by_2_user_reporting_role                 as qualified_by_2_reporting_role
     , user_id_reference.qualified_by_2_user_continental_region             as qualified_by_2_continental_region
     , sales_opportunity.champion
     , contact.name                                                         as champion_name
     , sales_opportunity.implementation_manager
     , user_id_reference.implementation_manager_name                        as implementation_manager_name
     , sales_opportunity.isr_id
     , user_id_reference.isr_user_name                                      as isr_name
     , sales_opportunity.erp_integration_specialist_id                      as erp_integration_specialist_id
     , user_id_reference.erp_integration_specialist_user_name               as erp_integration_specialist_old
     , user_id_reference_a.account_executive_id
     , user_id_reference_a.account_executive_name
     , user_id_reference_a.business_development_representative_id
     , user_id_reference_a.business_development_representative_name
     , user_id_reference_a.account_executive_manager_id
     , user_id_reference_a.account_executive_manager_name
    -- binary fields
     , funnel_data.is_marketing_qualified as is_inbound_opportunity

     , sales_opportunity.opportunity_source
     , case when sales_opportunity.is_pipeline = true
                and sales_opportunity.opportunity_source ilike '%Outbound Sales%'
            then true
            else false
            end as is_ae_self_sourced_pipeline
     , case when is_ae_self_sourced_pipeline = true
            then sales_opportunity.zuora_first_year_value_arr_2
            else 0
        end as ae_self_sourced_pipeline_dollars
    -- creation team pipeline dollars
     , case when sales_opportunity.is_pipeline = true
                and sales_opportunity.opportunity_record_type = 'Renewal Process'
            then sales_opportunity.pipeline_dollars
            else 0
        end as renewal_pipeline_dollars
     , case when sales_opportunity.is_pipeline = true
                 and sales_opportunity.opportunity_source = 'Inbound'
            then sales_opportunity.pipeline_dollars
            else 0
        end as inbound_pipeline_dollars
     , case when sales_opportunity.is_pipeline = true
                 and sales_opportunity.opportunity_source = 'Outbound SDR'
            then sales_opportunity.pipeline_dollars
            else 0
        end as sdr_pipeline_dollars
     , case when sales_opportunity.is_pipeline = true
                and sales_opportunity.opportunity_source_role = 'AE'
            then sales_opportunity.pipeline_dollars
            else 0
        end as ae_pipeline_dollars
     , case when sales_opportunity.is_pipeline = true
                 and sales_opportunity.opportunity_source = 'Partner'
            then sales_opportunity.pipeline_dollars
            else 0
        end as partner_pipeline_dollars
     , case when sales_opportunity.is_pipeline = true
                 and sales_opportunity.opportunity_source_role = 'CSQL'
            then sales_opportunity.pipeline_dollars
            else 0
        end as cs_pipeline_dollars
     , case when sales_opportunity.is_pipeline = true
                and sales_opportunity.opportunity_source = 'Other'
            then sales_opportunity.pipeline_dollars
            else 0
        end as other_pipeline_dollars
    , case when sales_opportunity.is_pipeline = true
                and sales_opportunity.opportunity_source_role = 'AM'
            then sales_opportunity.pipeline_dollars
            else 0
        end as am_pipeline_dollars
    , sales_opportunity.is_partner_referral_opportunity as is_partner_referral_opportunity
    , sales_opportunity.is_partner_sourced
    , sales_opportunity.recommendation as recommendation_id
    , sales_opportunity.downgrade_straight_renewal_reason as downgrade_reason
    , sales_opportunity.debook_reason
    , sales_opportunity.last_open_stage
    , sales_opportunity.standard_msa_t_f
    , sales_opportunity.territory2_id
    , sales_opportunity.price_bps
    , sales_opportunity.holdover_date
    , sales_opportunity.holdover_desc
    , sales_opportunity.ae_territory_number
    , sales_opportunity.exclude_from_territory_filter
    , sales_opportunity.fyv_overwrite
    , sales_opportunity.region_level_1
    , sales_opportunity.region_level_2
    , sales_opportunity.region_level_3
    , sales_opportunity.region_level_4
    , sales_opportunity.gtm_level
    , sales_opportunity.corporate_strategic_tiers
    , sales_opportunity.is_cs_created
    , sales_opportunity.was_a_new_product_added
    , wrk_hier.employee_full_name
    , wrk_hier.job_profile_name
    , null                                        as master_start_date
    , null                                        as master_end_date
    , null                                        as employee_start_date
    , null                                        as employee_end_date
    , wrk_hier.manager_1_name
    , wrk_hier.manager_2_name
    , wrk_hier.manager_3_name
    , wrk_hier.manager_4_name
    , wrk_hier.employee_id
    , wrk_hier.business_unit
    , wrk_hier.segment
    , wrk_hier.location_country
    , wrk_hier.location_state
    , wrk_hier.location_city
    , 'Y'                                         as is_active_employment_period
    , wrk_hier.employee_hire_date
    , wrk_hier.employee_termination_date
    , null                                        as business_process_reason
    , null                                        as business_process_category
    , sales_opportunity.quote_currency
    , sales_opportunity.final_exchange_rate
    , sales_opportunity.local_amount
    , sales_opportunity.local_mrr
    , sales_opportunity.local_delta_mrr
    , sales_opportunity.local_commissionable_delta_arr
    , sales_opportunity.local_delta_arr
    , sales_opportunity.local_total_delta_arr
    , previous_closed_won.previous_closed_won_opportunity_id
    , previous_closed_won.previous_closed_won_billings_date
    , previous_closed_won.previous_closed_won_local_commissionable_delta_arr
    , opportunity_tf.product_added_t_f
    , opportunity_tf.product_cross_sell_t_f
    , opportunity_tf.product_upsell_t_f
    , opportunity_tf.product_removed_t_f
    , opportunity_tf.product_downgraded_t_f
    , opportunity_tf.product_cancel_t_f
    , opportunity_tf.product_financials_t_f
    , opportunity_tf.product_qs_t_f
    , opportunity_tf.strategic_product_flag_y_n_1
    , opportunity_tf.strategic_product_flag_y_n_2
    , opportunity_tf.strategic_product_flag_y_n
    , sales_opportunity.commissionable_pipeline_value
    , sales_opportunity.partner_next_steps
    , sales_opportunity.high_velocity_transfer
    , coalesce(sales_opp_forecast.forecast_ner,0) as forecast_ner
    , case when sales_opportunity.is_retention_opportunity = true
           then user_id_reference.customer_success_manager_manager_name
           when sales_opportunity.is_retention_opportunity = false
                and user_hierarchy_manager_role.user_role_name ilike '%implementation%'
           then customer_success_manager.manager_name
        else user_hierarchy_manager_role.manager_name
      end as csm_manager 
    , funnel_data.funnel_metric_product_interest
    , sales_opportunity.cs_expansion_value
    , sales_opportunity.cs_product_interest
    , sales_opportunity.cs_suggested_acv_cap
    , sales_opportunity.execution_plan
    , cs.renewal_outcome
    , cs.renewal_forecast_outcome
    , cs.renewal_forecast_accuracy_90
    , sales_opportunity.subscription_term
    , coalesce(st_level.sold_to_segment_1, 'Unknown') as sold_to_segment_1
    , coalesce(st_level.sold_to_segment_2, 'Unknown') as sold_to_segment_2
    , coalesce(st_level.sold_to_segment_3, 'Unknown') as sold_to_segment_3
    , coalesce(st_level.sold_to_segment_4, 'Unknown') as sold_to_segment_4
    , coalesce(st_level.st_cso_segment, 'Unknown')    as st_cso_segment
    , case when cdh.sb_level_1_c is null
             and sales_opportunity.region_level_2 = 'LATAM'
             and year(sales_opportunity.billings_date) >= '2024'
           then 'LATAM'
           when cdh.sb_level_1_c is null then 'Unknown'
       else cdh.sb_level_1_c
      end as current_sb_level_1
    , case when cdh.sb_level_2_c is null
             and sales_opportunity.region_level_2 = 'LATAM'
             and year(sales_opportunity.billings_date) >= '2024'
           then 'LATAM'
           when cdh.sb_level_2_c is null 
             or (sales_opportunity.region_level_2 = 'LATAM' and year(sales_opportunity.billings_date) < '2024')
             or (cdh.sb_level_2_c is not null and year(sales_opportunity.billings_date) < '2024')
           then 'Unknown'
       else cdh.sb_level_2_c
      end as current_sb_level_2
    , case when cdh.sb_level_3_c is null
             and 'LATAM' in (cdh.sb_level_2_c)
             and year(sales_opportunity.billings_date) >= '2024'
           then 'LATAM'
           when cdh.sb_level_3_c is null
             or (sales_opportunity.region_level_2 = 'LATAM' and year(sales_opportunity.billings_date) < '2024')
             or (cdh.sb_level_3_c is not null and year(sales_opportunity.billings_date) < '2024')
           then 'Unknown'
       else cdh.sb_level_3_c
      end as current_sb_level_3
    , case when cdh.sb_level_4_c is null
             and 'LATAM' in (cdh.sb_level_2_c,cdh.sb_level_3_c)
             and year(sales_opportunity.billings_date) >= '2024'
           then 'LATAM'
           when cdh.sb_level_4_c is null
             or (sales_opportunity.region_level_2 = 'LATAM' and year(sales_opportunity.billings_date) < '2024')
             or (cdh.sb_level_4_c is not null and year(sales_opportunity.billings_date) < '2024')
           then 'Unknown'
       else cdh.sb_level_4_c
      end as current_sb_level_4
    , case when  year(sales_opportunity.billings_date) >= 2024 
             and sales_opportunity.region_level_2 = 'LATAM' 
             and  'LATAM' in (current_sb_level_2,current_sb_level_3,current_sb_level_4)
           then 'LATAM'
           when cdh.sb_cso_segment is null
             or (sales_opportunity.region_level_2 = 'LATAM' and year(sales_opportunity.billings_date) < '2024')
             or (cdh.sb_level_4_c is not null and year(sales_opportunity.billings_date) < '2024')
           then 'Unknown'
       else cdh.sb_cso_segment
      end as current_sb_cso_segment
    , case 
    --For future dated opps, take their current sb level since we don't have snapshots on user hierarchy in workday for future dates.
        when sales_opportunity.billings_date > current_date() 
          then current_sb_level_1
    --Starting 2025+, we don't have a LATAM sellers and LATAM CSEs own those opps but if there isn't a sb level associated we want to attribute to LATAM
        when dh.sb_level_1_c is null
             and sales_opportunity.region_level_2 = 'LATAM'
             and year(sales_opportunity.billings_date) >= '2025'
          then 'LATAM'
    --In 2024, default value for level 1 = Global
        when dh.sb_level_1_c is null and year(sales_opportunity.billings_date) < '2025'
          then 'Global'   
    --Due to employees being termed, we want to take their most recent current sb level prior to their departure
        when dh.sb_level_1_c is null 
            and cdh.sb_level_1_c is not null 
          then current_sb_level_1   
    --Default null values as 'Unknown' if it didn't fulfil prior criteria
        when dh.sb_level_1_c is null and year(sales_opportunity.billings_date) >= '2025'
          then 'Unknown'
       else dh.sb_level_1_c
      end as sb_level_1
    , case 
    --For future dated opps, take their current sb level
        when sales_opportunity.billings_date > current_date() 
          then current_sb_level_2
    --Starting 2025+, we don't have a LATAM sellers and LATAM CSEs own those opps but if there isn't a sb level associated we want to attribute to LATAM
        when dh.sb_level_2_c is null
             and sales_opportunity.region_level_2 = 'LATAM'
             and year(sales_opportunity.billings_date) >= '2024'
           then 'LATAM'
    --Due to employees being termed, we want to take their most recent current sb level prior to their departure
    --Only reference current_sb_level when prior level has same criteria in order to maintain roll up
        when coalesce(dh.sb_level_1_c, dh.sb_level_2_c) is null 
            and cdh.sb_level_2_c is not null 
           then current_sb_level_2
    --Default null values as 'Unknown' if it didn't fulfil prior criteria
        when dh.sb_level_2_c is null 
             or (sales_opportunity.region_level_2 = 'LATAM' and year(sales_opportunity.billings_date) < '2024')
             or (dh.sb_level_2_c is not null and year(sales_opportunity.billings_date) < '2024')
           then 'Unknown'
       else dh.sb_level_2_c
      end as sb_level_2
    , case 
    --For future dated opps, take their current sb level
        when sales_opportunity.billings_date > current_date() 
          then current_sb_level_3
    --Starting 2025+, we don't have a LATAM sellers and LATAM CSEs own those opps but if there isn't a sb level associated we want to attribute to LATAM
        when dh.sb_level_3_c is null
             and 'LATAM' in (sb_level_2)
             and year(sales_opportunity.billings_date) >= '2024'
           then 'LATAM'
    --Due to employees being termed, we want to take their most recent current sb level prior to their departure
    --Only reference current_sb_level when prior level has same criteria in order to maintain roll up
        when coalesce(dh.sb_level_1_c, dh.sb_level_2_c,dh.sb_level_3_c) is null  and cdh.sb_level_3_c is not null 
           then current_sb_level_3
    --Default null values as 'Unknown' if it didn't fulfil prior criteria
        when dh.sb_level_3_c is null
             or (sales_opportunity.region_level_2 = 'LATAM' and year(sales_opportunity.billings_date) < '2024')
             or (dh.sb_level_3_c is not null and year(sales_opportunity.billings_date) < '2024')
           then 'Unknown'
       else dh.sb_level_3_c
      end as sb_level_3
    , case
    --For future dated opps, take their current sb level
        when sales_opportunity.billings_date > current_date() 
          then current_sb_level_4 
    --Starting 2025+, we don't have a LATAM sellers and LATAM CSEs own those opps but if there isn't a sb level associated we want to attribute to LATAM
        when dh.sb_level_4_c is null
             and 'LATAM' in (sb_level_2,sb_level_3)
             and year(sales_opportunity.billings_date) >= '2024'
           then 'LATAM'
    --Due to employees being termed, we want to take their most recent current sb level prior to their departure
    --Only reference current_sb_level when prior level has same criteria in order to maintain roll up
        when coalesce(dh.sb_level_1_c, dh.sb_level_2_c,dh.sb_level_3_c,dh.sb_level_4_c) is null and cdh.sb_level_4_c is not null 
           then current_sb_level_4
    --Default null values as 'Unknown' if it didn't fulfil prior criteria
        when dh.sb_level_4_c is null
             or (sales_opportunity.region_level_2 = 'LATAM' and year(sales_opportunity.billings_date) < '2024')
             or (dh.sb_level_4_c is not null and year(sales_opportunity.billings_date) < '2024')
           then 'Unknown'
       else dh.sb_level_4_c
      end as sb_level_4
    , case 
    --For future dated opps, take their current sb level
        when sales_opportunity.billings_date > current_date() 
          then current_sb_cso_segment
    --Starting 2025+, we don't have a LATAM sellers and LATAM CSEs own those opps but if there isn't a sb level associated we want to attribute to LATAM
        when year(sales_opportunity.billings_date) >= 2024 
             and sales_opportunity.region_level_2 = 'LATAM' 
             and 'LATAM' in (sb_level_2,sb_level_3,sb_level_4)
           then 'LATAM'
    --Due to employees being termed, we want to take their most recent current sb level prior to their departure
    --Only reference current_sb_level when prior level has same criteria in order to maintain roll up
        when coalesce(dh.sb_level_1_c, dh.sb_level_2_c,dh.sb_level_3_c,dh.sb_level_4_c,dh.sb_cso_segment) is null and cdh.sb_cso_segment is not null 
           then current_sb_cso_segment
    --Default null values as 'Unknown' if it didn't fulfil prior criteria
        when dh.sb_cso_segment is null
             or (sales_opportunity.region_level_2 = 'LATAM' and year(sales_opportunity.billings_date) < '2024')
             or (dh.sb_level_4_c is not null and year(sales_opportunity.billings_date) < '2024')
           then 'Unknown'
        else dh.sb_cso_segment
      end as sb_cso_segment
    
    , case when sales_opportunity.deal_type = 'New Logo'
           then 'New Logo' 
        else 'Expansion' 
      end as deal_type_category
    , sales_opportunity.downgrade_debook_arr
    , sales_opportunity.technical_selection_details
    , sales_opportunity.close_plan
    , sales_opportunity.ps_engaged
    , sales_opportunity.deal_review
    , sales_opportunity.scope_acv_product_set
    , sales_opportunity.mutual_action_plan_link
    , sales_opportunity.value_consultant_old
    , sales_opportunity.value_consultant_notes
    , sales_opportunity.commercial_selection
    , sales_opportunity.commercial_selection_details
    , sales_opportunity.legal_selection
    , sales_opportunity.legal_selection_details
    , sales_opportunity.political_selection
    , sales_opportunity.political_selection_details
    , sales_opportunity.technical_selection
    , sales_opportunity.technical_selection_big_deals
    , case when sales_opportunity.expansion_arr > 0 and sales_opportunity.planned_arr != 0
           then (sales_opportunity.expansion_arr - sales_opportunity.planned_arr)
           else sales_opportunity.expansion_arr
      end                                          as  expansion_arr_excluding_planned
    , sales_opportunity.influenceable_risk
    , sales_opportunity.mitigation_update
    , sales_opportunity.opportunity_upside
    , sales_opportunity.top_account
    , sales_opportunity.opportunity_source_role
    , master_account.db_sic_4_code_1               as db_sic_4_code_1
    , master_account.db_sic_4_code_2               as db_sic_4_code_2
    , master_account.db_sic_4_code_3               as db_sic_4_code_3
    , case when (sales_opportunity.stage_name not in ('Cancelled',  'Deal Review'))
                and sales_opportunity.opportunity_record_type = 'Renewal Process'
                and sales_opportunity.opportunity_type = 'Cancellation'
           then true else false
      end                                         as pending_cancellations_flag

      {% for usr_role_id in user_role_ids %}
          , sales_opportunity.{{usr_role_id}}     as {{usr_role_id}}
      {% endfor %}

      {% for usr_id in user_ids %}
          , sales_opportunity.{{usr_id}}          as {{usr_id}}
      {% endfor %}
    , cse_dh.cse_level_1       as cse_level_1
    , cse_dh.cse_level_2       as cse_level_2
    , cse_dh.cse_level_3       as cse_level_3
    , cse_dh.cse_level_4       as cse_level_4
    , cse_dh.cse_cso_segment   as cse_cso_segment
    , ifnull(sales_opportunity.gut = TRUE, false) or ifnull(sales_opportunity.forecast_category_name = 'Most Likely', false)         as gut_most_likely
    , sales_opportunity.ai_arr
    , sales_opportunity.ai_deal_score
    , sales_opportunity.ai_notes
    , sales_opportunity.ai_product
    , sales_opportunity.bim_arr
    , sales_opportunity.bim_deal_score
    , sales_opportunity.bim_notes
    , sales_opportunity.estimating_arr
    , sales_opportunity.estimating_deal_score
    , sales_opportunity.estimating_notes
    , sales_opportunity.cost_management_arr
    , sales_opportunity.cost_management_deal_score
    , sales_opportunity.cost_management_notes
    , sales_opportunity.platform_deal_score
    , sales_opportunity.platform_notes
    , sales_opportunity.project_execution_arr
    , sales_opportunity.project_execution_deal_score
    , sales_opportunity.project_execution_notes
    , sales_opportunity.resource_management_arr
    , sales_opportunity.resource_management_deal_score
    , sales_opportunity.resource_management_notes
    , sales_opportunity.platform_solspec
    , sales_opportunity.stage_3_sao_date
    , sales_opportunity.solutions_close_quarter

    , historical_st.historical_sold_to_segment_1
    , historical_st.historical_sold_to_segment_2
    , historical_st.historical_sold_to_segment_3
    , historical_st.historical_sold_to_segment_4
    , historical_st.historical_st_cso_segment
    , sdfc_formulas_prep.manager_forecast_value
    , sdfc_formulas_prep.manager_pipeline_forecast_override
    , sdfc_formulas_prep.forecast_category_override
    , sdfc_formulas_prep.manager_forecast
    , sales_opportunity.manager_best_case
    , sales_opportunity.forecast_close_date
    , sales_opportunity.se_notes
    , sales_opportunity.se_deal_score_notes  

    , iff(sales_opportunity.stage_name = 'Cancelled', true, false) as iscancellation
    , iff(sales_opportunity.stage_name = 'De-booked', true, false) as isdebook
    , iff(sales_opportunity.qualified_by_id is not null and sales_opportunity.qualified_by_2 is not null, 0.5, 1.0) as split_percentage
    , partner_tag.is_reseller
    , de_booked.de_booked_opportunity_id
    , de_booked.de_booked_billings_date
    , de_booked.de_booked_opportunity_name
    , current_timestamp() as data_as_of
  from {{ ref('sales_opportunity') }} sales_opportunity
  left join previous_closed_won
    on sales_opportunity.opportunity_id = previous_closed_won.opportunity_id
  left join {{ ref('sales_account_segmentation') }} account_segmentation
    on sales_opportunity.account_id = account_segmentation.account_id
  left join {{ ref('salesforce_opportunity_user_id_reference') }} user_id_reference
    on sales_opportunity.opportunity_id = user_id_reference.opportunity_id
  left join {{ ref('salesforce_account_user_id_reference') }} user_id_reference_a
    on sales_opportunity.account_id = user_id_reference_a.account_id
  left join {{ ref('salesforce_contact_prep') }} contact
    on sales_opportunity.champion = contact.id
  left join {{ ref('dim_channel_grouping') }} dim_channel_grouping
    on dim_channel_grouping.pk = sales_opportunity.entry_channel || nvl(sales_opportunity.entry_subchannel,'')
  left join funnel_data
    on funnel_data.opportunity_id = sales_opportunity.opportunity_id
  left join {{ ref('salesforce_account_prep') }} master_account
    on sales_opportunity.account_id = master_account.id
  left join {{ ref('sales_rev_cycle_segment_rollup') }} rev_cycle_segment_rollup_seed
    on sales_opportunity.install_base_pipeline = rev_cycle_segment_rollup_seed.install_base_pipeline
      and account_segmentation.rev_cycle_segment = rev_cycle_segment_rollup_seed.rev_cycle_segment
  left join {{ ref('salesforce_user_hierarchy') }} as user_hierarchy
    on sales_opportunity.owner_id = user_hierarchy.user_id
  left join {{ ref('sales_opportunity_forecast') }} as sales_opp_forecast
    on sales_opportunity.opportunity_id = sales_opp_forecast.opportunity_id
      and sales_opportunity.account_id = sales_opp_forecast.account_id
  left join {{ ref('salesforce_user_hierarchy') }} user_hierarchy_manager_role
    on master_account.current_manager = user_hierarchy_manager_role.user_id
  left join {{ ref('salesforce_user_hierarchy') }} customer_success_manager
    on master_account.customer_success_manager = customer_success_manager.user_id
  left join wrk_day_hier as wrk_hier
    on sales_opportunity.billings_date= wrk_hier.date
      and user_hierarchy.employee_number=wrk_hier.employee_id
  left join opportunity_tf
    on sales_opportunity.opportunity_id = opportunity_tf.opportunity_id
  left join {{ ref('customer_success_opportunity_calculations') }} cs
    on sales_opportunity.opportunity_id = cs.opportunity_id
  left join {{ ref('sold_to_segment_level') }} st_level
    on equal_null(account_segmentation.rev_cycle_segment,st_level.rev_cycle_segment)
      and equal_null(sales_opportunity.deal_type,st_level.deal_type)
  left join daily_hierarchy dh
      on dh.date_id = sales_opportunity.billings_date
      and dh.level_1_id = sales_opportunity.owner_id
  left join current_daily_hierarchy cdh
      on cdh.level_1_id = sales_opportunity.owner_id
  left join cse_daily_hierarchy cse_dh
      on cse_dh.level_1_id = sales_opportunity.customer_success_engineer_user_id
  left join historical_st historical_st
      on sales_opportunity.billings_date = historical_st.billings_date
      and sales_opportunity.account_id = historical_st.account_id
      and sales_opportunity.opportunity_id = historical_st.opportunity_id
  left join select_primary_quotes pq  
      on pq.opportunity_id = sales_opportunity.opportunity_id
  left join consolidations cons
      on cons.consolidated_opportunity_id = sales_opportunity.opportunity_id
  left join {{ ref('salesforce_opportunity_formulas_prep') }} as sdfc_formulas_prep
      on sales_opportunity.opportunity_id = sdfc_formulas_prep.id
  left join partner_tag
      on sales_opportunity.opportunity_id = partner_tag.opportunity_id
  left join de_booked
      on sales_opportunity.opportunity_id = de_booked.opportunity_id