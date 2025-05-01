require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_CREATE_PULL_COMMENT_STATUS_CODE = :GITHUB_CREATE_PULL_COMMENT_STATUS_CODE
      GITHUB_CREATE_PULL_COMMENT_RESPONSE = :GITHUB_CREATE_PULL_COMMENT_RESPONSE
      GITHUB_CREATE_PULL_COMMENT_JSON = :GITHUB_CREATE_PULL_COMMENT_JSON
    end

    class GithubCreatePullCommentAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          
          # Validate required parameters
          UI.user_error!("Comment body is required") if params[:body].to_s.empty?
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/comments"
          
          # Build body parameters
          body_params = {
            body: params[:body]
          }
          
          # Add required parameters for different comment types
          if params[:commit_id] && params[:path] && !params[:in_reply_to]
            body_params[:commit_id] = params[:commit_id]
            body_params[:path] = params[:path]
            body_params[:position] = params[:position] if params[:position]
            body_params[:line] = params[:line] if params[:line]
            body_params[:side] = params[:side] if params[:side]
            body_params[:start_line] = params[:start_line] if params[:start_line]
            body_params[:start_side] = params[:start_side] if params[:start_side]
          elsif params[:in_reply_to]
            body_params[:in_reply_to] = params[:in_reply_to]
          else
            UI.user_error!("Either provide commit_id and path OR in_reply_to parameter")
          end
          
          UI.message("Creating comment on pull request ##{pull_number} in #{repo_owner}/#{repo_name}")
          
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            server_url: server_url,
            path: path,
            params: body_params,
            method: :post
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
            UI.success("Successfully created comment #{comment_id} on pull request ##{pull_number}")
          else
            UI.error("Error creating pull request comment: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_CREATE_PULL_COMMENT_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_CREATE_PULL_COMMENT_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_CREATE_PULL_COMMENT_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Creates a review comment on a pull request"
        end
        
        def details
          [
            "Creates a review comment on a pull request. Can create a comment on a specific line/position or in reply to another comment.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/comments#create-a-review-comment-for-a-pull-request"
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
            FastlaneCore::ConfigItem.new(key: :body,
                                 env_name: "GITHUB_PR_COMMENT_BODY",
                              description: "The text of the review comment",
                                 optional: false,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :commit_id,
                                 env_name: "GITHUB_PR_COMMENT_COMMIT_ID",
                              description: "The SHA of the commit to comment on (required when not replying to a comment)",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :path,
                                 env_name: "GITHUB_PR_COMMENT_PATH",
                              description: "The relative path to the file being commented on (required when not replying to a comment)",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :position,
                                 env_name: "GITHUB_PR_COMMENT_POSITION",
                              description: "The position in the diff to comment on (required when not replying to a comment and line/side not specified)",
                                 optional: true,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :line,
                                 env_name: "GITHUB_PR_COMMENT_LINE",
                              description: "The line number in the file to comment on (required when position is not specified)",
                                 optional: true,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :side,
                                 env_name: "GITHUB_PR_COMMENT_SIDE",
                              description: "Side of the diff (LEFT or RIGHT)",
                                 optional: true,
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("Side must be one of: LEFT, RIGHT") unless ["LEFT", "RIGHT"].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :start_line,
                                 env_name: "GITHUB_PR_COMMENT_START_LINE",
                              description: "The start line number for multi-line comments",
                                 optional: true,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :start_side,
                                 env_name: "GITHUB_PR_COMMENT_START_SIDE",
                              description: "Side of the diff for the start line (LEFT or RIGHT)",
                                 optional: true,
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("Start side must be one of: LEFT, RIGHT") unless ["LEFT", "RIGHT"].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :in_reply_to,
                                 env_name: "GITHUB_PR_COMMENT_IN_REPLY_TO",
                              description: "The ID of the comment to reply to (when creating a reply)",
                                 optional: true,
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_CREATE_PULL_COMMENT_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_CREATE_PULL_COMMENT_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_CREATE_PULL_COMMENT_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_create_pull_comment(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              body: "Great improvement to this section!",
              commit_id: "6dcb09b5b57875f334f61aebed695e2e4193db5e",
              path: "file.rb",
              line: 42,
              side: "RIGHT"
            )',
            'github_create_pull_comment(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              body: "I agree with your suggestion",
              in_reply_to: 123456
            )'
          ]
        end
      end
    end
  end
end
