require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_SUBMIT_PULL_REVIEW_STATUS_CODE = :GITHUB_SUBMIT_PULL_REVIEW_STATUS_CODE
      GITHUB_SUBMIT_PULL_REVIEW_RESPONSE = :GITHUB_SUBMIT_PULL_REVIEW_RESPONSE
      GITHUB_SUBMIT_PULL_REVIEW_JSON = :GITHUB_SUBMIT_PULL_REVIEW_JSON
    end

    class GithubSubmitPullReviewAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          event = params[:event]
          body = params[:body]
          comments = params[:comments]
          
          # Build the body for the request
          request_body = {}
          request_body[:event] = event if event
          request_body[:body] = body if body
          request_body[:comments] = comments if comments && !comments.empty?
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/reviews"
          
          UI.message("Submitting a review for pull request ##{pull_number} in #{repo_owner}/#{repo_name}")
          
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: request_body,
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
            UI.success("Successfully submitted a #{event} review for pull request ##{pull_number}")
          else
            UI.error("Error submitting review: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_SUBMIT_PULL_REVIEW_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_SUBMIT_PULL_REVIEW_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_SUBMIT_PULL_REVIEW_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Create a review for a pull request"
        end
        
        def details
          [
            "Creates a new review for a pull request.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/reviews#create-a-review-for-a-pull-request"
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
            FastlaneCore::ConfigItem.new(key: :event,
                                 env_name: "GITHUB_REVIEW_EVENT",
                              description: "The review action (APPROVE, REQUEST_CHANGES, COMMENT)",
                                 optional: true,
                                     type: String,
                            default_value: "COMMENT",
                             verify_block: proc do |value|
                               UI.user_error!("Event must be one of: APPROVE, REQUEST_CHANGES, COMMENT") unless ['APPROVE', 'REQUEST_CHANGES', 'COMMENT'].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :body,
                                 env_name: "GITHUB_REVIEW_BODY",
                              description: "The body text of the review",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :comments,
                                 env_name: "GITHUB_REVIEW_COMMENTS",
                              description: "Comments to add to the review (array of hashes with path, position, body)",
                                 optional: true,
                                     type: Array)
          ]
        end

        def output
          [
            ['GITHUB_SUBMIT_PULL_REVIEW_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_SUBMIT_PULL_REVIEW_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_SUBMIT_PULL_REVIEW_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_submit_pull_review(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              event: "APPROVE",
              body: "Looks good! 👍"
            )',
            'github_submit_pull_review(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              event: "REQUEST_CHANGES",
              body: "Please fix these issues before merging.",
              comments: [
                {
                  path: "file.rb",
                  position: 10,
                  body: "Consider refactoring this section."
                }
              ]
            )'
          ]
        end
      end
    end
  end
end
