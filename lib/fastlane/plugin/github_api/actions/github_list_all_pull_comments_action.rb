require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_LIST_PULL_COMMENTS_ALL_STATUS_CODE = :GITHUB_LIST_PULL_COMMENTS_ALL_STATUS_CODE
      GITHUB_LIST_PULL_COMMENTS_ALL_RESPONSE = :GITHUB_LIST_PULL_COMMENTS_ALL_RESPONSE
      GITHUB_LIST_PULL_COMMENTS_ALL_JSON = :GITHUB_LIST_PULL_COMMENTS_ALL_JSON
    end

    class GithubListAllPullCommentsAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/comments"
          
          # Build query parameters
          query_params = {}
          query_params[:sort] = params[:sort] if params[:sort]
          query_params[:direction] = params[:direction] if params[:direction]
          query_params[:since] = params[:since] if params[:since]
          query_params[:per_page] = params[:per_page] if params[:per_page]
          query_params[:page] = params[:page] if params[:page]
          
          UI.message("Listing all pull request comments in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: query_params,
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
            comment_count = json_response.count
            UI.success("Successfully retrieved #{comment_count} pull request comments")
          else
            UI.error("Error listing pull request comments: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_LIST_PULL_COMMENTS_ALL_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_LIST_PULL_COMMENTS_ALL_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_LIST_PULL_COMMENTS_ALL_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Lists review comments in a repository"
        end
        
        def details
          [
            "Lists all review comments on all pull requests in a repository with filtering options.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/comments#list-review-comments-in-a-repository"
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
            FastlaneCore::ConfigItem.new(key: :sort,
                                 env_name: "GITHUB_PR_COMMENTS_SORT",
                              description: "What to sort results by: created, updated",
                                 optional: true,
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("Sort must be one of: created, updated") unless ["created", "updated"].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :direction,
                                 env_name: "GITHUB_PR_COMMENTS_DIRECTION",
                              description: "The direction of the sort: asc or desc",
                                 optional: true,
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("Direction must be one of: asc, desc") unless ["asc", "desc"].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :since,
                                 env_name: "GITHUB_PR_COMMENTS_SINCE",
                              description: "Only comments updated at or after this time are returned (ISO 8601 format)",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :per_page,
                                 env_name: "GITHUB_PR_COMMENTS_PER_PAGE",
                              description: "Results per page (max 100)",
                                 optional: true,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :page,
                                 env_name: "GITHUB_PR_COMMENTS_PAGE",
                              description: "Page number of the results to fetch",
                                 optional: true,
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_LIST_PULL_COMMENTS_ALL_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_LIST_PULL_COMMENTS_ALL_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_LIST_PULL_COMMENTS_ALL_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_list_all_pull_comments(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              sort: "created",
              direction: "desc"
            )',
            'comments = github_list_all_pull_comments(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              since: "2022-01-01T00:00:00Z"
            )
            
            comments[:json].each do |comment|
              puts "Comment ID: #{comment["id"]}, on PR: #{comment["pull_request_url"]}"
            end'
          ]
        end
      end
    end
  end
end
