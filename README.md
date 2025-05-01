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

## Complete Action Reference Guide

This comprehensive reference guide provides detailed usage examples, required parameters, and expected outputs for all actions available in the GitHub API plugin. Use these examples as templates for your own Fastlane workflows.

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

#### `github_create_issue`
Create a new GitHub issue.

```ruby
github_create_issue(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  title: "Found a bug",
  body: "This is a description of the bug.",
  labels: ["bug"],
  assignees: ["octocat"],
  milestone: 1
)
```

#### `github_get_issue`
Get a single GitHub issue.

```ruby
issue = github_get_issue(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  issue_number: 42
)

puts "Issue title: #{issue[:json]['title']}"
puts "Issue state: #{issue[:json]['state']}"
```

#### `github_update_issue`
Update an existing issue.

```ruby
github_update_issue(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  issue_number: 42,
  title: "Updated issue title",
  body: "Updated description",
  state: "closed", # "open" or "closed"
  labels: ["bug", "wontfix"],
  assignees: ["octocat"],
  milestone: 2
)
```

#### `github_list_issues`
List issues in a repository.

```ruby
issues = github_list_issues(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  state: "open", # "open", "closed", or "all"
  sort: "created", # "created", "updated", "comments"
  direction: "desc", # "asc" or "desc"
  since: "2023-01-01T00:00:00Z", # Optional
  labels: "bug,enhancement", # Optional
  assignee: "octocat", # Optional
  creator: "octocat", # Optional
  mentioned: "octocat", # Optional
  milestone: 1 # Optional
)

issues[:json].each do |issue|
  puts "##{issue['number']} - #{issue['title']} (#{issue['state']})"
end
```

#### `github_add_issue_comment`
Add a comment to a GitHub issue.

```ruby
github_add_issue_comment(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  issue_number: 42,
  body: "This is a comment on the issue."
)
```

#### `github_list_issue_comments`
List comments on an issue.

```ruby
comments = github_list_issue_comments(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  issue_number: 42,
  since: "2023-01-01T00:00:00Z" # Optional
)

comments[:json].each do |comment|
  puts "Comment by #{comment['user']['login']}: #{comment['body']}"
end
```

### Pull Requests

#### `github_create_pull`
Create a new pull request.

```ruby
pull = github_create_pull(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  title: "Amazing new feature",
  body: "Please pull these awesome changes in!",
  head: "octocat:feature-branch",
  base: "main",
  draft: false,
  maintainer_can_modify: true
)

puts "Created PR ##{pull[:json]['number']}"
```

#### `github_get_pull`
Get a single pull request.

```ruby
pull = github_get_pull(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  pull_number: 42
)

puts "PR Title: #{pull[:json]['title']}"
puts "Branch: #{pull[:json]['head']['ref']} -> #{pull[:json]['base']['ref']}"
puts "State: #{pull[:json]['state']}"
```

#### `github_update_pull`
Update a pull request.

```ruby
github_update_pull(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  pull_number: 42,
  title: "Updated pull request title",
  body: "Updated description",
  state: "closed", # "open" or "closed"
  base: "main", # Branch to merge changes into
  maintainer_can_modify: true
)
```

#### `github_list_pulls`
List pull requests in a repository.

```ruby
pulls = github_list_pulls(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  state: "open", # "open", "closed", "all"
  head: "octocat:feature", # Optional filter by head branch
  base: "main", # Optional filter by base branch
  sort: "created", # "created", "updated", "popularity", "long-running"
  direction: "desc" # "asc" or "desc"
)

pulls[:json].each do |pull|
  puts "PR ##{pull['number']}: #{pull['title']}"
end
```

#### `github_merge_pull`
Merge a pull request.

```ruby
github_merge_pull(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  pull_number: 42,
  commit_title: "Merge pull request #42", # Optional
  commit_message: "Merge pull request #42 from octocat/feature", # Optional
  merge_method: "merge" # "merge", "squash", or "rebase"
)
```

#### `github_check_pull_merged`
Check if a pull request has been merged.

```ruby
result = github_check_pull_merged(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  pull_number: 42
)

if result[:status] == 204
  UI.success "Pull request has been merged!"
else
  UI.message "Pull request has not been merged."
end
```

#### `github_list_pull_commits`
List commits on a pull request.

```ruby
commits = github_list_pull_commits(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  pull_number: 42
)

commits[:json].each do |commit|
  puts "Commit SHA: #{commit['sha']}"
  puts "Author: #{commit['commit']['author']['name']}"
  puts "Message: #{commit['commit']['message']}"
end
```

#### `github_list_pull_files`
List files on a pull request.

```ruby
files = github_list_pull_files(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  pull_number: 42
)

files[:json].each do |file|
  puts "File: #{file['filename']}"
  puts "Status: #{file['status']}"
  puts "Additions: #{file['additions']}, Deletions: #{file['deletions']}, Changes: #{file['changes']}"
end
```

### Repositories

#### `github_create_repository`
Create a new repository.

```ruby
github_create_repository(
  api_token: "<your_github_token>",
  name: "new-repo",
  description: "This is a new repository",
  private: false,
  has_issues: true,
  has_projects: true,
  has_wiki: true,
  auto_init: true,
  gitignore_template: "Ruby",
  license_template: "mit",
  organization: "octo-org" # Optional, create in organization instead of user account
)
```

