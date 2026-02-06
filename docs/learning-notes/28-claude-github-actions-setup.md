# Learning Note 28: Claude GitHub Actions Setup

**Date**: February 5, 2026
**Context**: Setting up Claude GitHub Actions for automated code review and @claude mentions
**Status**: Operational

---

## What Claude GitHub Actions Does

Claude GitHub Actions brings AI-powered automation to your GitHub workflow:

- **@claude mentions**: Tag Claude in any PR or issue comment to get help
- **Automated code review**: Claude automatically reviews PRs when opened
- **Feature implementation**: Ask Claude to implement features from issue descriptions
- **Bug fixes**: Share screenshots or describe bugs and Claude can fix them

---

## What We Installed

Two workflow files in `.github/workflows/`:

### 1. `claude.yml` - Interactive Mentions

Responds to `@claude` mentions in:
- Issue comments
- PR comments
- PR review comments
- Issue descriptions

**Triggers**: `issue_comment`, `pull_request_review_comment`, `issues`, `pull_request_review`

### 2. `claude-code-review.yml` - Automated Code Review

Automatically reviews PRs when they're opened or updated.

**Triggers**: `pull_request` (opened, synchronize)

---

## How to Use @claude Effectively

### Ask Questions
```
@claude What does this function do and how could we improve it?
@claude Explain the architecture of this module
```

### Request Code Changes
```
@claude Can you add error handling to this function?
@claude Refactor this to use async/await
@claude Add unit tests for this service
```

### Code Review
```
@claude Please review this PR and suggest improvements
@claude Check this for security vulnerabilities
```

### Implement Features
```
@claude Implement this feature based on the issue description
@claude Create a new endpoint for user preferences
```

### Fix Bugs
```
@claude Fix the TypeError in the user dashboard component
@claude Here's a screenshot of a bug I'm seeing [attach image]. Can you fix it?
```

---

## Configuration Options

### CLAUDE.md Integration

Claude reads your project's `CLAUDE.md` to understand:
- Code style guidelines
- Review criteria
- Project-specific rules
- Preferred patterns

This is already set up in Forager - Claude will follow the naming conventions (M#.#.#), service layer patterns, and other standards defined in CLAUDE.md.

### Workflow Customization

You can customize behavior via `claude_args` in the workflow files:

```yaml
claude_args: |
  --max-turns 10
  --model claude-sonnet-4-5-20250929
  --allowedTools Edit,Read,Write
  --system-prompt "Focus on security"
```

**Common arguments:**
| Argument | Purpose | Example |
|----------|---------|---------|
| `--max-turns` | Limit conversation rounds | `--max-turns 5` |
| `--model` | Choose Claude model | `--model claude-opus-4-6` |
| `--allowedTools` | Restrict available tools | `--allowedTools Edit,Read,Write` |
| `--disallowedTools` | Block specific tools | `--disallowedTools WebSearch` |

### Custom Prompts

For automation workflows, use the `prompt` parameter:

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    prompt: "/review"  # Use built-in review skill
```

---

## Best Practices

### 1. Be Specific in Requests
```
# Good
@claude Add input validation to the createUser function that checks for valid email format and non-empty username

# Less helpful
@claude Fix the validation
```

### 2. Provide Context
```
@claude This function handles user authentication. Can you add rate limiting to prevent brute force attacks?
```

### 3. Reference Specific Code
```
@claude In src/services/AuthService.swift lines 45-60, can you add error handling for network failures?
```

### 4. Use for Code Review Before Merging
- Let Claude review PRs before human review
- Catches style issues, potential bugs, and missing tests
- Saves reviewer time for higher-level feedback

### 5. Leverage CLAUDE.md
- Keep CLAUDE.md updated with project standards
- Claude will automatically follow these guidelines
- Reduces need to repeat instructions

---

## Authentication Setup

We used `/install-github-app` which:
1. Installed the official Claude GitHub app
2. Generated an OAuth token
3. Added `CLAUDE_CODE_OAUTH_TOKEN` to repository secrets

**Alternative authentication methods:**
- `ANTHROPIC_API_KEY` - Direct API key (for API billing)
- Custom GitHub App - For enterprise/restrictive permissions
- AWS Bedrock / Google Vertex AI - For cloud provider integration

---

## Cost Considerations

### GitHub Actions Minutes
- Workflows run on GitHub-hosted runners
- Consumes GitHub Actions minutes from your plan
- See [GitHub billing docs](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions)

### API Token Usage
- Each Claude interaction consumes API tokens
- Token usage varies by task complexity and codebase size
- OAuth token uses your Claude subscription (Pro/Max)

### Cost Optimization Tips
1. Use `--max-turns` to limit iterations
2. Be specific to reduce unnecessary back-and-forth
3. Set workflow timeouts to prevent runaway jobs
4. Use concurrency controls for parallel runs

---

## Troubleshooting

### Claude Not Responding
1. Verify GitHub App is installed on the repository
2. Check that workflows are enabled (Actions tab)
3. Ensure secrets are configured correctly
4. Confirm comment contains `@claude` (not `/claude`)

### Authentication Errors
1. Verify `CLAUDE_CODE_OAUTH_TOKEN` secret exists
2. Re-run `/install-github-app` if token expired
3. Check Actions tab for detailed error logs

### Permissions Issues
Claude needs these repository permissions:
- **Contents**: Read & Write
- **Issues**: Read & Write
- **Pull requests**: Read & Write

---

## Workflow Examples

### Scheduled Code Quality Check
```yaml
name: Weekly Code Review
on:
  schedule:
    - cron: "0 9 * * 1"  # Every Monday at 9am
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          prompt: "Review the codebase for technical debt and create issues for improvements"
```

### Issue Triage
```yaml
name: Issue Triage
on:
  issues:
    types: [opened]
jobs:
  triage:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
          prompt: "Analyze this issue and add appropriate labels"
```

---

## Resources

- [Claude Code Action Repository](https://github.com/anthropics/claude-code-action)
- [Setup Guide](https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md)
- [Usage Documentation](https://github.com/anthropics/claude-code-action/blob/main/docs/usage.md)
- [Official Docs](https://code.claude.com/docs/en/github-actions)

---

## Key Takeaways

1. **Two workflows installed**: @claude mentions + automated PR review
2. **CLAUDE.md matters**: Claude follows your project standards automatically
3. **Be specific**: Better prompts = better results
4. **Use for pre-review**: Let Claude catch issues before human review
5. **OAuth token**: Using subscription credits, not separate API billing
