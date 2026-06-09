# Docker Hub Setup

To enable the GitHub Actions workflow to push images to Docker Hub, follow these steps:

## 1. Create Docker Hub Access Token

1. Go to https://hub.docker.com/settings/security
2. Click **New Access Token**
3. Give it a descriptive name (e.g., `github-actions-token`)
4. Keep the permissions as default (read/write)
5. Copy the token — you'll use it once

## 2. Add GitHub Secrets

In your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add two secrets:
   - **DOCKERHUB_USERNAME**: Your Docker Hub username
   - **DOCKERHUB_TOKEN**: The access token you created above

## 3. Update Workflow Image Name

Edit `.github/workflows/docker-build.yml` and update the `IMAGE_NAME` if needed:

```yaml
IMAGE_NAME: your-username/token-dashboard
```

## How It Works

The workflow automatically:
- Builds on every push to `main`, `develop`, or version tags
- Tags images with:
  - Branch name (e.g., `main`, `develop`)
  - Git commit SHA (e.g., `main-abc123def`)
  - Semantic version from tags (e.g., `v1.0.0` → `1.0.0`, `1.0`)
  - `latest` tag on main branch
- Caches layers using GitHub Actions cache for faster builds
- Skips push on pull requests (build-only for PRs)

## Verify Push

After pushing code to GitHub, check:
1. **GitHub Actions**: Go to your repo's **Actions** tab to see build logs
2. **Docker Hub**: Your images appear at `hub.docker.com/r/your-username/token-dashboard`

## Pull and Run

Once pushed to Docker Hub:

```bash
docker pull your-username/token-dashboard:latest
docker run -d -p 8080:8080 your-username/token-dashboard:latest
```
