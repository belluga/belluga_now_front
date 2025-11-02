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
        -   **Badges:** Users can earn gamification badges for achieving milestones, both for specific partners (e.g., "Top Fan of [Restaurant]") and across the app (e.g., "Invited friends to 10 different partners").

-   **Landlord (Partner) Module:**
    -   A dedicated module for business partners to manage their POIs, create and manage events, activate and manage offers/promotions, and potentially view analytics.

-   **User Profile & Settings:**
    -   Standard app features for managing user accounts, preferences, and privacy.

-   **Global Search:**
    -   A search functionality that extends beyond just the map, allowing users to find POIs, events, or even artists across the entire application.

-   **Notifications:**
    -   Implement push notifications for events, offers, or personalized updates.
