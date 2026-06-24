# Intervene

**Mental Wellbeing • Anti-Bullying • Awareness, Empathy & Action**
A student-led initiative by **Seher Chauhan** & **Riddhita Sharma** at Prometheus School, Noida.

## What's here

| File | Purpose |
|------|---------|
| `index.html` | The full website — homepage, all feature sections, student dashboard, modals. Self-contained (Tailwind via CDN, no build step). |
| `supabase-schema.sql` | Complete database schema with tables, enums, Row-Level Security, and an auto-profile trigger. |

## Run it

Just open `index.html` in a browser, or serve the folder:

```bash
python3 -m http.server 5173   # then visit http://localhost:5173/intervene/
```

## What's implemented (front-end, working today)

- **Hero** with the three CTAs (Join / Get Support / Become a Volunteer) and diverse-students illustration
- **About** — mission, vision, why-it-matters, animated count-up statistics
- **Features** — Mood Tracker, Safe Space, Therapist Connect, Anti-Bullying Reporting, Resource Hub
- **Therapist directory** (verified badges, book / ask-anonymously)
- **Resource Hub** with live search + topic filter
- **Volunteer** program + application form
- **Events & Campaigns** grid with registration
- **Connect With Us** — animated social cards (Instagram, LinkedIn, YouTube, Facebook, X, Threads, WhatsApp, Discord) + share buttons + newsletter
- **Student Dashboard** — interactive mood tracker (localStorage), canvas mood-trend chart, wellness score, goals, recommendations, community activity, badges
- **Admin Console** (`Admin` in the nav) — Overview with stat cards + charts; review/triage reports with live status changes; full CRUD for resources, events, and **social-media links**; user role management. Edits write to Supabase when signed in as an admin and reflect on the public site.
- **Meet Our Team** section — founders Seher Chauhan & Riddhita Sharma. Save your team photo as `intervene/team.png` (a founders placeholder shows until then).
- **Anti-bullying report modal** — anonymous option, category, evidence upload, tracking ID
- **Aria** — AI wellness assistant (rule-based demo)
- **Emergency support** modal with India helplines (112, Tele-MANAS 14416)
- **Dark mode**, glassmorphism, soft gradients, scroll-reveal animations, `prefers-reduced-motion` respected, mobile responsive, accessible focus states

## Database — LIVE ✅

This site is connected to a real Supabase project. The full schema (all tables + Row-Level Security + auto-profile trigger) has been applied.

- **Project URL:** `https://wzhbujbqvlmujxerthez.supabase.co`
- **Keys:** already pasted into the `SUPABASE_URL` / `SUPABASE_KEY` constants at the top of the script in `index.html`.
- **What persists now:** email sign-up/sign-in, mood check-ins (`moods`), and incident reports (`reports`) write to the database when a user is signed in. RLS keeps each student's moods private, lets anyone file a report (anonymously), and keeps resources/events public-read / admin-write.
- **Content lists** (therapists, resources, events, socials) currently render from front-end seed arrays — point them at `supabase.from('...').select()` to drive them from the DB instead.

`supabase-schema.sql` is kept in the repo as the source-of-truth copy of the migration.

### One manual step to finish Google sign-in

The "Continue with Google" button is wired (`supabase.auth.signInWithOAuth({ provider: 'google' })`), but Google OAuth must be enabled once in the Supabase dashboard (it needs Google Cloud credentials, which only you can create):

1. [Google Cloud Console](https://console.cloud.google.com/) → create an OAuth 2.0 Client ID (Web application).
2. Add this **Authorized redirect URI:** `https://wzhbujbqvlmujxerthez.supabase.co/auth/v1/callback`
3. Supabase dashboard → **Authentication → Providers → Google** → paste the Client ID + Secret, enable.
4. Supabase → **Authentication → URL Configuration** → add your site URL (e.g. `http://localhost:5173`) to redirect allow-list.

Until then, email/password sign-up already works end-to-end.

### Becoming an admin

Admin is **server-enforced via an allowlist** — no one can become admin just by signing up or picking a role. The Admin nav link only appears for allowlisted accounts, and the admin view is gated on the database role.

**Who is admin:** any email in the `admin_allowlist` table. Currently: `shambhavibhardwaj2x@gmail.com`.

**To add another admin** (e.g. a co-founder), run in the Supabase SQL editor:
```sql
insert into public.admin_allowlist(email) values ('newadmin@gmail.com');
update public.profiles set role='admin' where email='newadmin@gmail.com';  -- if they already signed up
```
New users whose email is on the allowlist are made admin automatically on signup (via the `handle_new_user` trigger). A `guard_profile_role` trigger prevents signed-in non-admins from escalating their own role, and the signup trigger ignores any client-supplied `admin` role — so the only path to admin is the allowlist.

Content tables (`resources`, `events`, `social_links`) are seeded, so the public Resource Hub, Events, and Connect pages now load from the database. Public visitors can read them; only admins can write.

## Branding

Purple `#8B5CF6` · Blue `#2563EB` · Teal `#14B8A6` · Coral `#F43F5E` — fonts **Figtree** / **Noto Sans**.
