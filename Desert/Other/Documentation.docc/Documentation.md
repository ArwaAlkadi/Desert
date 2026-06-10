# ``Desert``
A safety app for desert and remote trips.

## Overview

Desert is an off-road safety application designed to help users share their trip details with emergency contacts and automatically send alerts when a user exceeds the expected return time without any location updates.

When an alert is triggered, emergency contacts receive a WhatsApp message containing the user's latest known location and a tracking link. The recipient does not need to install the application or create an account to access the shared trip information.

## Technical Journey Documentation
Comprehensive documentation covering research findings, architectural decisions, system design, testing results, security considerations, and major technical decisions made throughout development.

[View Technical Documentation ↗](https://suhail-1.web.app/technical_journey_documentation.pdf)

## Data Storage Strategy

A hybrid storage model was adopted because the application's requirements differ significantly between operational data and safety-critical data.

The application is expected to operate in remote areas where network connectivity may be unavailable for extended periods. For this reason, trip data that must remain continuously available to the user, such as the full route history, is stored locally using SwiftData.

In contrast, data required by backend services and emergency workflows is synchronized to Firestore. This includes trip status, emergency contacts, destination information, and the latest known location.

Separating responsibilities between local and cloud storage reduces network dependency, improves reliability in remote environments, and limits the amount of location data uploaded to the server.

## Terms & Conditions and Privacy Policy
The same Terms & Conditions and Privacy Policy published with the App Store release, covering terms of use, privacy practices, data collection, and user responsibilities.

[View Terms & Conditions and Privacy Policy ↗](https://suhail-1.web.app/privacy.html)

## System Architecture

#### Layered Architecture
![LayeredArchitecture](LayeredArchitecture)
[View Layered Architecture ↗](https://suhail-1.web.app/system-architecture.pdf)

#### UML
![UML](UML)
[View UML ↗](https://suhail-1.web.app/system-architecture.pdf)

#### Backend Journey During a Trip
![BackendJourney](BackendJourney)
[View Backend Journey ↗](https://suhail-1.web.app/system-architecture.pdf)

## Project Repositories (GitHub)

#### iOS Application

[View Repository ↗](https://github.com/ArwaAlkadi/Desert)

#### Website

[View Repository ↗](https://github.com/ArwaAlkadi/DesertWebsite)

#### WhatsApp Server

[View Repository ↗](https://github.com/ArwaAlkadi/SuhailWhatsApp)

## Topics

### App
- ``DesertApp``
- ``AppDelegate``
- ``RootView``

### Models
- ``AppSettings``
- ``SavedInfo``
- ``SavedContact``
- ``Trip``
- ``Contact``
- ``LocationPoint``
- ``UserDefaultsKeys``

### Managers
- ``LocationManager``
- ``NotificationsManager``
- ``FirebaseManager``

### Session
- ``ActiveTripSession``

### Pages
- <doc:AppPages>

### Helpers
- ``NetworkMonitorHelper``
- ``AppPage``
- ``NavigationGestureDisabler``
- ``OnTripStartedKey``

### Design System + Compenents
- <doc:DesignSystem>

### Other
- <doc:Others>
