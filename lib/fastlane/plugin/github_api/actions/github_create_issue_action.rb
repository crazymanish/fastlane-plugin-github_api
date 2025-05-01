require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_CREATE_ISSUE_STATUS_CODE = :GITHUB_CREATE_ISSUE_STATUS_CODE
      GITHUB_CREATE_ISSUE_RESPONSE = :GITHUB_CREATE_ISSUE_RESPONSE
      GITHUB_CREATE_ISSUE_JSON = :GITHUB_CREATE_ISSUE_JSON
    end

    class GithubCreateIssueAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          
          # Validate parameters
          UI.user_error!("No title provided for issue, pass using `title: 'Issue Title'`") if params[:title].to_s.empty?
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/issues"
          
          # Build body parameters
          body_params = {
            title: params[:title],
            body: params[:body]
          }
          
          # Add optional parameters if provided
          body_params[:assignees] = params[:assignees] if params[:assignees]
          body_params[:milestone] = params[:milestone] if params[:milestone]
          body_params[:labels] = params[:labels] if params[:labels]
          
          UI.message("Creating new issue in #{repo_owner}/#{repo_name}: #{params[:title]}")
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
            issue_number = json_response['number']
            UI.success("Successfully created issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          else
            UI.error("Error creating issue: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_CREATE_ISSUE_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_CREATE_ISSUE_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_CREATE_ISSUE_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Creates a new GitHub issue"
        end
        
        def details
          [
            "Creates a new issue in a GitHub repository with the specified title, body, and other optional parameters.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/issues/issues#create-an-issue"
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
                              description: "Repository owner (organization or username)",
                                 optional: false,
                                     type: String,
                              verify_block: proc do |value|
                                UI.user_error!("No repository owner provided, pass using `repo_owner: 'owner'`") if value.to_s.empty?
                              end),
            FastlaneCore::ConfigItem.new(key: :repo_name,
                                 env_name: "GITHUB_API_REPO_NAME",
                              description: "Repository name",
                                 optional: false,
                                     type: String,
                              verify_block: proc do |value|
                                UI.user_error!("No repository name provided, pass using `repo_name: 'name'`") if value.to_s.empty?
                              end),
            FastlaneCore::ConfigItem.new(key: :title,
                              description: "The title of the issue",
                                 optional: false,
                                     type: String,
                              verify_block: proc do |value|
                                UI.user_error!("No title provided, pass using `title: 'Issue Title'`") if value.to_s.empty?
                              end),
            FastlaneCore::ConfigItem.new(key: :body,
                              description: "The body content of the issue",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :assignees,
                              description: "Array of logins for users to assign to the issue",
                                 optional: true,
                                     type: Array),
            FastlaneCore::ConfigItem.new(key: :milestone,
                              description: "The milestone number to associate with this issue",
                                 optional: true,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :labels,
                              description: "Array of labels to associate with this issue",
                                 optional: true,
                                     type: Array)
          ]
        end
        
        def output
          [
            ['GITHUB_CREATE_ISSUE_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_CREATE_ISSUE_RESPONSE', 'The full response body from the GitHub API'],
            ['GITHUB_CREATE_ISSUE_JSON', 'The parsed JSON returned from the GitHub API']
          ]
        end
        
        def return_value
          "A hash including the HTTP status code (:status), the response body (:body), and the parsed JSON (:json)."
        end
        
        def authors
          ["Manish Rathi"]
        end
        
        def example_code
          [
            'github_create_issue(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              title: "New Feature Request",
              body: "Please implement this awesome feature",
              labels: ["enhancement", "feature-request"],
              assignees: ["username1", "username2"]
            )',
            '# You can also access the response data
            result = github_create_issue(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              title: "Bug Report",
              body: "Something is not working"
            )
            UI.message("Created issue number: #{result[:json]["number"]}")'
          ]
        end
        
        def category
          :source_control
        end
        
        def is_supported?(platform)
          true
        end
      end
    end
  end
end