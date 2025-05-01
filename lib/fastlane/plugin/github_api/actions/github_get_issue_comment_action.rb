require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_GET_ISSUE_COMMENT_RESPONSE = :GITHUB_GET_ISSUE_COMMENT_RESPONSE
      GITHUB_GET_ISSUE_COMMENT_JSON = :GITHUB_GET_ISSUE_COMMENT_JSON
      GITHUB_GET_ISSUE_COMMENT_STATUS_CODE = :GITHUB_GET_ISSUE_COMMENT_STATUS_CODE
    end

    class GithubGetIssueCommentAction < Action
      class << self
        def run(params)
          token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          comment_id = params[:comment_id]
          server_url = params[:server_url]
          
          # Validate parameters (additional validation beyond what's in ConfigItem)
          UI.user_error!("No comment ID provided, pass using `comment_id: 12345678`") unless comment_id.to_s.length > 0
          
          # Prepare request parameters
          path = "/repos/#{repo_owner}/#{repo_name}/issues/comments/#{comment_id}"
          
          # Make the request
          UI.message("Fetching comment ID #{comment_id} from #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: token,
            path: path,
            method: :get,
            server_url: server_url
          )
          
          status_code = response.key?('status') ? response['status'] : nil
          result = {
            status: status_code,
            body: response,
            json: response
          }
          
          if response.key?('error')
            UI.error("GitHub responded with an error: #{response['error']}")
            UI.user_error!("GitHub API error: #{response['error']}")
            return nil
          end
          
          if response['message'] && status_code && status_code >= 400
            UI.error("GitHub API error: #{response['message']}")
            UI.user_error!("GitHub API error: #{response['message']} (Status code: #{status_code})")
            return nil
          end
          
          # Print comment user info
          if response['user'] && response['user']['login']
            user = response['user']['login']
            UI.success("Successfully fetched comment ID #{comment_id} by #{user}")
          else
            UI.success("Successfully fetched comment ID #{comment_id}")
          end
          
          # Set the shared values
          Actions.lane_context[SharedValues::GITHUB_GET_ISSUE_COMMENT_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_GET_ISSUE_COMMENT_RESPONSE] = response
          Actions.lane_context[SharedValues::GITHUB_GET_ISSUE_COMMENT_JSON] = response
          
          return result
        end

        #####################################################
        # @!group Documentation
        #####################################################

        def description
          "Gets a specific comment from a GitHub issue"
        end

        def details
          [
            "This action fetches a specific comment from a GitHub issue by its comment ID.",
            "It requires a valid GitHub API token with appropriate permissions.",
            "Documentation: [https://docs.github.com/en/rest/issues/comments](https://docs.github.com/en/rest/issues/comments#get-an-issue-comment)"
          ].join("\n")
        end

        def available_options
          [
            FastlaneCore::ConfigItem.new(key: :api_token,
                                    env_name: "GITHUB_API_TOKEN",
                                 description: "GitHub API token with repo permissions",
                                    optional: false,
                                        type: String,
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
                              description: "Repository owner (organization or username)",
                                    optional: false,
                                        type: String,
                               verify_block: proc do |value|
                                  UI.user_error!("No repository owner provided, pass using `repo_owner: 'owner'`") if value.to_s.empty?
                                end),
            FastlaneCore::ConfigItem.new(key: :repo_name,
                                 env_name: "GITHUB_API_REPO_NAME",
                                 description: "Repository name",
                                    optional: false,
                                        type: String,
                               verify_block: proc do |value|
                                  UI.user_error!("No repository name provided, pass using `repo_name: 'name'`") if value.to_s.empty?
                                end),
            FastlaneCore::ConfigItem.new(key: :comment_id,
                                 description: "The ID of the comment to fetch",
                                    optional: false,
                                        type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_GET_ISSUE_COMMENT_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_GET_ISSUE_COMMENT_RESPONSE', 'The full response from the GitHub API'],
            ['GITHUB_GET_ISSUE_COMMENT_JSON', 'The JSON data returned from the GitHub API']
          ]
        end

        def return_value
          "A hash including the HTTP status code (:status), the response body (:body), and the parsed JSON (:json)."
        end

        def authors
          ["Manish Rathi"]
        end

        def example_code
          [
            'github_get_issue_comment(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              comment_id: 12345678
            )',
            '# You can also access the response data
            result = github_get_issue_comment(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              comment_id: 12345678
            )
            UI.message("Comment by: #{result[:json]["user"]["login"]}")
            UI.message("Comment body: #{result[:json]["body"]}")'
          ]
        end

        def category
          :source_control
        end

        def is_supported?(platform)
          true
        end
      end
    end
  end
end