require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_CREATE_PULL_STATUS_CODE = :GITHUB_CREATE_PULL_STATUS_CODE
      GITHUB_CREATE_PULL_RESPONSE = :GITHUB_CREATE_PULL_RESPONSE
      GITHUB_CREATE_PULL_JSON = :GITHUB_CREATE_PULL_JSON
    end

    class GithubCreatePullAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          
          # Validate parameters
          UI.user_error!("No title provided for pull request, pass using `title: 'PR Title'`") if params[:title].to_s.empty?
          UI.user_error!("Head branch is required for pull request") if params[:head].to_s.empty?
          UI.user_error!("Base branch is required for pull request") if params[:base].to_s.empty?
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls"
          
          # Build body parameters
          body_params = {
            title: params[:title],
            head: params[:head],
            base: params[:base]
          }
          
          # Add optional parameters if provided
          body_params[:body] = params[:body] if params[:body]
          body_params[:maintainer_can_modify] = params[:maintainer_can_modify] unless params[:maintainer_can_modify].nil?
          body_params[:draft] = params[:draft] unless params[:draft].nil?
          body_params[:issue] = params[:issue] if params[:issue]
          
          UI.message("Creating pull request in #{repo_owner}/#{repo_name}: #{params[:title]}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: body_params,
            method: :post,
            server_url: server_url
          )
          
          status_code = response[:status]
          json_response = response[:json]
          result = {
            status: status_code,
            body: response[:body],
            json: json_response
          }
          
          if status_code.between?(200, 299)
            pr_number = json_response['number']
            UI.success("Successfully created pull request ##{pr_number} in #{repo_owner}/#{repo_name}")
          else
            UI.error("Error creating pull request: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_CREATE_PULL_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_CREATE_PULL_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_CREATE_PULL_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Creates a new pull request in a GitHub repository"
        end
        
        def details
          [
            "Creates a new pull request in a GitHub repository with the specified title, head branch, base branch, and other optional parameters.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/pulls#create-a-pull-request"
          ].join("\n")
        end
        
        def available_options
          [
            FastlaneCore::ConfigItem.new(key: :api_token,
                                 env_name: "GITHUB_API_TOKEN",
                              description: "GitHub API token",
                                 optional: false,
                                sensitive: true,
                       code_gen_sensitive: true,
                            default_value: ENV["GITHUB_API_TOKEN"],
                             verify_block: proc do |value|
                               UI.user_error!("No GitHub API token given, pass using `api_token: 'token'`") if value.to_s.empty?
                             end),
            FastlaneCore::ConfigItem.new(key: :server_url,
                                 env_name: "GITHUB_API_SERVER_URL",
                              description: "GitHub API server URL",
                                 optional: true,
                            default_value: "https://api.github.com"),
            FastlaneCore::ConfigItem.new(key: :repo_owner,
                                 env_name: "GITHUB_API_REPO_OWNER",
                              description: "Owner of the repository",
                                 optional: false),
            FastlaneCore::ConfigItem.new(key: :repo_name,
                                 env_name: "GITHUB_API_REPO_NAME",
                              description: "Name of the repository",
                                 optional: false),
            FastlaneCore::ConfigItem.new(key: :title,
                                 env_name: "GITHUB_API_PR_TITLE",
                              description: "The title of the pull request",
                                 optional: false,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :head,
                                 env_name: "GITHUB_API_PR_HEAD",
                              description: "The name of the branch where your changes are implemented (or user:branch for cross-repo PRs)",
                                 optional: false,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :base,
                                 env_name: "GITHUB_API_PR_BASE",
                              description: "The name of the branch you want the changes pulled into",
                                 optional: false,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :body,
                                 env_name: "GITHUB_API_PR_BODY",
                              description: "The body text content of the pull request",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :maintainer_can_modify,
                                 env_name: "GITHUB_API_PR_MAINTAINER_CAN_MODIFY",
                              description: "Whether maintainers can modify the pull request",
                                 optional: true,
                                     type: Boolean),
            FastlaneCore::ConfigItem.new(key: :draft,
                                 env_name: "GITHUB_API_PR_DRAFT",
                              description: "Whether the pull request is a draft",
                                 optional: true,
                                     type: Boolean),
            FastlaneCore::ConfigItem.new(key: :issue,
                                 env_name: "GITHUB_API_PR_ISSUE",
                              description: "The issue number to convert to a pull request",
                                 optional: true,
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_CREATE_PULL_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_CREATE_PULL_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_CREATE_PULL_JSON', 'The parsed JSON response returned by the GitHub API']
          ]
        end

        def return_value
          "Returns a hash containing the status code, response body, and parsed JSON response from the GitHub API."
        end

        def authors
          ["crazymanish"]
        end

        def is_supported?(platform)
          true
        end
        
        def example_code
          [
            'github_create_pull(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              title: "Amazing new feature",
              head: "feature-branch",
              base: "main",
              body: "Please pull these awesome changes"
            )',
            'github_create_pull(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              title: "Bug fix for issue #42",
              head: "fix-branch",
              base: "main",
              body: "This PR fixes issue #42",
              draft: true
            )'
          ]
        end
      end
    end
  end
end
