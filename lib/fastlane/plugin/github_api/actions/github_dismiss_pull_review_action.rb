require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_DISMISS_PULL_REVIEW_STATUS_CODE = :GITHUB_DISMISS_PULL_REVIEW_STATUS_CODE
      GITHUB_DISMISS_PULL_REVIEW_RESPONSE = :GITHUB_DISMISS_PULL_REVIEW_RESPONSE
      GITHUB_DISMISS_PULL_REVIEW_JSON = :GITHUB_DISMISS_PULL_REVIEW_JSON
    end

    class GithubDismissPullReviewAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          review_id = params[:review_id]
          message = params[:message]
          
          # Build the body for the request
          body = { message: message }
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/reviews/#{review_id}/dismissals"
          
          UI.message("Dismissing review ##{review_id} for pull request ##{pull_number} in #{repo_owner}/#{repo_name}")
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
            UI.success("Successfully dismissed review ##{review_id} for pull request ##{pull_number}")
          else
            UI.error("Error dismissing review: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_DISMISS_PULL_REVIEW_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_DISMISS_PULL_REVIEW_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_DISMISS_PULL_REVIEW_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Dismiss a review for a pull request"
        end
        
        def details
          [
            "Dismisses a review for a pull request.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/reviews#dismiss-a-review-for-a-pull-request"
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
                                 env_name: "GITHUB_API_PULL_NUMBER",
                              description: "The number of the pull request",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :review_id,
                                 env_name: "GITHUB_API_REVIEW_ID",
                              description: "The ID of the review",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :message,
                                 env_name: "GITHUB_API_REVIEW_DISMISS_MESSAGE",
                              description: "The message for the review dismissal",
                                 optional: false,
                                     type: String)
          ]
        end

        def output
          [
            ['GITHUB_DISMISS_PULL_REVIEW_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_DISMISS_PULL_REVIEW_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_DISMISS_PULL_REVIEW_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_dismiss_pull_review(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              review_id: 80,
              message: "Dismissing this review as the code has been updated."
            )',
            'dismissed_review = github_dismiss_pull_review(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              review_id: 80,
              message: "This review is no longer relevant."
            )
            
            puts "Review dismissed successfully with status: #{dismissed_review[:status]}"'
          ]
        end
      end
    end
  end
end
