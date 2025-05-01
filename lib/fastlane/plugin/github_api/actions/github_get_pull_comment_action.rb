require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_GET_PULL_COMMENT_STATUS_CODE = :GITHUB_GET_PULL_COMMENT_STATUS_CODE
      GITHUB_GET_PULL_COMMENT_RESPONSE = :GITHUB_GET_PULL_COMMENT_RESPONSE
      GITHUB_GET_PULL_COMMENT_JSON = :GITHUB_GET_PULL_COMMENT_JSON
    end

    class GithubGetPullCommentAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          comment_id = params[:comment_id]
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/comments/#{comment_id}"
          
          UI.message("Getting pull request comment #{comment_id} from #{repo_owner}/#{repo_name}")
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
            UI.success("Successfully retrieved pull request comment #{comment_id}")
          else
            UI.error("Error getting pull request comment: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_GET_PULL_COMMENT_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_GET_PULL_COMMENT_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_GET_PULL_COMMENT_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Gets a specific pull request comment"
        end
        
        def details
          [
            "Gets detailed information about a specific review comment on a pull request.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/comments#get-a-review-comment-for-a-pull-request"
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
            FastlaneCore::ConfigItem.new(key: :comment_id,
                                 env_name: "GITHUB_PR_COMMENT_ID",
                              description: "The ID of the comment",
                                 optional: false,
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_GET_PULL_COMMENT_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_GET_PULL_COMMENT_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_GET_PULL_COMMENT_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_get_pull_comment(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              comment_id: 12345
            )',
            'comment = github_get_pull_comment(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              comment_id: 12345
            )
            puts "Comment by #{comment[:json]["user"]["login"]}: #{comment[:json]["body"]}"'
          ]
        end
      end
    end
  end
end
