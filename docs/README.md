# Holdfast Project Website

This directory contains the GitHub Pages site for the Holdfast project.

## Setup

To enable GitHub Pages deployment:

1. Go to your repository settings on GitHub
2. Navigate to **Settings** → **Pages**
3. Under **Build and deployment**:
   - Source: Select **GitHub Actions**
4. The site will automatically deploy on every push to `main`

## Local Development

To preview the site locally, simply open `index.html` in your browser:

```bash
cd docs
open index.html  # macOS
# or
xdg-open index.html  # Linux
# or just double-click the file
```

## Deployment

The site is automatically deployed via GitHub Actions workflow (`.github/workflows/deploy-pages.yml`) on every push to the `main` branch.

The live site will be available at: `https://varex83.github.io/holdfast/`

## Manual Deployment

You can also trigger a manual deployment:

1. Go to **Actions** tab in your GitHub repository
2. Select **Deploy to GitHub Pages** workflow
3. Click **Run workflow**
