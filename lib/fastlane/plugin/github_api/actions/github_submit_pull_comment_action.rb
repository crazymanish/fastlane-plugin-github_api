require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_SUBMIT_PULL_COMMENT_STATUS_CODE = :GITHUB_SUBMIT_PULL_COMMENT_STATUS_CODE
      GITHUB_SUBMIT_PULL_COMMENT_RESPONSE = :GITHUB_SUBMIT_PULL_COMMENT_RESPONSE
      GITHUB_SUBMIT_PULL_COMMENT_JSON = :GITHUB_SUBMIT_PULL_COMMENT_JSON
    end

    class GithubSubmitPullCommentAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          body = params[:body]
          commit_id = params[:commit_id]
          path = params[:path]
          position = params[:position]
          
          # Build the body for the request
          request_body = {
            body: body
          }
          
          request_body[:commit_id] = commit_id if commit_id
          request_body[:path] = path if path
          request_body[:position] = position if position
          
          # Build the path
          api_path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}/comments"
          
          UI.message("Creating a comment on pull request ##{pull_number} in #{repo_owner}/#{repo_name}")
          
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            server_url: server_url,
            path: api_path,
            method: :post,
            params: request_body
          )
          
          status_code = response[:status]
          json_response = response[:json]
          result = {
            status: status_code,
            body: response[:body],
            json: json_response
          }
          
          if status_code.between?(200, 299)
            UI.success("Successfully created a comment on pull request ##{pull_number}")
          else
            UI.error("Error creating comment: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_SUBMIT_PULL_COMMENT_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_SUBMIT_PULL_COMMENT_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_SUBMIT_PULL_COMMENT_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Create a review comment on a pull request"
        end
        
        def details
          [
            "Creates a review comment on a pull request.",
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
                              description: "GitHub server url",
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
                                 env_name: "GITHUB_COMMENT_BODY",
                              description: "The body text of the comment",
                                 optional: false,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :commit_id,
                                 env_name: "GITHUB_COMMIT_ID",
                              description: "The SHA of the commit to comment on",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :path,
                                 env_name: "GITHUB_FILE_PATH",
                              description: "The relative path to the file to comment on",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :position,
                                 env_name: "GITHUB_FILE_POSITION",
                              description: "The position in the diff to comment on",
                                 optional: true,
                                     type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_SUBMIT_PULL_COMMENT_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_SUBMIT_PULL_COMMENT_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_SUBMIT_PULL_COMMENT_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_submit_pull_comment(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              body: "This is a great improvement!"
            )',
            'github_submit_pull_comment(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              body: "This could be improved",
              commit_id: "6dcb09b5b57875f334f61aebed695e2e4193db5e",
              path: "file.rb",
              position: 10
            )'
          ]
        end
      end
    end
  end
end
