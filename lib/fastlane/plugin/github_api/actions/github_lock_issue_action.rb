require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_LOCK_ISSUE_STATUS_CODE = :GITHUB_LOCK_ISSUE_STATUS_CODE
      GITHUB_LOCK_ISSUE_RESPONSE = :GITHUB_LOCK_ISSUE_RESPONSE
      GITHUB_LOCK_ISSUE_JSON = :GITHUB_LOCK_ISSUE_JSON
    end

    class GithubLockIssueAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          issue_number = params[:issue_number]
          lock_reason = params[:lock_reason]
          
          # Validate parameters
          UI.user_error!("No GitHub issue number given, pass using `issue_number: 123`") unless issue_number.to_s.length > 0
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/issues/#{issue_number}/lock"
          
          # Build body parameters
          body_params = {}
          body_params[:lock_reason] = lock_reason if lock_reason
          
          UI.message("Locking issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: body_params,
            method: :put,
            server_url: server_url
          )
          
          status_code = response[:status]
          json_response = response[:json]
          result = {
            status: status_code,
            body: response[:body],
            json: json_response
          }
          
          if status_code.between?(200, 299) || status_code == 204
            reason_text = lock_reason ? " with reason '#{lock_reason}'" : ""
            UI.success("Successfully locked issue ##{issue_number}#{reason_text}")
          else
            UI.error("Error locking issue: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_LOCK_ISSUE_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_LOCK_ISSUE_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_LOCK_ISSUE_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Locks a GitHub issue"
        end
        
        def details
          [
            "Locks an issue in a GitHub repository, preventing further comments.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/issues/issues#lock-an-issue"
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
                              description: "The issue number to lock",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :lock_reason,
                              description: "The reason for locking the issue (off-topic, too heated, resolved, spam)",
                                 optional: true,
                                     type: String,
                              verify_block: proc do |value|
                                allowed_reasons = ['off-topic', 'too heated', 'resolved', 'spam']
                                UI.user_error!("Lock reason must be one of: #{allowed_reasons.join(', ')}") unless allowed_reasons.include?(value) || value.nil?
                              end)
          ]
        end
        
        def output
          [
            ['GITHUB_LOCK_ISSUE_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_LOCK_ISSUE_RESPONSE', 'The full response body from the GitHub API'],
            ['GITHUB_LOCK_ISSUE_JSON', 'The parsed JSON returned from the GitHub API']
          ]
        end
        
        def return_value
          "A hash including the HTTP status code (:status), the response body (:body), and the parsed JSON (:json)."
        end
        
        def authors
          ["crazymanish"]
        end
        
        def example_code
          [
            'github_lock_issue(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123
            )',
            '# Lock with a reason
            github_lock_issue(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              lock_reason: "resolved"
            )'
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