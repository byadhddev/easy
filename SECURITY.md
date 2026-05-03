# Secrets & Security Guide

This document explains how to keep secrets out of the repository and how developers should manage local and CI secrets for the `unstuck` project.

Summary of actions already taken
- The hardcoded `GEMINI_API_KEY` was removed from the shared Xcode scheme (`xcshareddata/xcschemes/unstuck.xcscheme`).
- You mentioned the key has already been rotated — good. Treat the rotated key as active and the old key as revoked.

Local developer setup (recommended)
1. Create a local `Secrets.xcconfig` from the provided template and DO NOT commit it:

```sh
cp Secrets.xcconfig.template Secrets.xcconfig
# edit Secrets.xcconfig and paste your real keys
```

2. `Secrets.xcconfig` is ignored by `.gitignore` (the repo already ignores `*.xcconfig`). Xcode build configurations can be pointed to this file so the values are available at build time.

3. Alternatively, set environment variables for GUI Xcode using `launchctl` (useful for `ProcessInfo.processInfo.environment`):

```sh
launchctl setenv GEMINI_API_KEY "your_real_key_here"
# Restart Xcode (or log out/in) so the GUI picks up the env var
```

To remove the var:

```sh
launchctl unsetenv GEMINI_API_KEY
```

Reading secrets in-app
- From build-time `.xcconfig` (via Info.plist or custom mechanism):
  - Use `$(GEMINI_API_KEY)` in Info.plist and read with `Bundle.main.object(forInfoDictionaryKey:)`.
- From runtime environment (if using `launchctl` or CI env injection):
  - `let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]`
- For sensitive tokens you receive at runtime, store them in Keychain (KeychainAccess or custom wrapper).

Xcode user-scheme vs shared-scheme
- Do not put environment variables into shared schemes. Use a user-scoped scheme (uncheck “Shared” in scheme editor) so settings live under `xcuserdata/` and are not committed.

CI and distribution
- Store secrets in your CI system:
  - GitHub Actions: use repository or organization Secrets and inject at build time.
  - Bitrise/GitLab/CI: use their environment-secret features.
  - Xcode Cloud: use its secure variables for builds.
- Do not commit secrets into the repo or shared scheme. Only inject them at build time on CI or at runtime on your backend.

Purge secret from git history (destructive — read carefully)
If a secret was committed into the repository, rewriting history is required to remove it from earlier commits. This rewrites commit history and requires a forced push and coordination with your team.

Recommended process (backup first):

1. Create a mirror backup of the repo (just in case):

```sh
git clone --mirror git@github.com:your-org/your-repo.git backup-repo.git
```

2a. Using `git filter-repo` (recommended):

Install: `brew install git-filter-repo` or follow upstream docs.

```sh
# run from repo root
git filter-repo --invert-paths --path-glob 'unstuck.xcodeproj/xcshareddata/xcschemes/unstuck.xcscheme' \
    --replace-text <(echo "[REMOVED_GEMINI_API_KEY]==>>")
```

`git-filter-repo` supports many options; see its docs. The safe pattern is to remove files or replace strings. Replace the above command with the exact pattern you need to remove.

2b. Using BFG (simpler for removing secrets by string):

Install: `brew install bfg` or download jar.

```sh
# create a mirror clone
git clone --mirror git@github.com:your-org/your-repo.git
cd your-repo.git
# remove the secret string
bfg --replace-text <(printf '[REMOVED_GEMINI_API_KEY]==')
git reflog expire --expire=now --all && git gc --prune=now --aggressive
git push --force
```

Important notes when rewriting history
- Coordinate with all contributors — they must re-clone or reset their local clones after a force-push.
- Back up the repo first.
- A history rewrite will change commit SHAs; open PRs may break and will need re-creating or rebasing.

If you want, I can run the purge locally now (I will create a mirror backup and show the commands I will run). Tell me if you prefer `git-filter-repo` or `bfg` and confirm you want me to proceed.

Further hardening recommendations
- Keep secrets on the server and issue short-lived tokens to the app.
- Use Keychain for runtime tokens and consider biometrics gating for highly sensitive data.
- Run static analysis and secret scanners (e.g., `gitleaks`) in CI to avoid future leaks.

Questions or next steps
- Confirm whether you want me to proceed with the git-history purge now and which tool to use (`git-filter-repo` recommended).
- I can also add a short `DEV_SECRETS.md` or update README with developer checklist if you prefer a different file name.
