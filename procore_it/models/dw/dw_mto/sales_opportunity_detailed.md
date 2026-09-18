{% docs sales_opportunity_detailed %}

# Sales Opportunity Detailed

## Stakeholders

### Team

- Revenue Insights

### Individual

- Josh Vukovich

## Description

This model takes `sales_opportunity` and joins together key account segment and user details. Together this
creates the main resource for all opportunity based reporting.

## Documents

- [Revenue Data Mart Requirements, Salesforce Opportunity](https://docs.google.com/spreadsheets/d/1KlzKx54jqxnVBfYyJ-nBpR86A8H0N3JsHjzLnzifZoM/edit?pli=1#gid=849430372)

## Development History

|   Type   |    Date    |         Contributors         |                              Ticket                              | Summary                                                      |
| :------: | :--------: | :--------------------------: | :--------------------------------------------------------------: | :----------------------------------------------------------- |
| Created  | 12/01/2019 | Katrina Wise, Bobby Birstock |                                                                  |                                                              |
| Modified | 02/19/2021 |         Katrina Wise         |    [EA-136](https://procoretech.atlassian.net/browse/EA-136)     |                                                              |
| Modified | 03/04/2021 |        Derek Hackett         |    [RA-605](https://procoretech.atlassian.net/browse/RA-605)     |                                                              |
| Modified | 04/05/2021 |        Derek Hackett         |    [RA-639](https://procoretech.atlassian.net/browse/RA-639)     |                                                              |
| Modified | 04/14/2021 |        Bobby Birstock        |   [REV-247](https://procoretech.atlassian.net/browse/REV-247)    |                                                              |
| Modified | 05/17/2021 |       Siva Nagulapati        |    [RA-673](https://procoretech.atlassian.net/browse/REV-673)    |                                                              |
| Modified | 07/08/2021 |       Siva Nagulapati        |   [RBI-681](https://procoretech.atlassian.net/browse/RBI-681)    |                                                              |
| Modified | 07/27/2021 |       Siva Nagulapati        |   [RBI-726](https://procoretech.atlassian.net/browse/RBI-726)    |                                                              |
| Modified | 08/16/2021 |        Pierre van Eck        |   [REV-355](https://procoretech.atlassian.net/browse/REV-355)    |                                                              |
| Modified | 09/01/2021 |       Siva Nagulapati        |   [REV-345](https://procoretech.atlassian.net/browse/REV-345)    |                                                              |
| Modified | 09/20/2021 |       Siva Nagulapati        |   [REV-372](https://procoretech.atlassian.net/browse/REV-372)    |                                                              |
| Modified | 10/07/2021 |        Bobby Birstock        |   [RBI-764](https://procoretech.atlassian.net/browse/RBI-764)    |                                                              |
| Modified | 10/21/2021 |        Pierre van Eck        |   [REV-398](https://procoretech.atlassian.net/browse/REV-398)    |                                                              |
| Modified | 12/10/2021 |       Siva Nagulapati        |   [RBI-880](https://procoretech.atlassian.net/browse/RBI-880)    |                                                              |
| Modified | 12/10/2021 |       Siva Nagulapati        |   [RBI-880](https://procoretech.atlassian.net/browse/RBI-880)    |                                                              |
| Modified | 12/22/2021 |        Pierre van Eck        |   [REV-435](https://procoretech.atlassian.net/browse/REV-435)    |                                                              |
| Modified | 12/15/2021 |        Pierre van Eck        |   [REV-417](https://procoretech.atlassian.net/browse/REV-417)    |                                                              |
| Modified | 12/27/2021 |       Siva Nagulapati        |   [RBI-871](https://procoretech.atlassian.net/browse/RBI-871)    |                                                              |
| Modified | 01/04/2022 |          Arpan Shah          |   [RBI-916](https://procoretech.atlassian.net/browse/RBI-916)    |                                                              |
| Modified | 01/10/2022 |        Pierre van Eck        |   [REV-453](https://procoretech.atlassian.net/browse/REV-453)    |                                                              |
| Modified | 01/18/2022 |        Pierre van Eck        |   [RBI-936](https://procoretech.atlassian.net/browse/RBI-936)    |                                                              |
| Modified | 01/20/2022 |        Pierre van Eck        |   [REV-465](https://procoretech.atlassian.net/browse/REV-465)    |                                                              |
| Modified | 01/26/2022 |          Arpan Shah          |   [RBI-924](https://procoretech.atlassian.net/browse/RBI-924)    |                                                              |
| Modified | 02/15/2022 |        Franny Delaney        |    [EA-975](https://procoretech.atlassian.net/browse/EA-975)     |                                                              |
| Modified | 04/25/2022 |          Arpan Shah          |   [REV-520](https://procoretech.atlassian.net/browse/REV-520)    |                                                              |
| Modified | 08/03/2022 |         Abin Abraham         |  [RBI-1217](https://procoretech.atlassian.net/browse/RBI-1217)   |                                                              |
| Modified | 08/19/2022 |         Abin Abraham         |  [RBI-1283](https://procoretech.atlassian.net/browse/RBI-1283)   |                                                              |
| Modified | 10/04/2022 |         Abin Abraham         |  [RBI-1341](https://procoretech.atlassian.net/browse/RBI-1341)   |                                                              |
| Modified | 01/03/2023 |          Arpan Shah          |   [REV-645](https://procoretech.atlassian.net/browse/REV-645)    |                                                              |
| Modified | 01/11/2023 |        Jonathan Elam         |  [RBI-1290](https://procoretech.atlassian.net/browse/RBI-1290)   |                                                              |
| Modified | 01/14/2023 |         Abin Abraham         |   [REV-627](https://procoretech.atlassian.net/browse/REV-627)    |                                                              |
| Modified | 03/02/2023 |         Deepak Kumar         |  [PDP-5052](https://procoretech.atlassian.net/browse/PDP-5052)   |                                                              |
| Modified | 03/06/2023 |         Abin Abraham         |  [RBI-1549](https://procoretech.atlassian.net/browse/RBI-1549)   |                                                              |
| Modified | 04/24/2023 |          Arpan Shah          |   [REV-731](https://procoretech.atlassian.net/browse/REV-731)    |                                                              |
| Modified | 07/26/2023 |        Epparla Balaji        |  [PDP-7369](https://procoretech.atlassian.net/browse/PDP-7369)   | Added Forecast Ner field                                     |
| Modified | 07/27/2023 |        Epparla Balaji        |  [RBI-1677](https://procoretech.atlassian.net/browse/RBI-1677)   | Added csm manager field                                      |
| Modified | 08/16/2023 |        Epparla Balaji        |  [RBI-1686](https://procoretech.atlassian.net/browse/RBI-1686)   | Added qbr_segment logic                                      |
| Modified | 08/29/2023 |        Epparla Balaji        |  [RBI-1729](https://procoretech.atlassian.net/browse/RBI-1729)   | Added product_interest field                                 |
| Modified | 10/11/2023 |        Epparla Balaji        |   [REV-828](https://procoretech.atlassian.net/browse/REV-828)    | New fields added                                             |
| Modified | 11/02/2023 |        Epparla Balaji        |  [RBI-1789](https://procoretech.atlassian.net/browse/RBI-1789)   | Execution_plan added                                         |
| Modified | 11/07/2023 |           Zihe Su            |   [REV-829](https://procoretech.atlassian.net/browse/REV-829)    | Move CS outcome join in view                                 |
| Modified | 11/13/2023 |        Epparla Balaji        |  [RBI-1809](https://procoretech.atlassian.net/browse/RBI-1809)   | New field Subscription_term added                            |
| Modified | 12/07/2023 |        Epparla Balaji        |  [RBI-1828](https://procoretech.atlassian.net/browse/RBI-1828)   | Added accnt_executive_manager_name                           |
| Modified | 01/05/2024 |        Epparla Balaji        |  [RBI-1830](https://procoretech.atlassian.net/browse/RBI-1830)   | Added renewal_pipeline_dollars field                         |
| Modified | 02/02/2024 |        Epparla Balaji        |  [RBI-1883](https://procoretech.atlassian.net/browse/RBI-1883)   | Updated logic for is_ae_self_sourced_pipeline                |
| Modified | 03/06/2024 |        Pierre van Eck        |   [REV-918](https://procoretech.atlassian.net/browse/REV-918)    | Adding sold to segment                                       |
| Modified | 03/15/2024 |          Arpan Shah          |   [REV-938](https://procoretech.atlassian.net/browse/REV-938)    | Added seg level info                                         |
| Modified | 03/20/2024 |        Epparla Balaji        |  [RBI-1941](https://procoretech.atlassian.net/browse/RBI-1941)   | Renamed Product Interest fields                              |
| Modified | 04/19/2024 |        Epparla Balaji        |  [RBI-1970](https://procoretech.atlassian.net/browse/RBI-1970)   | Added Downgrade_debook_arr                                   |
| Modified | 04/19/2024 |         Sara Bratsch         | [PDP-12965](https://procoretech.atlassian.net/browse/PDP-12965)  | Add x-db-deps                                                |
| Modified | 04/30/2024 |        Shristi Gupta         |  [RBI-1994](https://procoretech.atlassian.net/browse/RBI-1994)   | Added New fields                                             |
| Modified | 05/14/2024 |          Arpan Shah          |   [REV-980](https://procoretech.atlassian.net/browse/REV-980)    | Added cso segment and values                                 |
| Modified | 05/20/2024 |        Lea Schlanger         | [PDP-12308](https://procoretech.atlassian.net/browse/PDP-12308)  | Add engagement_recognition_date                              |
| Modified | 05/23/2024 |        Epparla Balaji        | [PDP-13928](https://procoretech.atlassian.net/browse/PDP-13928)  | Added sb_levels and sb_cso                                   |
| Modified | 06/03/2024 |        Shristi Gupta         | [PDP-13404](https://procoretech.atlassian.net/browse/PDP-13404)  | Expansion_Arr_Excluding_Planned field                        |
| Modified | 06/25/2024 |        Epparla Balaji        | [PDP-14725](https://procoretech.atlassian.net/browse/PDP-14725)  | Infleunceable and mitigation fields added                    |
| Modified | 07/10/2024 |        Epparla Balaji        | [PDP-15089](https://procoretech.atlassian.net/browse/PDP-15089)  | Updated sb_cso_segment logic                                 |
| Modified | 07/17/2024 |          Arpan Shah          |  [REV-1033](https://procoretech.atlassian.net/browse/REV-1033)   | Updated the sb level logic                                   |
| Modified | 07/30/2024 |          Arpan Shah          | [PDP-15651](https://procoretech.atlassian.net/browse/PDP-15651)  | Added opp_upside field                                       |
| Modified | 08/06/2024 |        Epparla Balaji        | [PDP-157015](https://procoretech.atlassian.net/browse/PDP-15701) | current sb_levels and sb_cso_segment fields added            |
| Modified | 08/14/2024 |        Shristi Gupta         | [PDP-15728](https://procoretech.atlassian.net/browse/PDP-15728)  | Added top_account                                            |
| Modified | 09/06/2024 |        Epparla Balaji        | [PDP-16053](https://procoretech.atlassian.net/browse/PDP-16053)  | Account_segment values updated                               |
| Modified | 09/12/2024 |        Shristi Gupta         | [PDP-16379](https://procoretech.atlassian.net/browse/PDP-16379)  | Added pending_cancellations_flag                             |
| Modified | 10/09/2024 |         Abin Abraham         | [PDP-17909](https://procoretech.atlassian.net/browse/PDP-17909)  | Modified qbr_segment field                                   |
| Modified | 12/18/2024 |        Srija mokarala        | [PDP-20701](https://procoretech.atlassian.net/browse/PDP-20701)  | Modified Current SB Level logic                              |
| Modified | 01/03/2025 |        Srija Mokarala        | [PDP-21050](https://procoretech.atlassian.net/browse/PDP-21050)  | Updated logic with opportunity_sold_to_segment_2025 data     |
| Modified | 01/09/2025 |         Abin Abraham         | [PDP-20698](https://procoretech.atlassian.net/browse/PDP-20698)  | Modified Current SB CSO Segment logic                        |
| Modified | 01/16/2025 |        Epparla Balaji        | [PDP-20844](https://procoretech.atlassian.net/browse/PDP-20844)  | Added role user_id fields                                    |
| Modified | 01/30/2025 |         Ashvin Kumar         | [PDP-20453](https://procoretech.atlassian.net/browse/PDP-20453)  | New fields added                                             |
| Modified | 02/20/2025 |          Arpan Shah          |  [REV-1241](https://procoretech.atlassian.net/browse/REV-1241)   | Fixed the logic to match the split model for sb levels       |
| Modified | 02/28/2025 |        Epparla Balaji        | [PDP-22643](https://procoretech.atlassian.net/browse/PDP-22643)  | CSE level fields added                                       |
| Modified | 03/12/2025 |          Arpan Shah          | [PDP-23101](https://procoretech.atlassian.net/browse/PDP-23101)  | CSE levels - Fixed the null for SMB CSE                      |
| Modified | 04/17/2025 |          Arpan Shah          | [PDP-24268](https://procoretech.atlassian.net/browse/PDP-24268)  | Removed the region level joins due to changes in SFDC        |
| Modified | 04/23/2025 |         Kevin Hayes          | [PDP-23949](https://procoretech.atlassian.net/browse/PDP-23949)  | Update for SDFC Gut Field deprecation                        |
| Modified | 04/28/2025 |         Kevin Hayes          | [PDP-24172](https://procoretech.atlassian.net/browse/PDP-24172)  | Resolve Unknown SB Levels for termed employees               |
| Modified | 05/13/2025 |          Arpan Shah          | [PDP-23876](https://procoretech.atlassian.net/browse/PDP-23876)  | Added historical sold to segment fields                      |
| Modified | 05/15/2025 |         Mark Jurries         | [PDP-24796](https://procoretech.atlassian.net/browse/PDP-24796)  | Added new SolSpec fields                                     |
| Modified | 06/04/2025 |          Arpan Shah          | [PDP-25577](https://procoretech.atlassian.net/browse/PDP-25577)  | Refactoring to remove dependency on MDM master account       |
| Modified | 07/23/2025 |         Kevin Hayes          | [PDP-26418](https://procoretech.atlassian.net/browse/PDP-26418)  | Added new SDFC manager forecast override fields              |
| Modified | 08/04/2025 |         Mark Jurries         | [PDP-26678](https://procoretech.atlassian.net/browse/PDP-26678)  | Added Per Project Field                                      |
| Modified | 08/06/2025 |         Mark Jurries         | [PDP-26780](https://procoretech.atlassian.net/browse/PDP-26780)  | Added Forecast Close Field                                   |
| Modified | 09/04/2025 |        Kevin Burnham         | [PDP-26805](https://procoretech.atlassian.net/browse/PDP-26805)  | Added forecast_category_override and manager_forecast fields |
| Modified | 09/08/2025 |        Xander Olivero        | [PDP-27517](https://procoretech.atlassian.net/browse/PDP-27517)  | Added Quote Data                                             |
| Modified | 10/09/2025 |      Mike Thisyamondol       | [PDP-27894](https://procoretech.atlassian.net/browse/PDP-27894)  | Added sales_play dimension                                   |
| Modified | 10/21/2025 |      Mike Thisyamondol       | [PDP-27983](https://procoretech.atlassian.net/browse/PDP-27983)  | Added sales_play_name dimension                              |
| Modified | 11/05/2025 |      Mike Thisyamondol       | [PDP-28060](https://procoretech.atlassian.net/browse/PDP-28060)  | Added is_partner_sourced dimension                           |
| Modified | 12/15/2025 |          Arpan Shah          | [PDP-26098](https://procoretech.atlassian.net/browse/PDP-26098)  | Remove QBR Segment Field                                     |
| Modified | 12/16/2025 |          Arpan Shah          | [PDP-28198](https://procoretech.atlassian.net/browse/PDP-28198)  | Added new fields from sales_notes                            |
| Modified | 01/12/2026 |          Arpan Shah          | [PDP-28118](https://procoretech.atlassian.net/browse/PDP-28118)  | Updated with 2026 Logic                                      |
| Modified | 02/05/2026 |          Arpan Shah          | [PDP-28258](https://procoretech.atlassian.net/browse/PDP-28258)  | Update FY26 sb level logic to get the right values           |
|Modified  | 02/18/2026 |          Arpan Shah          | [PDP-28208](https://procoretech.atlassian.net/browse/PDP-28208)  | Rename SolSpec Dimension Fields                              |
|Modified  | 02/27/2026 |          Andrew Kader        |[PDP-28280](https://procoretech.atlassian.net/browse/PDP-28280)   | Added manager_best_case                                      |
| Modified | 04/30/2026 |        Kevin Burnham         | [BDAH-365](https://procoretech.atlassian.net/browse/BDAH-365)    | Aligned with mdm_sales_opportunity_detailed: added is_reseller, iscancellation, isdebook, split_percentage, de_booked fields |
|Modified  |05/26/2026  |Andrew Kader                  |[PDP-28390](https://procoretech.atlassian.net/browse/PDP-28390)   | Added solutions_close_quarter                                |
| Modified | 07/13/2026 |          Arpan Shah          |[PDP-28469](https://procoretech.atlassian.net/browse/PDP-28469)   | remove outdated fields from the model|
| Modified | 07/16/2026 |         Tina Nguyen          |[PDP-28227](https://procoretech.atlassian.net/browse/PDP-28227)   | Updated Sold to Segment Reference                            |
| Modified | 08/18/2026 |       Anthony Garvey         |[PDP-28538](https://procoretech.atlassian.net/browse/PDP-28538)   | Added ai_arr, ai_deal_score, ai_notes, ai_product fields     |
---

{% enddocs %}