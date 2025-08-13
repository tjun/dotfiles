# CLAUDE.md - Global rules

Please provide all answers in Japanese

## Git

 - [IMPORTANT] use git commit with one line simple message, conventional commit style

 ## Terraform

 - Refer Terraform MCP Server to write Terraform codes

## Troubleshooting

### Shell/Command Issues

- **cd command fails with "zsh: command not found: \_\_zoxide_z"**: Use `builtin cd` instead of `cd` to bypass zoxide alias
  ```bash
  # Instead of: cd .git/wts/branch-name
  builtin cd .git/wts/branch-name
  ```
