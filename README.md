# Ikimina Savings & Loan — free, self-hosted version

Two static pages plus a database schema. No server code, no build step,
no paid tier of anything.

- `index.html` — the public home page
- `ledger.html` — the app: logins, dashboards, savings, daily rate contributions, loans, earnings
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
members, their savings, and their existing loans. The sample book includes
October 2026 contributions paid by the 15th except Eric and Charlotte (unpaid)
and Patrick (paid on the 16th), RWF 250 rate payments from Patrick in October
and Chadia in September, and first-month loan-interest-only payments of
RWF 8,100 from Jules and RWF 16,800 from Candide.
On October 17, this means 0 chargeable days for members paid by the 15th,
2 for Eric and Charlotte, and 1 for Patrick.
From then on the data lives in Supabase, not in the page.
An admin can use **Apply recorded book payments** on the dashboard to
reconcile these known October contribution dates, rate payments, and
interest-only repayments in an existing ledger. Matching records are updated
without duplicating them; conflicting October contribution records are flagged
for review instead of overwritten.

The **Rate contributions** page calculates a simple 1% daily penalty on unpaid
monthly contributions starting on the 16th. Amounts paid above the normal
contribution cover that penalty first, then accrued loan interest at the loan's
monthly rate (3% by default) on outstanding principal. Any remaining amount is
carried forward as an interest credit; it does not count toward savings or
reduce loan principal. Officers can use **Edit paid rates** to add or remove
chargeable days manually; each day adjustment also updates the penalty by the
member's current daily penalty.
Loan requests require approval from the President, Vice President, and
Secretary in order. An officer may approve a stage assigned to their current
role; nobody may approve their own loan. Existing accounts with legacy Admin
and Supervisor roles continue to work; Jules maps to President, Chadia to Vice
President, and Supervisor accounts to Secretary.
A President can approve only a request waiting on the President and cannot
approve their own loan. Pending loan rows show why approval is unavailable.
President, Vice President, and Secretary accounts also have a **Reports** page.
Choose a contribution month to review the group summary, member balances,
chargeable days, and loans. Use **Save as PDF** to print or save the report as
PDF, or **Download Excel** to export an Excel-compatible workbook file.

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
