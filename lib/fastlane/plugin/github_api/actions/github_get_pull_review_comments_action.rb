require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_GET_PULL_REVIEW_COMMENTS_STATUS_CODE = :GITHUB_GET_PULL_REVIEW_COMMENTS_STATUS_CODE
      GITHUB_GET_PULL_REVIEW_COMMENTS_RESPONSE = :GITHUB_GET_PULL_REVIEW_COMMENTS_RESPONSE
      GITHUB_GET_PULL_REVIEW_COMMENTS_JSON = :GITHUB_GET_PULL_REVIEW_COMMENTS_JSON
    end

    class GithubGetPullReviewCommentsAction < Action
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
          per_page = params[:per_page]
          page = params[:page]
          
          # Build query parameters
          query_params = {}
          query_params[:per_page] = per_page if per_page
          query_params[:page] = page if page
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/reviews/#{review_id}/comments"
          
          UI.message("Getting comments for review ##{review_id} on pull request ##{pull_number} from #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: query_params.empty? ? nil : query_params
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
            comment_count = json_response.is_a?(Array) ? json_response.count : 0
            UI.success("Successfully retrieved #{comment_count} comments for review ##{review_id} on pull request ##{pull_number}")
          else
            UI.error("Error getting review comments: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_GET_PULL_REVIEW_COMMENTS_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_GET_PULL_REVIEW_COMMENTS_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_GET_PULL_REVIEW_COMMENTS_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Get comments for a pull request review"
        end
        
        def details
          [
            "Lists all comments for a specific pull request review.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/reviews#get-comments-for-a-pull-request-review"
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
            FastlaneCore::ConfigItem.new(key: :review_id,
                                 env_name: "GITHUB_REVIEW_ID",
                              description: "The ID of the review",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :per_page,
                                 env_name: "GITHUB_PER_PAGE",
                              description: "Results per page (max 100)",
                                 optional: true,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :page,
                                 env_name: "GITHUB_PAGE",
                              description: "Page number of the results to fetch",
                                 optional: true,
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_GET_PULL_REVIEW_COMMENTS_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_GET_PULL_REVIEW_COMMENTS_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_GET_PULL_REVIEW_COMMENTS_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_get_pull_review_comments(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              review_id: 80
            )',
            'comments = github_get_pull_review_comments(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              review_id: 80,
              per_page: 10,
              page: 1
            )
            
            comments[:json].each do |comment|
              puts "Comment by #{comment["user"]["login"]}: #{comment["body"]}"
              puts "Path: #{comment["path"]}, Position: #{comment["position"]}"
              puts "---"
            end'
          ]
        end
      end
    end
  end
end
