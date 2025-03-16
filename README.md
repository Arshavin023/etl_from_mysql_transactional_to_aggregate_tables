# ETL Data Pipeline with Stored Procedures and Triggers
## Overview
This repository contains several SQL scripts developed to automated data extraction, transformation and loading from parent/transactional tables to aggregate tables.

# Table of Contents
- [Introduction](#introduction)
- [Steps Followed](#steps_followed)
- [Prerequisites](#prerequisites)
- [Analytics Dashboard](#analytics_dashboard)


## Introduction <a name="introduction"></a>
In this project, the client (Federal Government of Nigeria) wanted an analytics dashboard that displays several metrics that explains import operations and associated import duties/waivers for private business owners. Businesses that were imported goods that encouraged local production e.g., farm machineries were given import waivers and Businesses that imported finished goods weren't given.

## Steps Followed
The following steps were followed to successfully meet the client's needs.

- The client's business requirements and documentation alongside the schema of the database for their online transaction processing (OLTP) system were keenly studied to decode aggregate tables to be created
- Aggregate tables were created and data obtained from the original tables were aggregated and populated into the newly created aggregate tables
- Several queries were run to affirm success of data loading into aggregate tables
- SQL procedures and triggers were created to automate incremental loading of aggregate data from original tables each time INSERT/UPDATE events occurred on the client's database  i.e., customers filed a new application or their status changed from "pending" to "approved"
- A dashboard was created on Google Looker Studio and data in aggregate tables from the client's database was connected as the data source
- The Google Looker Studio was set to refresh the data source every 15 seconds to ensure real-time metrics were reflected 

## Prerequisites <a name="prerequisites"></a>
Before running this report generation process, the following prerequisite must be meant.
- MySQL database 

## Analytics Dashboard
- [Analytics_Dashboard](https://lookerstudio.google.com/reporting/0ba11fc9-d327-4932-8c10-8f25d8999c02/page/VUACD)
