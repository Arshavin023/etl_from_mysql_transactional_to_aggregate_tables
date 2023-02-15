# Aggregate-table-creation-SQL-procesures-&-triggers-and-dashboard-building-andautomation

In this project, the client wanted an analytics dashboard that displays business metrics in real-time with respect to changes occuring in their online transaction processing (OLTP) sysem, which was built with MySQL relational database.

The following steps were followed to successfully meet the client's needs.

- The client's business requirements and documentation alongside the schema of the MySQL database were keenly studied to decode aggregate tables to be created
- online transactional processing (OLTP) database schema were studied to understand the business uses cases. Aggregate tables were created with SQL queries and new tables were populated with data from the client’s OLTP database. Stored Procedures and Triggers were created and implemented to automate incremental population of data on aggregate tables each time INSERT/UPDATE activities occur on the client’s OLTP database. Finally, aggregate tables were connected to a visualization software to display key business metrics on a dashboard in real-time.
