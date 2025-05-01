require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_UPDATE_ISSUE_STATUS_CODE = :GITHUB_UPDATE_ISSUE_STATUS_CODE
      GITHUB_UPDATE_ISSUE_RESPONSE = :GITHUB_UPDATE_ISSUE_RESPONSE
      GITHUB_UPDATE_ISSUE_JSON = :GITHUB_UPDATE_ISSUE_JSON
    end

    class GithubUpdateIssueAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          issue_number = params[:issue_number]
          
          # Validate parameters
          UI.user_error!("No GitHub issue number given, pass using `issue_number: 123`") unless issue_number.to_s.length > 0
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/issues/#{issue_number}"
          
          # Build body parameters
          body_params = {}
          body_params[:title] = params[:title] if params[:title]
          body_params[:body] = params[:body] if params[:body]
          body_params[:state] = params[:state] if params[:state]
          body_params[:assignees] = params[:assignees] if params[:assignees]
          body_params[:milestone] = params[:milestone] if params[:milestone]
          body_params[:labels] = params[:labels] if params[:labels]
          
          UI.message("Updating issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: body_params,
            method: :patch,
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
            UI.success("Successfully updated issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          else
            UI.error("Error updating issue: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_UPDATE_ISSUE_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_UPDATE_ISSUE_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_UPDATE_ISSUE_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Updates an existing GitHub issue"
        end
        
        def details
          [
            "Updates an existing issue in a GitHub repository with the specified parameters.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/issues/issues#update-an-issue"
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
                              description: "Repository owner (organization or username)",
                                 optional: false,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :repo_name,
                              description: "Repository name",
                                 optional: false,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :issue_number,
                              description: "The issue number to update",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :title,
                              description: "The title of the issue",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :body,
                              description: "The body content of the issue",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :state,
                              description: "State of the issue (open or closed)",
                                 optional: true,
                                     type: String,
                              verify_block: proc do |value|
                                UI.user_error!("State must be 'open' or 'closed'") unless ['open', 'closed'].include?(value)
                              end),
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
            ['GITHUB_UPDATE_ISSUE_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_UPDATE_ISSUE_RESPONSE', 'The full response body from the GitHub API'],
            ['GITHUB_UPDATE_ISSUE_JSON', 'The parsed JSON returned from the GitHub API']
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
            'github_update_issue(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              title: "Updated Title",
              body: "Updated description",
              state: "closed",
              assignees: ["username1", "username2"],
              labels: ["bug", "enhancement"]
            )',
            '# You can also access the response data
            result = github_update_issue(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              state: "closed"
            )
            UI.message("Updated issue title: #{result[:json]["title"]}")'
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