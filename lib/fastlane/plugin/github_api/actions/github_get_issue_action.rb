require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_GET_ISSUE_STATUS_CODE = :GITHUB_GET_ISSUE_STATUS_CODE
      GITHUB_GET_ISSUE_RESPONSE = :GITHUB_GET_ISSUE_RESPONSE
      GITHUB_GET_ISSUE_JSON = :GITHUB_GET_ISSUE_JSON
    end

    class GithubGetIssueAction < Action
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
          
          UI.message("Fetching issue ##{issue_number} from #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            method: :get,
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
            UI.success("Successfully fetched issue ##{issue_number} from #{repo_owner}/#{repo_name}")
          else
            UI.error("Error fetching issue: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_GET_ISSUE_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_GET_ISSUE_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_GET_ISSUE_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Gets a specific GitHub issue by number"
        end
        
        def details
          [
            "Gets a specific issue from a GitHub repository by its issue number.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/issues/issues#get-an-issue"
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
            FastlaneCore::ConfigItem.new(key: :issue_number,
                              description: "The issue number",
                                 optional: false,
                                     type: Integer)
          ]
        end
        
        def output
          [
            ['GITHUB_GET_ISSUE_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_GET_ISSUE_RESPONSE', 'The full response body from the GitHub API'],
            ['GITHUB_GET_ISSUE_JSON', 'The parsed JSON returned from the GitHub API']
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
            'github_get_issue(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123
            )',
            '# You can also access the response data
            result = github_get_issue(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123
            )
            UI.message("Issue title: #{result[:json]["title"]}")
            UI.message("Issue state: #{result[:json]["state"]}")'
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