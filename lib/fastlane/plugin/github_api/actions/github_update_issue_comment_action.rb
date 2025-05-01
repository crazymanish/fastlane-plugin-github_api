require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_UPDATE_ISSUE_COMMENT_STATUS_CODE = :GITHUB_UPDATE_ISSUE_COMMENT_STATUS_CODE
      GITHUB_UPDATE_ISSUE_COMMENT_RESPONSE = :GITHUB_UPDATE_ISSUE_COMMENT_RESPONSE
      GITHUB_UPDATE_ISSUE_COMMENT_JSON = :GITHUB_UPDATE_ISSUE_COMMENT_JSON
    end

    class GithubUpdateIssueCommentAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          comment_id = params[:comment_id]
          body = params[:body]
          
          # Validate parameters
          UI.user_error!("No comment ID provided, pass using `comment_id: 12345678`") unless comment_id.to_s.length > 0
          UI.user_error!("No comment body provided, pass using `body: 'Updated comment'`") if body.to_s.empty?
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/issues/comments/#{comment_id}"
          
          # Build body parameters
          body_params = {
            body: body
          }
          
          UI.message("Updating comment ID: #{comment_id} in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: body_params,
            method: :patch,
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
            UI.success("Successfully updated comment ID: #{comment_id} in #{repo_owner}/#{repo_name}")
          else
            UI.error("Error updating comment: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_UPDATE_ISSUE_COMMENT_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_UPDATE_ISSUE_COMMENT_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_UPDATE_ISSUE_COMMENT_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Updates a comment on a GitHub issue"
        end
        
        def details
          [
            "Updates an existing comment on an issue in a GitHub repository.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/issues/comments#update-an-issue-comment"
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
                              description: "Repository owner (organization or username)",
                                 optional: false,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :repo_name,
                              description: "Repository name",
                                 optional: false,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :comment_id,
                              description: "The ID of the comment to update",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :body,
                              description: "The updated body text of the comment",
                                 optional: false,
                                     type: String)
          ]
        end
        
        def output
          [
            ['GITHUB_UPDATE_ISSUE_COMMENT_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_UPDATE_ISSUE_COMMENT_RESPONSE', 'The full response body from the GitHub API'],
            ['GITHUB_UPDATE_ISSUE_COMMENT_JSON', 'The parsed JSON returned from the GitHub API']
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
            'github_update_issue_comment(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              comment_id: 12345678,
              body: "Updated comment text"
            )',
            '# You can also access the response data
            result = github_update_issue_comment(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              comment_id: 12345678,
              body: "Updated comment text"
            )
            UI.message("Updated comment by: #{result[:json]["user"]["login"]}")'
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