# MAREA visual system

<!-- impeccable:design-contract
THESIS: MAREA is a plaza for discovering people, ideas, and local opportunities; navigation stays quiet so the next connection stays visible.
OWN-WORLD: Navy and action blue anchor an airy cool canvas, aqua marks invitations and active creation, and category pastels give social context without turning the product into a dashboard.
STORY: A visitor recognizes what is happening nearby, understands who is behind it, and takes the next social step through a post, profile, or mission.
FIRST VIEWPORT: A responsive shell frames a focused content column; on mobile the bottom navigation leaves the feed open, while on web a compact rail creates breathing room for discovery.
FORM: Social plaza / editorial feed composition, adapted across mobile, tablet, and desktop from the existing Flutter shell; the form favors content rhythm over stacked utility panels.
-->

## Visual language

MAREA uses a bright, breathable canvas (`canvas`) with white content surfaces and a restrained set of identity colors. Brand navy carries headings and identity, action blue carries primary actions, aqua signals creation and connection, and category pastels distinguish context. Borders are quiet and elevation is intentionally minimal so posts, profiles, and missions feel like social artifacts rather than admin records.

Nunito Sans remains the local typeface. Large headings use a compact, confident weight; body copy uses a generous line height and muted secondary text only for supporting context. Rounded surfaces and pill chips keep the interface approachable without making every element look like a floating card.

## Navigation

The five existing destinations remain stable: Inicio, Explorar, Crear, Misiones, and Perfil. Mobile uses a labeled fixed navigation surface with a distinct aqua create action. Tablet uses a compact rail; desktop uses an extended rail with a smaller, content-first label scale. The shell changes density at 600px and 1024px instead of stretching one layout across every viewport.

## Components

- Cards are white, border-led, and elevation-free by default.
- Inputs use white surfaces, large touch-friendly padding, and a large radius with a strong focus border.
- Chips are contextual filters or identity tags, not primary actions.
- Avatars use aqua identity rings and navy text so role and person remain visible on pale surfaces.
- Empty, error, and feedback notices use tinted surfaces and explicit recovery actions.

## Responsive rules

Mobile prioritizes one-column reading and thumb-reachable navigation. Tablet reduces navigation chrome while preserving touch targets. Desktop gives social content a centered maximum width and uses the rail to establish a stable frame. Profile headers can become denser at wide widths, but identity, role, bio, and next action remain in the same reading order.
