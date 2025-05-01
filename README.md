# GitHub API Plugin for Fastlane

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-github_api)
[![Gem Version](https://badge.fury.io/rb/fastlane-plugin-github_api.svg)](https://badge.fury.io/rb/fastlane-plugin-github_api)
[![MIT Licensed](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## Table of Contents

- [Overview](#about-github_api)
- [Installation](#getting-started)
- [Available Actions](#available-actions)
  - [Issues](#issues)
  - [Pull Requests](#pull-requests)
  - [Repositories](#repositories)
  - [Reactions](#reactions)
- [Return Values](#return-values)
- [Authentication](#authentication)
- [Example Usage](#example)
- [Development](#run-tests-for-this-plugin)
- [Troubleshooting](#troubleshooting)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-github_api`, add it to your project by running:

```bash
fastlane add_plugin github_api
```

### Requirements

- Ruby 2.5.0 or higher
- Fastlane 2.170.0 or higher

## About github_api

A comprehensive Fastlane plugin for interacting with GitHub's REST APIs. This plugin enables automation of GitHub-related tasks directly from your Fastlane workflows, including managing issues, pull requests, repositories, labels, milestones, and more.

### Key Features

- Full coverage of GitHub REST API endpoints for common operations
- Consistent Ruby-style interface for all GitHub interactions
- Detailed error handling and response parsing
- Shared lane context values for chaining multiple actions
- Comprehensive documentation and examples

## Available Actions

### Issues
- `github_add_assignees`: Add assignees to an issue.
- `github_add_labels`: Add labels to an issue.
- `github_create_issue`: Create a new issue.
- `github_create_issue_comment_reaction`: Create a reaction for an issue comment.
- `github_create_issue_reaction`: Create a reaction for an issue.
- `github_delete_issue_comment`: Delete an issue comment.
- `github_delete_issue_comment_reaction`: Delete a reaction from an issue comment.
- `github_delete_issue_reaction`: Delete a reaction from an issue.
- `github_get_issue`: Get a single issue.
- `github_get_issue_comment`: Get a single issue comment.
- `github_get_issue_event`: Get a single issue event.
- `github_get_issue_timeline`: List events for an issue timeline.
- `github_list_issue_comment_reactions`: List reactions for an issue comment.
- `github_list_issue_comments`: List comments on an issue.
- `github_list_issue_labels`: List labels on an issue.
- `github_list_issue_reactions`: List reactions for an issue.
- `github_list_issues`: List issues in a repository.
- `github_lock_issue`: Lock an issue.
- `github_remove_all_labels`: Remove all labels from an issue.
- `github_remove_assignees`: Remove assignees from an issue.
- `github_remove_label`: Remove a label from an issue.
- `github_set_labels`: Set labels for an issue.
- `github_unlock_issue`: Unlock an issue.
- `github_update_issue`: Update an issue.
- `github_update_issue_comment`: Update an issue comment.

### Pull Requests
- `github_check_pull_merged`: Check if a pull request has been merged.
- `github_create_pull`: Create a pull request.
- `github_create_pull_comment`: Create a review comment for a pull request.
- `github_create_pull_comment_reaction`: Create a reaction for a pull request review comment.
- `github_create_pull_review`: Create a review for a pull request.
- `github_delete_pull_comment`: Delete a pull request review comment.
- `github_delete_pull_comment_reaction`: Delete a reaction from a pull request review comment.
- `github_dismiss_pull_review`: Dismiss a pull request review.
- `github_get_pull`: Get a single pull request.
- `github_get_pull_comment`: Get a single pull request review comment.
- `github_get_pull_review`: Get a single pull request review.
- `github_get_pull_review_comments`: List comments for a pull request review.
- `github_list_all_pull_comments`: List all pull request review comments in a repository.
- `github_list_pull_comment_reactions`: List reactions for a pull request review comment.
- `github_list_pull_comments`: List review comments on a pull request.
- `github_list_pull_commits`: List commits on a pull request.
- `github_list_pull_files`: List files on a pull request.
- `github_list_pull_reviewers`: List requested reviewers for a pull request.
- `github_list_pull_reviews`: List reviews on a pull request.
- `github_list_pulls`: List pull requests in a repository.
- `github_merge_pull`: Merge a pull request.
- `github_request_pull_review`: Request reviewers for a pull request.
- `github_remove_pull_reviewers`: Remove requested reviewers from a pull request.
- `github_submit_pull_review`: Submit a review for a pull request.
- `github_update_pull`: Update a pull request.
- `github_update_pull_branch`: Update a pull request branch.
- `github_update_pull_comment`: Update a pull request review comment.
- `github_update_pull_review`: Update a pull request review.

### Repositories
- `github_create_repository`: Create a new repository.
- `github_delete_repository`: Delete a repository.
- `github_list_repo_labels`: List labels for a repository.
- `github_list_repo_issue_events`: List issue events for a repository.
- `github_list_milestones`: List milestones for a repository.
- `github_create_label`: Create a label.
- `github_update_label`: Update a label.
- `github_delete_label`: Delete a label.
- `github_create_milestone`: Create a milestone.
- `github_update_milestone`: Update a milestone.
- `github_delete_milestone`: Delete a milestone.

### Reactions
- `github_create_commit_comment_reaction`: Create a reaction for a commit comment.
- `github_delete_commit_comment_reaction`: Delete a reaction from a commit comment.
- `github_list_commit_comment_reactions`: List reactions for a commit comment.

## Return Values

All actions return a hash with the following keys:
- `:status` - The HTTP status code
- `:body` - The raw response body
- `:json` - Parsed JSON response (if applicable)

Most actions also set shared lane context values that can be accessed in subsequent steps:

```ruby
result = github_create_issue(...)
puts "Issue number: #{Actions.lane_context[SharedValues::GITHUB_CREATE_ISSUE_JSON]['number']}"
```

## Authentication

All actions require GitHub authentication via a Personal Access Token:

```ruby
ENV["GITHUB_API_TOKEN"] = "your-token-here" # Set in your environment

# Or pass directly to actions
github_create_issue(
  api_token: "your-token-token",
  # other parameters...
)
```

You can create a GitHub Personal Access Token at https://github.com/settings/tokens.

### Token Permissions

For most operations, your token will need the following scopes:
- `repo` - Full control of private repositories
- `admin:org` - For organization-related operations
- `user` - For user-related operations

For specific operations, refer to [GitHub's documentation on token scopes](https://docs.github.com/en/developers/apps/scopes-for-oauth-apps).

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

### Sample Usage

```ruby
# In your Fastfile
lane :create_release_issue do
  github_create_issue(
    repo_owner: "your-username",
    repo_name: "your-repo",
    title: "Release version #{lane_context[SharedValues::VERSION_NUMBER]}",
    body: "Please review the following changes for this release...",
    labels: ["release", "needs-review"]
  )
end

lane :submit_pr_review do
  github_submit_pull_review(
    repo_owner: "your-username",
    repo_name: "your-repo",
    pull_number: 42,
    event: "APPROVE",
    body: "LGTM! :rocket:"
  )
end
```

## Run tests for this plugin

To run both the tests, and code style validation, run:

```
rake
```

To automatically fix many of the styling issues, use:
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Common Issues

### Authentication Problems
- Make sure your GitHub token has the correct permissions
- Check that your token is valid and not expired
- Verify the token is correctly set as an environment variable or passed to the action

### Rate Limiting
- GitHub API has rate limits that might affect high-frequency usage
- Consider implementing retry logic or rate limit handling

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).

## All Available Actions: Detailed Usage

### Issues

#### `github_add_assignees`
Add one or more assignees to a GitHub issue.

```ruby
github_add_assignees(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  issue_number: 42,
  assignees: ["octocat", "hubot"]
)
```

#### `github_add_labels`
Add one or more labels to a GitHub issue.

```ruby
github_add_labels(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  issue_number: 42,
  labels: ["bug", "help wanted"]
)
```
