require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_CHECK_PULL_MERGED_STATUS_CODE = :GITHUB_CHECK_PULL_MERGED_STATUS_CODE
      GITHUB_CHECK_PULL_MERGED_RESPONSE = :GITHUB_CHECK_PULL_MERGED_RESPONSE
      GITHUB_PULL_IS_MERGED = :GITHUB_PULL_IS_MERGED
    end

    class GithubCheckPullMergedAction < Action
      class << self
        def run(params)
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/merge"
          
          UI.message("Checking if pull request ##{pull_number} from #{repo_owner}/#{repo_name} is merged")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            method: :get,
            server_url: server_url
          )
          
          status_code = response[:status]
          is_merged = status_code == 204
          result = {
            status: status_code,
            body: response[:body],
            is_merged: is_merged
          }
          
          if is_merged
            UI.success("Pull request ##{pull_number} has been merged")
          elsif status_code == 404
            UI.message("Pull request ##{pull_number} has not been merged")
          else
            UI.error("Error checking if pull request is merged: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_CHECK_PULL_MERGED_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_CHECK_PULL_MERGED_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_PULL_IS_MERGED] = is_merged
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Check if a pull request has been merged"
        end
        
        def details
          [
            "Checks if a pull request has been merged.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/pulls#check-if-a-pull-request-has-been-merged"
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
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_CHECK_PULL_MERGED_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_CHECK_PULL_MERGED_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_PULL_IS_MERGED', 'Boolean indicating whether the pull request has been merged']
          ]
        end

        def return_value
          "Returns a hash containing the status code, response body, and a boolean indicating if the pull request is merged."
        end

        def authors
          ["Manish Rathi"]
        end

        def is_supported?(platform)
          true
        end
        
        def example_code
          [
            'github_check_pull_merged(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42
            )',
            'result = github_check_pull_merged(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42
            )
            
            if result[:is_merged]
              puts "Pull request #42 has been merged!"
            else
              puts "Pull request #42 has not been merged yet."
            end'
          ]
        end
      end
    end
  end
end
