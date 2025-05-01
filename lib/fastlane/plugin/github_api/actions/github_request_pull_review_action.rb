require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_REQUEST_PULL_REVIEW_STATUS_CODE = :GITHUB_REQUEST_PULL_REVIEW_STATUS_CODE
      GITHUB_REQUEST_PULL_REVIEW_RESPONSE = :GITHUB_REQUEST_PULL_REVIEW_RESPONSE
      GITHUB_REQUEST_PULL_REVIEW_JSON = :GITHUB_REQUEST_PULL_REVIEW_JSON
    end

    class GithubRequestPullReviewAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          reviewers = params[:reviewers]
          team_reviewers = params[:team_reviewers]
          
          # Build the body for the request
          body = {}
          body[:reviewers] = reviewers if reviewers && !reviewers.empty?
          body[:team_reviewers] = team_reviewers if team_reviewers && !team_reviewers.empty?
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/requested_reviewers"
          
          UI.message("Requesting reviewers for pull request ##{pull_number} from #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: body,
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
            reviewer_count = reviewers ? reviewers.count : 0
            team_count = team_reviewers ? team_reviewers.count : 0
            UI.success("Successfully requested #{reviewer_count} reviewers and #{team_count} team reviewers for pull request ##{pull_number}")
          else
            UI.error("Error requesting reviewers: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_REQUEST_PULL_REVIEW_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_REQUEST_PULL_REVIEW_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_REQUEST_PULL_REVIEW_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Requests reviewers for a pull request"
        end
        
        def details
          [
            "Requests reviewers for a pull request.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/review-requests#request-reviewers-for-a-pull-request"
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
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :reviewers,
                                 env_name: "GITHUB_PULL_REVIEWERS",
                              description: "An array of user logins that will be requested to review",
                                 optional: true,
                                     type: Array),
            FastlaneCore::ConfigItem.new(key: :team_reviewers,
                                 env_name: "GITHUB_PULL_TEAM_REVIEWERS",
                              description: "An array of team slugs that will be requested to review",
                                 optional: true,
                                     type: Array)
          ]
        end

        def output
          [
            ['GITHUB_REQUEST_PULL_REVIEW_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_REQUEST_PULL_REVIEW_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_REQUEST_PULL_REVIEW_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_request_pull_review(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              reviewers: ["username1", "username2"]
            )',
            'github_request_pull_review(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              reviewers: ["username1"],
              team_reviewers: ["engineering-team"]
            )'
          ]
        end
      end
    end
  end
end
