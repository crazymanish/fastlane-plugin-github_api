require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_LIST_PULL_REVIEWERS_STATUS_CODE = :GITHUB_LIST_PULL_REVIEWERS_STATUS_CODE
      GITHUB_LIST_PULL_REVIEWERS_RESPONSE = :GITHUB_LIST_PULL_REVIEWERS_RESPONSE
      GITHUB_LIST_PULL_REVIEWERS_JSON = :GITHUB_LIST_PULL_REVIEWERS_JSON
    end

    class GithubListPullReviewersAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/requested_reviewers"
          
          UI.message("Listing requested reviewers for pull request ##{pull_number} in #{repo_owner}/#{repo_name}")
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
            reviewers_count = 0
            team_reviewers_count = 0
            
            if json_response["users"] && json_response["users"].is_a?(Array)
              reviewers_count = json_response["users"].count
            end
            
            if json_response["teams"] && json_response["teams"].is_a?(Array)
              team_reviewers_count = json_response["teams"].count
            end
            
            UI.success("Successfully listed #{reviewers_count} reviewers and #{team_reviewers_count} team reviewers for pull request ##{pull_number}")
          else
            UI.error("Error listing reviewers: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_LIST_PULL_REVIEWERS_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_LIST_PULL_REVIEWERS_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_LIST_PULL_REVIEWERS_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Lists requested reviewers for a pull request"
        end
        
        def details
          [
            "Lists all requested reviewers for a pull request.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/review-requests#get-all-requested-reviewers-for-a-pull-request"
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
            FastlaneCore::ConfigItem.new(key: :pull_number,
                                 env_name: "GITHUB_PULL_NUMBER",
                              description: "The number of the pull request",
                                 optional: false,
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_LIST_PULL_REVIEWERS_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_LIST_PULL_REVIEWERS_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_LIST_PULL_REVIEWERS_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_list_pull_reviewers(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42
            )',
            'reviewers_info = github_list_pull_reviewers(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42
            )
            
            users = reviewers_info[:json]["users"]
            teams = reviewers_info[:json]["teams"]
            
            puts "Requested reviewers: #{users.map { |u| u["login"] }.join(", ")}"
            puts "Requested team reviewers: #{teams.map { |t| t["name"] }.join(", ")}"'
          ]
        end
      end
    end
  end
end
