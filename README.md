# Ikimina Savings & Loan — free, self-hosted version

Two static pages plus a database schema. No server code, no build step,
no paid tier of anything.

- `index.html` — the public home page
- `ledger.html` — the app: logins, dashboards, savings, loans, earnings
- `schema.sql` — run once in Supabase to create the database

## 1. Create a free Supabase project (the database)

1. Go to supabase.com and sign up (free, no card needed).
2. Click **New project**. Pick any name and password, choose the region
   closest to you, and wait about a minute for it to spin up.
3. In the left sidebar, open **SQL Editor** → **New query**.
4. Paste in the entire contents of `schema.sql` from this folder and
   click **Run**. This creates every table the ledger needs.
5. Go to **Project Settings** → **API**. You'll need two values from
   this page in a moment: the **Project URL** and the **anon public**
   key (not the `service_role` key — never put that one in a browser
   page).

## 2. Connect the ledger to your database

Open `ledger.html` in a text editor (or VS Code) and find this block
near the top:

```html
<script>
window.SUPABASE_URL = "https://YOUR-PROJECT.supabase.co";
window.SUPABASE_ANON_KEY = "YOUR-ANON-PUBLIC-KEY";
</script>
```

Replace both placeholder strings with the Project URL and anon key
from step 1.5, save the file.

## 3. Try it locally

Open `index.html` in a browser (or use VS Code's Live Server — see the
earlier instructions). Click **Sign in**, and you should land on a
"Load the contribution book" screen. Click it once to seed your eight
members, their savings, and their existing loans. From then on the
data lives in Supabase, not in the page.

## 4. Put it online for free

Any static host works, since there's no server code. GitHub Pages
(steps below) or Netlify's drag-and-drop deploy are both free and
take a few minutes.

**GitHub Pages:**
1. Create a new **public** GitHub repository.
2. Push these three files (and this README) to it.
3. In the repo, go to **Settings → Pages**, set Source to "Deploy from
   a branch", branch `main`, folder `/ (root)`, then Save.
4. Your site is live at `https://YOUR-USERNAME.github.io/REPO-NAME/`
   within a minute or two.

## About security

The anon key is meant to be public — it's designed to sit in
browser-side code like this. What actually protects your group's data
is the **Row Level Security** policy in `schema.sql`, plus the fact
that only people you give the link to will ever open the page. This
is the same trust model as a shared spreadsheet: fine for a known
group of members, not a substitute for real access control if this
ever needs to serve the general public. If that changes, the next
step is adding Supabase Auth and tightening the policies in
`schema.sql` so each person can only write their own rows.

## Costs, honestly

Supabase's free tier includes a database, real-time sync, and 500MB
of storage — enough for many years of one group's savings and loan
records. GitHub Pages is free with no bandwidth limit for a normal
site. Nothing here requires a credit card. If your group ever grows
into needing more than the free tier offers, Supabase's paid plan
starts at $25/month — but an eight-member group is nowhere near that.
