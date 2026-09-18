{{ config(materialized='table', schema='dw_mto', tags=['daily','hourly','x-db-deps']) }}

With cancellation as(
select
        e.opportunity_id                                                         as opportunity_id
        ,sum(case when (e.stage_name not in ('Cancelled',  'Deal Review'))
                       and e.opportunity_record_type = 'Renewal Process'
                       and e.opportunity_type = 'Cancellation'
                  then e.engagement_book_arr
             end)                                                                as pending_cancellations
from    {{ ref('opportunity_engagement_book_prep') }} e
group by all
)

select
   -- fields calculated from upstream PDP sales_engagement_book
   e.account_id                                       as account_id
  ,e.opportunity_id                                   as opportunity_id
  ,e.opportunity_name                                 as opportunity_name
  ,acct_seg.account_name                              as account_name
  ,e.opportunity_type                                 as opportunity_type
  ,e.net_new_arr                                      as net_new_arr
  ,e.stage_name                                       as stage_name
  ,e.opportunity_record_type                          as opportunity_record_type
  ,e.churn_and_downgrade_arr                          as churn_and_downgrade_arr
  ,e.expansion_arr                                    as expansion_arr
  ,e.customer_success_manager_id                      as customer_success_manager_id
  ,e.customer_success_manager_name                    as customer_success_manager_name
  ,e.csm_manager_name                                 as csm_manager_name
  ,e.csm_reporting_role                               as csm_reporting_role
  ,e.install_base_pipeline                            as install_base_pipeline
  ,e.zuora_first_year_value_arr_2                     as zuora_first_year_value_arr_2
  ,e.engagement_year_number                           as engagement_year_number
  ,e.engagement_book_arr                              as engagement_book_arr
  ,e.renewal_book_arr                                 as renewal_book_arr
  ,e.engagement_recognition_date                      as engagement_recognition_date
  ,e.up_for_renewal_date                              as up_for_renewal_date
  ,e.is_multi_year                                    as is_multi_year
  ,e.is_engagement_opportunity                        as is_engagement_opportunity
  ,e.is_interim_planned                               as is_interim_planned
  ,e.open_or_closed                                   as open_or_closed
   -- join in other dimensions for reporting purposes
   -- acct
  ,user_id_reference.current_manager_id               as current_manager_id
  ,user_id_reference.current_manager_name             as current_manager_name
   -- segment
  ,acct_seg.owner_vertical                            as owner_vertical
  ,acct_seg.rev_cycle_segment                         as rev_cycle_segment
  ,acct_seg.account_segment                           as account_segment
  ,acct_seg.vertical                                  as vertical
  ,acct_seg.corporate_reporting_segment               as corporate_reporting_segment
  ,acct_seg.region_level_1                            as region_level_1
  ,acct_seg.region_level_2                            as region_level_2
  ,acct_seg.region_level_3                            as region_level_3
  ,acct_seg.region_level_4                            as region_level_4
   -- opp
  ,opp.acv_cap                                        as acv_cap
  ,opp.funnel_metric_id                               as funnel_metric_id
  ,opp.funnel_contact_id                              as funnel_contact_id
  ,opp.entry_channel                                  as entry_channel
  ,opp.entry_subchannel                               as entry_subchannel
  ,opp.true_pipeline_creation_date                    as true_pipeline_creation_date
  ,opp.new_arr_type                                   as new_arr_type
  ,opp.company_type_tier_2                            as company_type_tier_2
  ,opp.owner_id                                       as owner_id
  ,opp.owner_name                                     as owner_name
  ,opp.owner_role                                     as owner_role
  ,opp.owner_title                                    as owner_title
  ,opp.manager_name                                   as manager_name
  ,opp.manager_id                                     as manager_id
  ,opp.manager_2_name                                 as manager_2_name
  ,opp.manager_3_name                                 as manager_3_name
  ,opp.manager_4_name                                 as manager_4_name
  ,opp.created_by_id                                  as created_by_id
  ,opp.created_by_name                                as created_by_name
  ,opp.qualified_by_name                              as qualified_by_name
  ,opp.qualified_by_manager_name                      as qualified_by_manager_name
  ,opp.account_executive_id                           as account_executive_id
  ,opp.account_executive_name                         as account_executive_name
  ,opp.opportunity_source                             as opportunity_source
  ,opp.recycle_reason                                 as recycle_reason
  ,opp.reason_for_expansion                           as reason_for_expansion
  ,opp.reason_for_cancellation                        as reason_for_cancellation
  ,opp.zuora_product_bundle                           as zuora_product_bundle
  ,opp.is_cs_created_original_created_by_role         as is_cs_created_original_created_by_role
  ,opp.manager_1_name                                 as manager_1_name
  ,opp.renewal_outcome                                as renewal_outcome
  ,opp.gut                                            as gut
  ,opp.deal_type                                      as deal_type
  ,opp.debook_reason                                  as debook_reason
  ,opp.service_start_date                             as service_start_date
  ,opp.service_end_date                               as service_end_date
  ,opp.execution_plan                                 as execution_plan
  ,opp.account_executive_manager_name                 as sales_manager_name
  ,opp.next_step                                      as next_step
  ,opp.next_step_complete_date                        as next_step_complete_date
  ,opp.renewal_forecast_category_at_close             as renewal_forecast_category_at_close
  ,opp.downgrade_debook_arr                           as downgrade_debook_arr
  ,opp.customer_success_engineer                      as customer_success_engineer
  ,opp.customer_success_engineer_user_id              as customer_success_engineer_user_id
  ,opp.secondary_customer_success_engineer            as secondary_customer_success_engineer
  ,opp.secondary_customer_success_engineer_user_id    as secondary_customer_success_engineer_user_id
  ,opp.st_cso_segment                                 as st_cso_segment
  ,opp.sb_cso_segment                                 as sb_cso_segment
  ,opp.sold_to_segment_1                              as sold_to_segment_1
  ,opp.sold_to_segment_2                              as sold_to_segment_2
  ,opp.sold_to_segment_3                              as sold_to_segment_3
  ,opp.sold_to_segment_4                              as sold_to_segment_4
  ,opp.current_sb_level_1                             as current_sb_level_1
  ,opp.current_sb_level_2                             as current_sb_level_2
  ,opp.current_sb_level_3                             as current_sb_level_3
  ,opp.current_sb_level_4                             as current_sb_level_4
  ,opp.current_sb_cso_segment                         as current_sb_cso_segment
  ,opp.cse_level_1                                    as cse_level_1
  ,opp.cse_level_2                                    as cse_level_2
  ,opp.cse_level_3                                    as cse_level_3
  ,opp.cse_level_4                                    as cse_level_4
  ,opp.cse_cso_segment                                as cse_cso_segment
  ,opp.per_project                                    as per_project
  ,case when datediff('day', opp.service_start_date,
                  last_day(e.engagement_recognition_date, 'quarter')) between -10 and -1
        and e.opportunity_record_type = 'Renewal Process'
        and e.stage_name in ('Closed Won', 'Renewed')
        and e.opportunity_type in ('Downgrade', 'Upgrade')
        then 1 else 0
   end                                                    as pull_in_val
  ,pull_in_val::boolean                                   as is_pull_in
  ,abs(ifnull(e.engagement_book_arr, 0)) * pull_in_val    as pull_in_engagement_book_arr
  ,abs(ifnull(e.churn_and_downgrade_arr,0)) * pull_in_val as pull_in_churn_and_downgrade_arr
  ,abs(ifnull(e.expansion_arr,0)) * pull_in_val           as pull_in_expansion_arr
  ,abs(ifnull(e.net_new_arr,0)) * pull_in_val             as pull_in_net_new_arr

  ,case when opp.service_start_date < e.engagement_recognition_date
        and e.opportunity_record_type = 'Renewal Process'
        then 1 else 0
   end                                                           as lapsed_renewal_val
  ,lapsed_renewal_val::boolean                                   as lapsed_renewal
  ,abs(ifnull(e.engagement_book_arr,0)) * lapsed_renewal_val     as lapsed_book
  ,abs(ifnull(e.churn_and_downgrade_arr,0)) * lapsed_renewal_val as lapsed_churn_and_downgrade_arr
  ,abs(ifnull(e.expansion_arr,0)) * lapsed_renewal_val           as lapsed_expansion_arr
  ,abs(ifnull(e.net_new_arr,0)) * lapsed_renewal_val             as lapsed_net_new_arr
  ,case when lapsed_renewal = TRUE and e.open_or_closed = 'Open'
        then e.engagement_book_arr
        else 0
   end                                                           as open_lapsed_book
  ,opp.planned_arr                                               as planned_arr
  ,case when e.expansion_arr > 0 and opp.planned_arr != 0
        then (e.expansion_arr - opp.planned_arr)
        else e.expansion_arr
   end                                                           as expansion_arr_excluding_planned
  ,opp.influenceable_risk                                        as influenceable_risk
  ,opp.mitigation_update                                         as mitigation_update
  ,can.pending_cancellations                                     as pending_cancellations
  ,case when (e.stage_name not in ('Cancelled',  'Deal Review'))
                and e.opportunity_record_type = 'Renewal Process'
                and e.opportunity_type = 'Cancellation'
        then true else false
   end                                                           as pending_cancellations_flag
  ,case when e.is_interim_planned = true
        then 0
        else opp.cs_risk_forecast
   end                                                           as cs_risk_forecast
  ,case when e.is_interim_planned = true
        then 0
        else opp.churn_at_risk
   end                                                           as churn_at_risk
  ,e.engagement_event_type                                       as engagement_event_type
  ,current_timestamp()                                           as data_as_of
from
  {{ ref('opportunity_engagement_book_prep') }} e
  left join {{ ref('sales_opportunity_detailed') }} opp
    on e.opportunity_id = opp.opportunity_id
  left join {{ ref('sales_account_segmentation') }} acct_seg
    on e.account_id = acct_seg.account_id
  left join {{ ref('master_accounts_prep') }} acct
    on e.account_id = acct.salesforce_account_id
  left join {{ ref('salesforce_account_user_id_reference') }} user_id_reference
    on e.account_id = user_id_reference.account_id
  left join cancellation can
   on e.opportunity_id = can.opportunity_id

where
  opp.stage_name != 'Duplicate'
  order by e.account_id
       , e.opportunity_id
