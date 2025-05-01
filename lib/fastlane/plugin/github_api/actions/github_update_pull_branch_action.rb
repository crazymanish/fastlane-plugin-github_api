require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_UPDATE_PULL_BRANCH_STATUS_CODE = :GITHUB_UPDATE_PULL_BRANCH_STATUS_CODE
      GITHUB_UPDATE_PULL_BRANCH_RESPONSE = :GITHUB_UPDATE_PULL_BRANCH_RESPONSE
      GITHUB_UPDATE_PULL_BRANCH_JSON = :GITHUB_UPDATE_PULL_BRANCH_JSON
    end

    class GithubUpdatePullBranchAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          expected_head_sha = params[:expected_head_sha]
          
          # Build the body for the update request
          body = {}
          body[:expected_head_sha] = expected_head_sha if expected_head_sha
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/update-branch"
          
          UI.message("Updating branch for pull request ##{pull_number} from #{repo_owner}/#{repo_name}")
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
            UI.success("Successfully updated branch for pull request ##{pull_number} from #{repo_owner}/#{repo_name}")
          else
            UI.error("Error updating branch for pull request: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_UPDATE_PULL_BRANCH_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_UPDATE_PULL_BRANCH_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_UPDATE_PULL_BRANCH_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Updates a pull request branch with the latest upstream changes"
        end
        
        def details
          [
            "Updates the pull request branch with the latest upstream changes by merging head from the base branch.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/pulls#update-a-pull-request-branch"
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
            FastlaneCore::ConfigItem.new(key: :expected_head_sha,
                                 env_name: "GITHUB_EXPECTED_HEAD_SHA",
                              description: "The expected SHA of the pull request's HEAD ref",
                                 optional: true,
                                     type: String)
          ]
        end

        def output
          [
            ['GITHUB_UPDATE_PULL_BRANCH_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_UPDATE_PULL_BRANCH_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_UPDATE_PULL_BRANCH_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_update_pull_branch(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42
            )',
            'github_update_pull_branch(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              expected_head_sha: "6dcb09b5b57875f334f61aebed695e2e4193db5e"
            )'
          ]
        end
      end
    end
  end
end
