{{ config(materialized='view', schema='pdp_mart_export_revenue_prep', tags=['daily']) }}

with source as (
select 
  *
from
  {{ source('pdp_mart_export_revenue','opportunity_engagement_book_export') }}
),

renamed as (
select
  account_id                       as account_id,
  opportunity_id                   as opportunity_id,
  opportunity_name                 as opportunity_name,
  account_name                     as account_name,
  opportunity_record_type          as opportunity_record_type,
  opportunity_type                 as opportunity_type,
  stage_name                       as stage_name,
  net_new_arr                      as net_new_arr,
  churn_and_downgrade_arr          as churn_and_downgrade_arr,
  expansion_arr                    as expansion_arr,
  install_base_pipeline            as install_base_pipeline,
  zuora_first_year_value_arr_2     as zuora_first_year_value_arr_2,
  engagement_year_number           as engagement_year_number,
  engagement_book_arr              as engagement_book_arr,
  renewal_book_arr                 as renewal_book_arr,
  engagement_recognition_date      as engagement_recognition_date,
  up_for_renewal_date              as up_for_renewal_date,
  is_multi_year                    as is_multi_year,
  is_engagement_opportunity        as is_engagement_opportunity,
  is_interim_planned               as is_interim_planned,
  open_or_closed                   as open_or_closed,
  attributed_csm_id                as attributed_csm_id,
  customer_success_manager_id      as customer_success_manager_id,
  employee_number                  as employee_number,
  customer_success_manager_name    as customer_success_manager_name,
  csm_manager_name                 as csm_manager_name,
  csm_reporting_role               as csm_reporting_role,
  engagement_event_type            as engagement_event_type
from
  source
)

select
  *,
  current_timestamp() as data_as_of  
from renamed
