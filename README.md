# Sebenza Clocking System

A digital employee attendance and working-hours management system developed for **Umzamo Analytical Services (UAS)**.

Sebenza replaces manual attendance registers with a digital solution that allows employees to clock in and out, track working hours, request overtime, and view attendance records. Supervisors and administrators can manage employees, review requests, monitor attendance, and generate reports.

The system consists of a **Flutter mobile application**, an **ASP.NET Core MVC web application**, and a **Supabase backend**.

## Features

### Mobile Application (Employees)
- Employee login and profile
- Clock-in, clock-out, and break tracking
- Attendance history and late-arrival indicators
- Overtime and attendance correction requests
- Monthly working-hours breakdown
- Payslip summary

### Web Application (Management)
- Dashboard with attendance statistics and charts
- Employee and attendance management
- Overtime approval and rejection
- Attendance correction management
- CSV and PDF report generation
- Administrative audit logs

## Tech Stack

| Component | Technology |
|---|---|
| Mobile Application | Flutter (Dart) |
| Web Application | ASP.NET Core 8 MVC |
| Database | PostgreSQL (Supabase) |
| Authentication | Supabase Auth |
| Frontend | Razor, HTML, CSS, JavaScript |
| Reporting | QuestPDF, CSV |

## Getting Started

### Prerequisites

- Flutter SDK
- .NET 8 SDK
- Android Studio or an Android emulator
- Supabase project with the required database configuration
- Git

### 1. Clone the Repository

```bash
git clone https://github.com/biyasekwanele/sebenza-clocking-system.git
cd sebenza-clocking-system
```

### 2. Run the Mobile Application

Navigate to the Flutter project:

```bash
cd mobile-app
flutter pub get
flutter run
```

Select a connected Android device or emulator when prompted.

The mobile application requires valid Supabase configuration and an employee account.

### 3. Run the Web Application

From the repository root:

```bash
dotnet restore web-app/SebenzaClocking.sln
dotnet run --project web-app/src/SebenzaClocking.Web
```

Open the localhost address displayed in your terminal.

Sign in with a configured supervisor, HR, or administrator account.

Both applications must be connected to the configured Supabase backend.

### 4. Run Tests

**Flutter**

```bash
cd mobile-app
flutter analyze
flutter test
```

**ASP.NET Core**

From the repository root:

```bash
dotnet test web-app/SebenzaClocking.sln
```

Latest verified results:
- Flutter: 11 tests passed
- ASP.NET Core: 9 tests passed
- Flutter analysis: No issues found

## Project Structure

```text
sebenza-clocking-system/
├── docs/                  # Project documentation
├── mobile-app/            # Flutter employee application
│   ├── lib/
│   ├── test/
│   └── pubspec.yaml
├── web-app/               # ASP.NET Core MVC application
│   ├── src/
│   ├── tests/
│   └── SebenzaClocking.sln
├── supabase/              # Backend resources
├── project-management/    # Project management files
└── README.md
```

## Project Status

- [x] Phase 1 — Requirements Analysis
- [x] Phase 2 — System Design
- [x] Phase 3 — Implementation
- [x] Unit Testing

## Contributors

| GitHub | Contribution |
|---|---|
| [biyasekwanele](https://github.com/biyasekwanele) | Backend architecture and integration |
| [PGSekotlo](https://github.com/PGSekotlo) | Mobile login and profile |
| [tshegochoane42-hue](https://github.com/tshegochoane42-hue) | Mobile clock-in and attendance |
| [TshepisoChoeu1004](https://github.com/TshepisoChoeu1004) | Mobile overtime and corrections |
| [stallenbergpedro3](https://github.com/stallenbergpedro3) | Mobile payslip and monthly hours |
| [TakalaniMs](https://github.com/TakalaniMs) | Web dashboard and charts |
| [leratomakhetha](https://github.com/leratomakhetha) | Web employees and attendance |
| [Nkosinathi2002](https://github.com/Nkosinathi2002) | Web overtime and corrections |
| [Thape123](https://github.com/Thape123) | Web reports and audit logs |
| [Selloane646](https://github.com/Selloane646) | Layouts, navigation and styling |

## Project Documentation

Additional documentation is available in the [`docs/`](docs/) directory.
