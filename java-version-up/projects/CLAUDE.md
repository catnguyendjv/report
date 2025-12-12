# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **tool-orchestrator** repository for managing a large-scale backend framework modernization project. It orchestrates work across multiple microservices and libraries, migrating from JDK 1.8/Spring Boot 2.x to JDK 17/Spring Boot 3.

### Directory Structure

- `/work/` - Cloned repositories of libraries and services being migrated (gitignored)
- `/local/` - Temporary test data and analysis data (gitignored)
- `/projects/renew-backend-framework/` - Project documentation for the migration

## The Renew Backend Framework Project

### Goal
Split the monolithic `service-framework` into microservice-oriented libraries and build a new OAuth2 server (`service-security`) based on Spring Boot 3 / JDK 17.

### Architecture

**Before (Legacy)**:
```
service-oauth2-server (old tech stack)
    ↓
service-framework (monolithic shared library)
    ↓
Various services (JDK 1.8, Spring Boot 2.x)
```

**After (Target)**:
```
service-security (JDK 17, Spring Boot 3, Spring Authorization Server)
    ↓
lib-* libraries (separated responsibilities)
├── lib-spring-boot-starter-grpc
├── lib-spring-boot-starter-security
├── lib-spring-boot-starter-mongodb
├── lib-spring-boot-starter-masterdata
├── lib-spring-boot-starter-web
├── lib-common-models
└── lib-common-utils
    ↓
Various services (JDK 17, Spring Boot 3)
```

### Library Dependencies (build order)

Build libraries in this order due to dependencies:
1. `lib-common-utils` - No Spring dependencies, pure utilities
2. `lib-common-models` - Plain DTOs/POJOs with Lombok
3. `lib-spring-boot-starter-mongodb` - MongoDB base functionality
4. `lib-spring-boot-starter-security` - Spring Security 6 base
5. `lib-spring-boot-starter-grpc` - gRPC client/server
6. `lib-spring-boot-starter-web` - Web filters and handlers
7. `lib-spring-boot-starter-masterdata` - Master data management (depends on mongodb)

## Common Commands

### Building lib-* Libraries

```bash
# Build all libraries in order
cd work/lib-common-utils && mvn clean install
cd ../lib-common-models && mvn clean install
cd ../lib-spring-boot-starter-mongodb && mvn clean install
cd ../lib-spring-boot-starter-security && mvn clean install
cd ../lib-spring-boot-starter-grpc && mvn clean install
cd ../lib-spring-boot-starter-web && mvn clean install
cd ../lib-spring-boot-starter-masterdata && mvn clean install

# Build single library
cd work/lib-spring-boot-starter-security
mvn clean install
```

### Building service-security

```bash
cd work/service-security
mvn clean install

# Run with specific profile
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

### Running Tests

```bash
# Run all tests in a project
cd work/service-security
mvn test

# Run single test class
mvn test -Dtest=DrjoyPasswordAuthenticationProviderTest

# Run with coverage
mvn test jacoco:report
```

### Repository Status Check

```bash
# Check git status of all work/ repositories
./work-status.sh
```

## Key Technical Details

### Maven Configuration

- **Group ID**: `jp.drjoy`
- **Framework version property**: `0.1.DEVELOP-SNAPSHOT` (for lib-* in develop branch)
- **protobuf-gen version**: `0.1.DEVELOP-SNAPSHOT`
- **Private Maven repo**: `https://repo.famishare.jp/repository/famishare-repo/`

### Spring Boot 3 Migration Notes

When migrating services from Spring Boot 2.x to 3.x:
- `javax.*` → `jakarta.*` package changes
- `WebSecurityConfigurerAdapter` → `SecurityFilterChain` Bean
- Update gRPC dependencies to `3.1.0.RELEASE` for grpc-spring-boot-starter
- Use `grpc.version: 1.64.0` for io.grpc dependencies

### Branch Conventions

- **Existing services** (`service-admin`, `service-registration`, etc.): Work on `feature/renew_framework`
- **Migration source repos** (`service-oauth2-server`, `service-framework`): Reference `develop` branch
- **New repos** (`lib-*`, `service-security`): Work on `master` branch
- **protobuf**: Work on `feature/renew_framework`

## Project Documentation

| Document | Purpose |
|----------|---------|
| `projects/renew-backend-framework/README.md` | Migration overview and quick start |
| `projects/renew-backend-framework/architecture.md` | Technical architecture design |
| `projects/renew-backend-framework/detailed_plan.md` | Detailed task checklist |
| `projects/renew-backend-framework/service_migration_guide.md` | Service migration procedures |
| `projects/renew-backend-framework/service_migration_checklist.md` | Migration verification checklist |
