require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_LIST_PULL_COMMENTS_STATUS_CODE = :GITHUB_LIST_PULL_COMMENTS_STATUS_CODE
      GITHUB_LIST_PULL_COMMENTS_RESPONSE = :GITHUB_LIST_PULL_COMMENTS_RESPONSE
      GITHUB_LIST_PULL_COMMENTS_JSON = :GITHUB_LIST_PULL_COMMENTS_JSON
    end

    class GithubListPullCommentsAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          sort = params[:sort]
          direction = params[:direction]
          since = params[:since]
          per_page = params[:per_page]
          page = params[:page]
          
          # Build query parameters
          query_params = {}
          query_params[:sort] = sort if sort
          query_params[:direction] = direction if direction
          query_params[:since] = since if since
          query_params[:per_page] = per_page if per_page
          query_params[:page] = page if page
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/comments"
          
          UI.message("Listing review comments on pull request ##{pull_number} from #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: query_params.empty? ? nil : query_params,
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
            UI.success("Successfully retrieved #{comment_count} review comments for pull request ##{pull_number}")
          else
            UI.error("Error listing pull request comments: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_LIST_PULL_COMMENTS_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_LIST_PULL_COMMENTS_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_LIST_PULL_COMMENTS_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "List review comments on a pull request"
        end
        
        def details
          [
            "Lists all review comments on a pull request.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/comments#list-review-comments-on-a-pull-request"
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
            FastlaneCore::ConfigItem.new(key: :sort,
                                 env_name: "GITHUB_API_SORT",
                              description: "Sort direction (created, updated)",
                                 optional: true,
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("Sort must be either 'created' or 'updated'") unless ['created', 'updated'].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :direction,
                                 env_name: "GITHUB_API_DIRECTION",
                              description: "Sort direction (asc or desc)",
                                 optional: true,
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("Direction must be either 'asc' or 'desc'") unless ['asc', 'desc'].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :since,
                                 env_name: "GITHUB_API_SINCE",
                              description: "Only show comments updated at or after this time (ISO 8601 format)",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :per_page,
                                 env_name: "GITHUB_API_PER_PAGE",
                              description: "Results per page (max 100)",
                                 optional: true,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :page,
                                 env_name: "GITHUB_API_PAGE",
                              description: "Page number of the results to fetch",
                                 optional: true,
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_LIST_PULL_COMMENTS_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_LIST_PULL_COMMENTS_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_LIST_PULL_COMMENTS_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_list_pull_comments(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42
            )',
            'comments = github_list_pull_comments(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              sort: "updated",
              direction: "desc",
              per_page: 20,
              page: 1
            )
            
            comments[:json].each do |comment|
              puts "Comment by #{comment["user"]["login"]}: #{comment["body"]}"
              puts "Path: #{comment["path"]}, Position: #{comment["position"]}"
              puts "Created at: #{comment["created_at"]}"
              puts "---"
            end'
          ]
        end
      end
    end
  end
end
