require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_ADD_ISSUE_COMMENT_STATUS_CODE = :GITHUB_ADD_ISSUE_COMMENT_STATUS_CODE
      GITHUB_ADD_ISSUE_COMMENT_RESPONSE = :GITHUB_ADD_ISSUE_COMMENT_RESPONSE
      GITHUB_ADD_ISSUE_COMMENT_JSON = :GITHUB_ADD_ISSUE_COMMENT_JSON
    end

    class GithubAddIssueCommentAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          issue_number = params[:issue_number]
          body = params[:body]
          
          # Validate parameters
          UI.user_error!("No GitHub issue number given, pass using `issue_number: 123`") unless issue_number.to_s.length > 0
          UI.user_error!("No comment body provided, pass using `body: 'Comment text'`") if body.to_s.empty?
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/issues/#{issue_number}/comments"
          
          # Build body parameters
          body_params = {
            body: body
          }
          
          UI.message("Adding comment to issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: body_params,
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
            comment_id = json_response['id']
            UI.success("Successfully added comment ID: #{comment_id} to issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          else
            UI.error("Error adding comment: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_ADD_ISSUE_COMMENT_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_ADD_ISSUE_COMMENT_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_ADD_ISSUE_COMMENT_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Adds a comment to a GitHub issue"
        end
        
        def details
          [
            "Adds a new comment to an issue in a GitHub repository.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/issues/comments#create-an-issue-comment"
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
            FastlaneCore::ConfigItem.new(key: :issue_number,
                              description: "The issue number to comment on",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :body,
                              description: "The body text of the comment",
                                 optional: false,
                                     type: String,
                              verify_block: proc do |value|
                                UI.user_error!("No comment body provided, pass using `body: 'Comment text'`") if value.to_s.empty?
                              end)
          ]
        end
        
        def output
          [
            ['GITHUB_ADD_ISSUE_COMMENT_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_ADD_ISSUE_COMMENT_RESPONSE', 'The full response body from the GitHub API'],
            ['GITHUB_ADD_ISSUE_COMMENT_JSON', 'The parsed JSON returned from the GitHub API']
          ]
        end
        
        def return_value
          "A hash including the HTTP status code (:status), the response body (:body), and the parsed JSON (:json)."
        end
        
        def authors
          ["crazymanish"]
        end
        
        def example_code
          [
            'github_add_issue_comment(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              body: "This is a new comment"
            )',
            '# You can also access the response data
            result = github_add_issue_comment(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              body: "This is a new comment"
            )
            UI.message("Created comment ID: #{result[:json]["id"]}")'
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