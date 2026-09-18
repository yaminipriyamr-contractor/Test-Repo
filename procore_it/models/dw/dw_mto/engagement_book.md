{% docs engagement_book %}

# Engagement Book

## Stakeholders

### Team

- Revenue Insights

### Individual

- Teague Hamilton

## Description

This table is used to track and report on "engagements" for Renewals which are one level deeper than opportunities.  For example--a single renewal opportunity can have "engagements" to be worked on despite not being up for Renewal yet.  These engagement years have been broken out already by the CRI team (at the account/oportunity level) in `account_engagement_book_pdp_arr`.  This model takes that model and adds additional dimensions for reporting, as well as UNION'ining in opps that aren't captured in the CRI table.

As of March 2024, the logic for the metrics and custom dimensions from this model lives upstream in PDP in [opportunity_engagement_book.](https://github.com/procore-it/procore-data-platform/blob/main/dbt/models/pdp_corporate_reporting/dw_revenue/opportunity_engagement_book.sql).  Please only update this to model to add additional basic dimensions (IE: from sales_opportunity).  For updates to the metrics logic itself, please update the source model in PDP.

## Development History

| Type      | Date      | Contributors    | Ticket                                                          | Summary                                                   |
|:---------:|:---------:|:---------------:|:---------------------------------------------------------------:|:---------------------------------------------------------:|
|Created    |11/06/2023 |Zihe Su          |[REV-829](https://procoretech.atlassian.net/browse/REV-829)      |                                                           |
|Modified   |11/15/2023 |Epparla Balaji   |[RBI-1811](https://procoretech.atlassian.net/browse/RBI-1811)    |Added debook_reason field                                  |
|Modified   |12/12/2023 |Epparla Balaji   |[RBI-1828](https://procoretech.atlassian.net/browse/RBI-1828)    |Added new fields                                           |
|Modified   |02/12/2024 |Epparla Balaji   |[RBI-1893](https://procoretech.atlassian.net/browse/RBI-1893)    |Logic added for csm_name and changed source for few fields |
|Modified   |03/26/2024 |Zihe Su          |[REV-920](https://procoretech.atlassian.net/browse/REV-920)      |Point to new PDP source, fix tests                         |
|Modified   |04/19/2024 |Epparla Balaji   |[RBI-1970](https://procoretech.atlassian.net/browse/RBI-1970)    |Added Downgrade_debook_arr                                 |
|Modified   |04/19/2024 |Shristi gupta    |[PDP-13601](https://procoretech.atlassian.net/browse/PDP-13601)  |New fields added                                           |
|Modified   |05/20/2024 |Lea Schlanger    |[PDP-12308](https://procoretech.atlassian.net/browse/PDP-12308)  |Swap sales_account ref to prep model                       |
|Modified   |06/03/2024 |Shristi Gupta    |[PDP-13404](https://procoretech.atlassian.net/browse/PDP-13404)  |Added PLanned_Arr and Expansion_Arr_Excluding_Planned field|
|Modified   |06/22/2024 |Arpan Shah       |[PDP-14883](https://procoretech.atlassian.net/browse/PDP-14883)  |Added the frequency tag - Hourly                           |
|Modified   |06/25/2024 |Epparla Balaji   |[PDP-14725](https://procoretech.atlassian.net/browse/PDP-14725)  |Infleunceable and mitigation fields added                  |
|Modified   |07/26/2024 |Shristi Gupta    |[PDP-15502](https://procoretech.atlassian.net/browse/PDP-15502)  |current manager id added                                   |
|Modified   |09/12/2024 |Shristi Gupta    |[PDP-16379](https://procoretech.atlassian.net/browse/PDP-16379)  |Added pending_cancellations and pending_cancellations_flag |
|Modified   |09/17/2024 |Shristi Gupta    |[PDP-16838](https://procoretech.atlassian.net/browse/PDP-16838)  |Added churn_at_risk and cs_risk_forecast                   |
|Modified   |10/04/2024 |Srija Mokarala   |[PDP-17201](https://procoretech.atlassian.net/browse/PDP-17201)  |Addded Engagment_event_type column                         |
|Modified   |11/25/2024 |Deepak kumar     |[PDP-19352](https://procoretech.atlassian.net/browse/PDP-19352)  |removed data as of tests                                   |
|Modified   |02/13/2025 |Ashvin Kumar     |[PDP-22270](https://procoretech.atlassian.net/browse/PDP-22270)  |Added new fields                                           |
|Modified   |02/28/2025 |Epparla Balaji   |[PDP-22643](https://procoretech.atlassian.net/browse/PDP-22643)  |CSE level fields added                                     |
|Modified   |06/13/2025 |Pierre van Eck   |[PDP-25744](https://procoretech.atlassian.net/browse/PDP-25744)  | Adding x-db-deps                                          |
|Modified   |08/04/2025 |Mark Jurries     |[PDP-26678](https://procoretech.atlassian.net/browse/PDP-26678)  |Added Per Project Field                                    |
|Modified   |12/15/2025 |Arpan Shah       |[PDP-26098](https://procoretech.atlassian.net/browse/PDP-26098)  | Remove QBR Segment Field                                  |
| Modified | 07/13/2026 |  Arpan Shah       |[PDP-28469](https://procoretech.atlassian.net/browse/PDP-28469)  | remove outdated fields from the model|

---
{% enddocs %}
