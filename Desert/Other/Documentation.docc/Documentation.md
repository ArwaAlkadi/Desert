# ``Desert``
A safety app for desert and remote trips.

## Overview
A safety app for desert and remote trips that tracks users, provides a shareable safety card, and automatically sends their last known location to emergency contacts if they don't return on time.

## Data Schema
#### Logical ERD
![LogicalERD](LogicalERD)
[View ERD (Logical/Physical) ↗](#)

#### Physical ERD
![PhysicalERD](PhysicalERD)
[View ERD (Logical/Physical) ↗](#)

#### UML
![UML](UML)
[View UML ↗](#)

## Topics

### App
- ``DesertApp``
- ``AppDelegate``
- ``RootView``

### Managers
- ``TripSessionManager``
- ``LocationManager``
- ``NotificationsManager``
- ``FirebaseManager``

### Models
- ``AppSettings``
- ``SavedInfo``
- ``SavedContact``
- ``Trip``
- ``Contact``
- ``LocationPoint``

### Pages
- <doc:AppPages>

### Shared
- ``TripMapView``
- ``DestinationPickerMapView``
- ``SingleContactPickerView``
- ``MultiContactPickerView``
- ``MaintenanceView``

### Helpers
- ``NetworkMonitorHelper``
- ``AppPage``
- ``NavigationGestureDisabler``
- ``OnTripStartedKey``

### Design System + Compenents
- <doc:DesignSystem>

### Other
- <doc:Others>
