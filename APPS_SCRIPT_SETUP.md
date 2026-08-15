# Admin dashboard setup (about 5 minutes)

Formspree emails you applications, but it has nowhere for you to click
"approve" and have that stick. To get a real admin dashboard, submissions
need to live in a small database instead of (or alongside) your inbox.
The free tool for this is a Google Sheet + a tiny script Google hosts for
you, called Apps Script. No coding needed on your end, just copy/paste.

## 1. Create the sheet

1. Go to sheets.google.com and create a new blank spreadsheet.
2. Rename the first tab (bottom left) to exactly: `Submissions`
3. In row 1, add these headers, one per column: `ID | Type | Timestamp | Status | Summary | Details`

## 2. Add the script

1. In the sheet, click **Extensions > Apps Script**.
2. Delete anything in the editor and paste in the contents of `admin-backend.gs` (in this same folder).
3. Near the top of the script, change `CHANGE_ME_TO_A_SECRET_PASSCODE` to a passcode only you know. This is what protects your dashboard.
4. Click **Deploy > New deployment**.
5. Click the gear icon next to "Select type" and choose **Web app**.
6. Set "Execute as" to **Me**, and "Who has access" to **Anyone**.
7. Click **Deploy**, and authorize it with your Google account when asked.
8. Copy the **Web app URL** it gives you (ends in `/exec`).

## 3. Connect the site

1. Open `script.js` (or ask me to do it).
2. Find the line near the top: `const ADMIN_ENDPOINT = "PASTE_YOUR_APPS_SCRIPT_URL_HERE";`
3. Replace the placeholder with the Web app URL you copied.
4. Open `admin.html` in your browser and log in with the passcode you set in step 2.3.

That's it. New account creations, exam completions, volunteer applications,
and student registrations will now show up in your admin dashboard with
Approve / Deny / Pending buttons, and the status is saved permanently in
the Google Sheet, so it's the same for you on any device.

## Honest limits of this approach

- The passcode gate is enforced by the script itself (server-side), so it's
  more than just hiding a button, but it is still a single shared password,
  not a real login system with per-user accounts. Don't reuse a password
  you use elsewhere, and don't publicize the admin.html link.
- Apps Script web apps are fine for this volume of traffic (a nonprofit
  intake form) but aren't built for high traffic. If Bridge to China grows
  a lot, this is worth replacing with a proper backend.
- If you'd rather skip this entirely, every submission that went through
  Formspree (volunteer/student/contact forms) is still visible at
  formspree.io under your form's Submissions tab, you just can't mark
  approve/deny there.
