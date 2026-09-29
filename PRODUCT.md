# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

MAREA serves anyone interested in discovering people, projects, events, businesses, and opportunities in their city. Its primary communities are artists and creators, entrepreneurs, local businesses, brands, and spaces. Administrators moderate and supervise the platform.

## Product Purpose

MAREA connects ideas, talent, businesses, physical spaces, and local opportunities so people can move from discovering a post or mission to making a real collaboration. Success means that a person can recognize relevant work, understand who is behind it, and find a credible next step toward connecting.

## Positioning

MAREA is a social platform for local collaboration and real-world opportunities, not only a traditional feed optimized for likes and followers. Its mechanism joins social discovery with missions, profiles, places, and creative crews.

## Operating Context

People use MAREA to discover posts and profiles, explore missions, present their skills or business, find collaborators, and identify activities or opportunities connected to their city. Profiles may represent a general user, artist/creator, entrepreneur, or business.

## Capabilities and Constraints

The existing Flutter application targets mobile and web from one responsive experience. Current surfaces include authentication, home, explore, posts, missions, profile, settings, creation, and moderation. This design intervention must not change backend, Supabase, models, repositories, services, routes, permissions, or incomplete product behavior. Posts, missions, and explore are visual surfaces only for this pass.

## Brand Commitments

The name MAREA, its official navy/blue/aqua palette, local Nunito Sans fonts, and the idea “La ciudad se convierte en escenario” are binding. The interface should feel social, creative, nearby, and collaborative rather than corporate or administrative.

## Evidence on Hand

Product and design context are documented in `docs/community.md` and `docs/design-system.md`. Existing UI and content are the source of truth for this visual-only pass; no new factual claims or fabricated community content should be introduced.

## Product Principles

- Discovery should make people, ideas, and opportunities legible at a glance.
- Digital interactions should point toward credible local connections.
- A profile is a living introduction to a person, creator, entrepreneur, or business.
- Roles and identity should be visible without making the interface feel permission-driven.
- Responsive behavior should adapt density and navigation to the scene, not merely resize a mobile layout.

## Accessibility & Inclusion

Maintain minimum 48 px touch targets, visible keyboard focus, readable contrast, semantic labels for navigation and icon actions, and layouts that remain usable at narrow mobile widths and wide desktop widths.
