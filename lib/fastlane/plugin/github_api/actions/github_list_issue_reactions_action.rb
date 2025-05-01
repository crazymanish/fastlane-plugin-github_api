require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_LIST_ISSUE_REACTIONS_STATUS_CODE = :GITHUB_LIST_ISSUE_REACTIONS_STATUS_CODE
      GITHUB_LIST_ISSUE_REACTIONS_RESPONSE = :GITHUB_LIST_ISSUE_REACTIONS_RESPONSE
      GITHUB_LIST_ISSUE_REACTIONS_JSON = :GITHUB_LIST_ISSUE_REACTIONS_JSON
    end

    class GithubListIssueReactionsAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          issue_number = params[:issue_number]
          content = params[:content]
          per_page = params[:per_page]
          page = params[:page]
          
          # Build query parameters
          query_params = {}
          query_params[:content] = content if content
          query_params[:per_page] = per_page if per_page
          query_params[:page] = page if page
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/issues/#{issue_number}/reactions"
          
          UI.message("Listing reactions for issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: query_params.empty? ? nil : query_params,
            method: :get,
            server_url: server_url,
            headers: { 'Accept' => 'application/vnd.github.squirrel-girl-preview+json' }
          )
          
          status_code = response[:status]
          json_response = response[:json]
          result = {
            status: status_code,
            body: response[:body],
            json: json_response
          }
          
          if status_code.between?(200, 299)
            reaction_count = json_response.is_a?(Array) ? json_response.count : 0
            UI.success("Successfully retrieved #{reaction_count} reactions for issue ##{issue_number}")
          else
            UI.error("Error listing issue reactions: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_LIST_ISSUE_REACTIONS_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_LIST_ISSUE_REACTIONS_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_LIST_ISSUE_REACTIONS_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "List reactions for an issue"
        end
        
        def details
          [
            "Lists reactions for an issue.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/reactions/reactions#list-reactions-for-an-issue"
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
            FastlaneCore::ConfigItem.new(key: :issue_number,
                                 env_name: "GITHUB_API_ISSUE_NUMBER",
                              description: "The number of the issue",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :content,
                                 env_name: "GITHUB_API_REACTION_CONTENT",
                              description: "Filter reactions by content (e.g., +1, -1, laugh, confused, heart, hooray, rocket, eyes)",
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
            ['GITHUB_LIST_ISSUE_REACTIONS_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_LIST_ISSUE_REACTIONS_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_LIST_ISSUE_REACTIONS_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_list_issue_reactions(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              issue_number: 123
            )',
            'reactions = github_list_issue_reactions(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              issue_number: 123,
              content: "+1",
              per_page: 20,
              page: 1
            )
            
            reactions[:json].each do |reaction|
              puts "Reaction: #{reaction["content"]}"
              puts "User: #{reaction["user"]["login"]}"
              puts "Created at: #{reaction["created_at"]}"
              puts "---"
            end'
          ]
        end
      end
    end
  end
end
