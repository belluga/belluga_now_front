# System Roadmap

This document outlines the planned future features and architectural initiatives for the Belluga Now application.

---

## Core Application Features

-   **Phase 6: User Personalization - Favorites:**
    -   Implement the ability for users to mark POIs and events as favorites.
    -   Requires integration with user authentication.

-   **Phase 6.1: Remote User Onboarding:**
    -   **Concept:** For users accessing the app from outside a defined "in city" area, provide a tailored experience for potential visitors.
    -   **Implementation Details:**
        -   The "in city" area will be defined by a configurable geopoint and radius from tenant settings, not hardcoded to a specific city.
        -   Instead of navigating to the user's location, the map will default to the city's initial point.
        -   The UI should prioritize showing hosting options (e.g., hotels).
        -   Trigger backend events to log "potential visitor" interactions for future automations.

-   **Phase 7: Offline Capabilities:**
    -   **Concept:** Enhance app reliability and user experience in areas with poor connectivity.
    -   **Implementation Details:**
        -   Implement a "forever cache" strategy for map tiles from the chosen map service.
        -   The cache duration will be long-term (e.g., a week or a month) to minimize data usage and dependency on the map server for repeat users.

-   **Gamification:**
    -   **Concept:** Increase user engagement and community building through a rewards and recognition system.
    -   **Implementation Details:**
        -   **Invite Ranking:** A system to rank users based on the number of confirmed invites they have sent.
        -   **Partner-Specific Rankings:** Each partner (restaurant, musician, etc.) can see their own leaderboard of top "inviters."
        -   **Custom Ranking Names:** Partners can create custom names for their top ranks (e.g., "Anfitrião," "Super Fã").
-   **Phase 9: Invite Flow & Gamification:**
    -   Implement the full logic for the "Tinder-like" invite screen.
    -   Implement the "Invite Friends" feature (in-app and WhatsApp).
    -   Build out the gamification features (rankings, badges).

-   **Phase X: Invite Status & Privacy Controls (v1.1):**
    -   **Concept:** Allow users to see the status of invites they have sent, while respecting the privacy of the invitees.
    -   **UI Implementation:**
        -   On the event card in "My Schedule," display a small widget with an avatar roll of invited friends.
        -   Each avatar will have a color halo representing the invite status (e.g., pending, accepted, declined).
        -   Tapping this widget will open a modal bottom sheet/dialog with a detailed list of all invite statuses for that event.
    -   **Privacy Implementation:**
        -   A global privacy setting will allow users to control whether others can see their invite status.
        -   The backend will check this setting before revealing an invitee's status to the inviter.

-   **Phase 10: Home Screen & Global Data Integration:**

-   **Landlord (Partner) Module:**
    -   A dedicated module for business partners to manage their POIs, create and manage events, activate and manage offers/promotions, and potentially view analytics.

-   **User Profile & Settings:**
    -   Standard app features for managing user accounts, preferences, and privacy.

-   **Global Search:**
    -   A search functionality that extends beyond just the map, allowing users to find POIs, events, or even artists across the entire application.

-   **Notifications:**
    -   Implement push notifications for events, offers, or personalized updates.
