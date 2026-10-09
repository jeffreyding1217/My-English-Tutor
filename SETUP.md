# Bridge to China — setup guide

## 1. Put the site online
Upload every file in this folder to your web host, all in the same folder. `index.html` is the homepage.

## 2. Turn on real accounts (about 10 minutes, free)
1. Create a free project at https://supabase.com
2. Settings → API → copy the **Project URL** and **anon public** key into `auth-config.js`.
3. SQL Editor → New query → paste the ENTIRE contents of `supabase-schema.sql` → Run.
   (This creates the tables, the private voice-recordings storage bucket, and the security
   guards that stop volunteers from approving themselves. Don't skip the guards.)
4. Authentication → Providers → Email → keep **Confirm email ON** if you want real email
   verification (recommended — the application requires it). While testing you can turn it off.
   Authentication → URL Configuration → set Site URL to your website's address so the
   verification link comes back to your site.

## 3. Make yourself an admin
Create a normal volunteer account on your site first, then in the SQL Editor run:
    update profiles set is_admin = true
    where id = (select id from auth.users where email = 'YOUR-EMAIL');
Then open `admin.html` (a link also appears on your dashboard).

## 4. Before you launch — please review
- `orientation.html` contains DRAFT safety/boundary/reporting text. Replace anything that doesn't
  match your organization's real policies. This matters most because students may be minors.
- Consider having legal/child-safeguarding advice on background checks and data privacy
  (you'll be storing applicants' personal info, birthdates, and voice recordings).
- Test the whole flow once yourself: sign up → verify → application → assessments → orientation →
  submit → approve in admin.

## What's real vs. not yet built
Real: signup, email verification, application wizard, English + Chinese assessments (auto-scored
multiple choice + listening, plus writing and voice recordings for human review), orientation quiz,
availability, submit, admin review/approve/reject/retake, security guards.
Not yet built: automatic emails (status changes only appear on the dashboard), server-side
grading, student matching, lesson scheduling, real hours tracking/certificates, application
history log, profile photo upload.
