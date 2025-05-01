require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_LIST_PULLS_STATUS_CODE = :GITHUB_LIST_PULLS_STATUS_CODE
      GITHUB_LIST_PULLS_RESPONSE = :GITHUB_LIST_PULLS_RESPONSE
      GITHUB_LIST_PULLS_JSON = :GITHUB_LIST_PULLS_JSON
    end

    class GithubListPullsAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls"
          
          # Build query parameters
          query_params = {}
          query_params[:state] = params[:state] if params[:state]
          query_params[:head] = params[:head] if params[:head]
          query_params[:base] = params[:base] if params[:base]
          query_params[:sort] = params[:sort] if params[:sort]
          query_params[:direction] = params[:direction] if params[:direction]
          query_params[:per_page] = params[:per_page] if params[:per_page]
          query_params[:page] = params[:page] if params[:page]
          
          UI.message("Listing pull requests for #{repo_owner}/#{repo_name}")
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
            pull_count = json_response.count
            UI.success("Successfully retrieved #{pull_count} pull requests from #{repo_owner}/#{repo_name}")
          else
            UI.error("Error listing pull requests: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_LIST_PULLS_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_LIST_PULLS_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_LIST_PULLS_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Lists pull requests in a GitHub repository"
        end
        
        def details
          [
            "Lists pull requests in a GitHub repository with filtering options.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/pulls#list-pull-requests"
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
            FastlaneCore::ConfigItem.new(key: :state,
                                 env_name: "GITHUB_PR_STATE",
                              description: "State of the PR: open, closed, or all",
                                 optional: true,
                            default_value: "open",
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("State must be one of: open, closed, all") unless ["open", "closed", "all"].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :head,
                                 env_name: "GITHUB_PR_HEAD",
                              description: "Filter by head user or head organization and branch name in the format of user:ref-name or organization:ref-name",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :base,
                                 env_name: "GITHUB_PR_BASE",
                              description: "Filter by base branch name",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :sort,
                                 env_name: "GITHUB_PR_SORT",
                              description: "What to sort results by: created, updated, popularity, long-running",
                                 optional: true,
                            default_value: "created",
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("Sort must be one of: created, updated, popularity, long-running") unless ["created", "updated", "popularity", "long-running"].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :direction,
                                 env_name: "GITHUB_PR_DIRECTION",
                              description: "The direction of the sort: asc or desc",
                                 optional: true,
                            default_value: "desc",
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("Direction must be one of: asc, desc") unless ["asc", "desc"].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :per_page,
                                 env_name: "GITHUB_PR_PER_PAGE",
                              description: "Results per page (max 100)",
                                 optional: true,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :page,
                                 env_name: "GITHUB_PR_PAGE",
                              description: "Page number of the results to fetch",
                                 optional: true,
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_LIST_PULLS_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_LIST_PULLS_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_LIST_PULLS_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_list_pulls(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              state: "open"
            )',
            'pulls = github_list_pulls(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              base: "main",
              sort: "created",
              direction: "desc",
              per_page: 10
            )
            
            pulls[:json].each do |pull|
              puts "PR ##{pull["number"]}: #{pull["title"]}"
            end'
          ]
        end
      end
    end
  end
end
