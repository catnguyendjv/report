# tool-orchestrator
A set of tools for system-wide analysis and cross-cutting implementation task management

## Directories

* `/work`: A directory for cloning repositories of libraries and services to be worked on.
* `/local`: A directory for storing temporary test data and analysis data for local use.

Both `/work` and `/local` are added to `.gitignore` for local work.

## projects

The `projects` directory contains documents related to the `renew-backend-framework` project. This is a large-scale refactoring project to modernize the existing OAuth2 server and related frameworks.

This project consists of the following documents:

*   **[Migration Plan (README.md)](./projects/renew-backend-framework/README.md):** Describes the overall picture of the project, basic policies, and a phased migration plan.
*   **[Architecture Design (architecture.md)](./projects/renew-backend-framework/architecture.md):** Defines the technical details of the new architecture, component design, and data migration strategies.
*   **[Detailed Task List (detailed_plan.md)](./projects/renew-backend-framework/detailed_plan.md):** A checklist for managing progress by breaking down the migration plan into specific tasks.
*   **[Estimate (estimate.md)](./projects/renew-backend-framework/estimate.md):** An estimate of the project's effort and duration.
*   **[Gantt Chart (gantt-chart.md)](./projects/renew-backend-framework/gantt-chart.md):** A visualization of the project schedule.

The goal of this project is to split the monolithic `service-framework` into multiple microservice-oriented libraries and build a new OAuth2 server, `service-security`, based on Spring Boot 3 / JDK 17.