#### `github_delete_repository`
Delete a repository.

```ruby
github_delete_repository(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World"
)
```

#### `github_list_repo_labels`
List labels for a repository.

```ruby
labels = github_list_repo_labels(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World"
)

labels[:json].each do |label|
  puts "Label: #{label['name']} (#{label['color']})"
end
```

#### `github_create_label`
Create a label in a repository.

```ruby
github_create_label(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  name: "bug",
  color: "f29513",
  description: "Something isn't working" # Optional
)
```

#### `github_update_label`
Update a label in a repository.

```ruby
github_update_label(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  name: "bug",
  new_name: "confirmed-bug", # Optional, only if changing the name
  color: "b60205",
  description: "Confirmed bugs that need to be fixed"
)
```

#### `github_delete_label`
Delete a label from a repository.

```ruby
github_delete_label(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  name: "wontfix"
)
```

#### `github_list_milestones`
List milestones for a repository.

```ruby
milestones = github_list_milestones(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  state: "open", # "open", "closed", "all"
  sort: "due_on", # "due_on" or "completeness"
  direction: "asc" # "asc" or "desc"
)

milestones[:json].each do |milestone|
  puts "Milestone: #{milestone['title']} (#{milestone['state']})"
  puts "Due on: #{milestone['due_on']}"
end
```

#### `github_create_milestone`
Create a milestone in a repository.

```ruby
github_create_milestone(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  title: "v1.0",
  state: "open", # "open" or "closed"
  description: "Tracking milestone for version 1.0",
  due_on: "2023-12-31T23:59:59Z" # Optional due date
)
```

#### `github_update_milestone`
Update a milestone in a repository.

```ruby
github_update_milestone(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  milestone_number: 1,
  title: "Updated title", # Optional
  state: "closed", # Optional, "open" or "closed"
  description: "Updated description", # Optional
  due_on: "2024-01-31T23:59:59Z" # Optional due date
)
```

#### `github_delete_milestone`
Delete a milestone from a repository.

```ruby
github_delete_milestone(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  milestone_number: 1
)
```

### Reactions

#### `github_create_issue_reaction`
Create a reaction for an issue.

```ruby
github_create_issue_reaction(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  issue_number: 42,
  content: "+1" # Available reactions: +1, -1, laugh, confused, heart, hooray, rocket, eyes
)
```

#### `github_list_issue_reactions`
List reactions for an issue.

```ruby
reactions = github_list_issue_reactions(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  issue_number: 42,
  content: "+1" # Optional filter by reaction type
)

puts "Total reactions: #{reactions[:json].count}"
```

#### `github_delete_issue_reaction`
Delete a reaction from an issue.

```ruby
github_delete_issue_reaction(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  issue_number: 42,
  reaction_id: 12345
)
```

#### `github_create_issue_comment_reaction`
Create a reaction for an issue comment.

```ruby
github_create_issue_comment_reaction(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  comment_id: 123456,
  content: "heart" # Available reactions: +1, -1, laugh, confused, heart, hooray, rocket, eyes
)
```

#### `github_list_issue_comment_reactions`
List reactions for an issue comment.

```ruby
reactions = github_list_issue_comment_reactions(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  comment_id: 123456,
  content: "heart" # Optional filter by reaction type
)

puts "Total reactions: #{reactions[:json].count}"
```

#### `github_delete_issue_comment_reaction`
Delete a reaction from an issue comment.

```ruby
github_delete_issue_comment_reaction(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  comment_id: 123456,
  reaction_id: 12345
)
```

#### `github_create_pull_comment_reaction`
Create a reaction for a pull request review comment.

```ruby
github_create_pull_comment_reaction(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  comment_id: 123456,
  content: "heart" # Available reactions: +1, -1, laugh, confused, heart, hooray, rocket, eyes
)
```

#### `github_list_pull_comment_reactions`
List reactions for a pull request review comment.

```ruby
reactions = github_list_pull_comment_reactions(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  comment_id: 123456,
  content: "heart" # Optional filter by reaction type
)

puts "Total reactions: #{reactions[:json].count}"
```

#### `github_delete_pull_comment_reaction`
Delete a reaction from a pull request review comment.

```ruby
github_delete_pull_comment_reaction(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  comment_id: 123456,
  reaction_id: 12345
)
```

#### `github_create_commit_comment_reaction`
Create a reaction for a commit comment.

```ruby
github_create_commit_comment_reaction(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  comment_id: 123456,
  content: "heart" # Available reactions: +1, -1, laugh, confused, heart, hooray, rocket, eyes
)
```

#### `github_list_commit_comment_reactions`
List reactions for a commit comment.

```ruby
reactions = github_list_commit_comment_reactions(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  comment_id: 123456,
  content: "heart" # Optional filter by reaction type
)

puts "Total reactions: #{reactions[:json].count}"
```

#### `github_delete_commit_comment_reaction`
Delete a reaction from a commit comment.

```ruby
github_delete_commit_comment_reaction(
  api_token: "<your_github_token>",
  repo_owner: "octocat",
  repo_name: "Hello-World",
  comment_id: 123456,
  reaction_id: 12345
)
```
