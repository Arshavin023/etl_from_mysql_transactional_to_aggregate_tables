# Aggregate-table-creation-SQL-procesures-&-triggers-and-dashboard design 

In this project, the client wanted an analytics dashboard that displays business metrics in real-time with respect to changes occuring in their online transaction processing (OLTP) sysem, which was built with MySQL relational database.

The following steps were followed to successfully meet the client's needs.

- The client's business requirements and documentation alongside the schema of the database for their online transaction processing (OLTP) system were keenly studied to decode aggregate tables to be created
- Aggregate tables were created and data obtained from the original tables were aggregated and populated into the newly created aggregate tables
- Several queries were run to affirm success of data loading into aggregate tables
- SQL procedures and triggers were created to automate incremental loading of aggregate data from original tables each time INSERT/UPDATE events occurred on the client's database  i.e., customers filed a new application or their status changed from "pending" to "approved"
- A dashboard was created on Google Looker Studio and data in aggregate tables from the client's database was connected as the data source
- The Google Looker Studio was set to refresh the data source every 15 seconds to ensure real-time metrics were reflected 

- [Analytics_Dashboard](https://lookerstudio.google.com/reporting/0ba11fc9-d327-4932-8c10-8f25d8999c02/page/VUACD)
