# Deploying Aviator (Web) to Vercel

This project builds a static Flutter Web app into `build/web`. You can deploy that folder to Vercel.

Steps:

1. Build the web release locally (already done by this automation):

```bash
cd /home/elly/AndroidStudioProjects/aviator
flutter build web --release
```

2. Install Vercel CLI (if not installed):

```bash
npm i -g vercel
# or
# curl -fsSL https://vercel.com/download | bash
```

3. Deploy the `build/web` directory to Vercel:

```bash
# Deploy interactively and link to your Vercel account
vercel --prod build/web

# Or create a project (one-time) and then deploy
vercel deploy --prod --cwd build/web
```

Notes:
- `vercel.json` is included in the repo and configures Vercel to serve static files and route all paths to `index.html` (required for SPA).
- You must authenticate the Vercel CLI with your Vercel account when prompted.
- If you prefer Git-based deployment, push this repo to GitHub and import it into Vercel; set the project's output directory to `build/web` or use a GitHub Action to build then deploy.

If you want, I can: 1) attempt an automated `vercel deploy` here (requires your Vercel login), or 2) create a small GitHub Actions workflow to build and deploy from pushes to `main` (needs a Vercel token secret).
