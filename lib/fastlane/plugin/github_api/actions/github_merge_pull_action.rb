require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_MERGE_PULL_STATUS_CODE = :GITHUB_MERGE_PULL_STATUS_CODE
      GITHUB_MERGE_PULL_RESPONSE = :GITHUB_MERGE_PULL_RESPONSE
      GITHUB_MERGE_PULL_JSON = :GITHUB_MERGE_PULL_JSON
    end

    class GithubMergePullAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          commit_title = params[:commit_title]
          commit_message = params[:commit_message]
          merge_method = params[:merge_method]
          sha = params[:sha]
          
          # Build the body for the request
          body = {}
          body[:commit_title] = commit_title if commit_title
          body[:commit_message] = commit_message if commit_message
          body[:merge_method] = merge_method if merge_method
          body[:sha] = sha if sha
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/merge"
          
          UI.message("Merging pull request ##{pull_number} in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: body,
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
          
          if status_code.between?(200, 299)
            UI.success("Successfully merged pull request ##{pull_number}")
          else
            UI.error("Error merging pull request: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_MERGE_PULL_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_MERGE_PULL_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_MERGE_PULL_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Merge a pull request"
        end
        
        def details
          [
            "Merges a pull request into the base branch.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/pulls#merge-a-pull-request"
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
                                 env_name: "GITHUB_REPO_OWNER",
                              description: "Owner of the repository",
                                 optional: false),
            FastlaneCore::ConfigItem.new(key: :repo_name,
                                 env_name: "GITHUB_REPO_NAME",
                              description: "Name of the repository",
                                 optional: false),
            FastlaneCore::ConfigItem.new(key: :pull_number,
                                 env_name: "GITHUB_PULL_NUMBER",
                              description: "The number of the pull request",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :commit_title,
                                 env_name: "GITHUB_COMMIT_TITLE",
                              description: "Title for the automatic commit message",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :commit_message,
                                 env_name: "GITHUB_COMMIT_MESSAGE",
                              description: "Extra detail to append to automatic commit message",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :merge_method,
                                 env_name: "GITHUB_MERGE_METHOD",
                              description: "Merge method to use: merge, squash, or rebase",
                                 optional: true,
                                     type: String,
                            default_value: "merge",
                             verify_block: proc do |value|
                               UI.user_error!("Merge method must be one of: merge, squash, rebase") unless ['merge', 'squash', 'rebase'].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :sha,
                                 env_name: "GITHUB_SHA",
                              description: "SHA that pull request head must match to allow merge",
                                 optional: true,
                                     type: String)
          ]
        end

        def output
          [
            ['GITHUB_MERGE_PULL_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_MERGE_PULL_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_MERGE_PULL_JSON', 'The parsed JSON response returned by the GitHub API']
          ]
        end

        def return_value
          "Returns a hash containing the status code, response body, and parsed JSON response from the GitHub API."
        end

        def authors
          ["Manish Rathi"]
        end

        def is_supported?(platform)
          true
        end
        
        def example_code
          [
            'github_merge_pull(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42
            )',
            'merged_pull = github_merge_pull(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              commit_title: "Merge pull request #42 from octocat/feature-branch",
              commit_message: "This adds the new feature",
              merge_method: "squash",
              sha: "6dcb09b5b57875f334f61aebed695e2e4193db5e"
            )
            
            message = merged_pull[:json]["message"]
            sha = merged_pull[:json]["sha"]
            puts "Merge commit message: #{message}"
            puts "Merge commit SHA: #{sha}"'
          ]
        end
      end
    end
  end
end
