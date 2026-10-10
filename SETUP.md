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

## 2b. IMPORTANT for students in mainland China (do this before launch)
- **Download the Supabase library and host it yourself.** Open
  https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js , save the page as
  `supabase.js`, and upload it next to your other files. Every page loads this local copy first and
  only falls back to a public CDN, which may be slow or blocked in China.
- **Test from inside China.** Ask a friend or student in mainland China to open your site and
  create a student account on their phone, on mobile data and on home wifi. I could not verify that
  Supabase's servers are reliably reachable from China. If sign-up fails or is very slow there,
  student accounts will need a different backend (for example one hosted in China).
- **Set up real email sending.** Supabase's built-in email sender is only meant for testing: it is
  heavily rate-limited, and verification emails often don't reach QQ / 163 / 126 mailboxes. Before
  launch, connect your own email service (Supabase → Authentication → SMTP Settings) and test with a
  QQ and a 163 address. If students can't receive the verification email, they can't register.
- Google Fonts were removed from every page (Google is blocked in China and can stall page loading);
  the site uses each device's built-in fonts instead.

## 3. Make yourself an admin
Create a normal volunteer account on your site first, then in the SQL Editor run:
    update profiles set is_admin = true
    where id = (select id from auth.users where email = 'YOUR-EMAIL');
Then open `admin.html` (a link also appears on your dashboard).

## 4. Before you launch — please review
- `orientation.html` contains DRAFT safety/boundary/reporting text. Replace anything that doesn't
  match your organization's real policies. This matters most because students may be minors.
- Students are often minors. The student registration collects a date of birth and, for anyone
  under 18, a guardian's name and email plus a consent tick-box. A tick-box is NOT verified
  consent — the admin page reminds you to confirm with the guardian by email before approving a
  minor. Get advice on what China's rules on children's personal information (and any rules where
  your volunteers live) require of you.
- Consider having legal/child-safeguarding advice on background checks and data privacy
  (you'll be storing applicants' personal info, birthdates, and voice recordings).
- Test the whole flow once yourself: sign up → verify → application → assessments → orientation →
  submit → approve in admin.

## What's real vs. not yet built
Real (volunteers AND students, each with their own pipeline): signup, email verification, application wizard, English + Chinese assessments (auto-scored
multiple choice + listening, plus writing and voice recordings for human review), orientation quiz,
availability, submit, admin review/approve/reject/retake, security guards.
Not yet built: matching students with volunteers (an admin can see both sides but there is no match screen yet), automatic emails (status changes only appear on the dashboard), server-side
grading, student matching, lesson scheduling, real hours tracking/certificates, application
history log, profile photo upload.
