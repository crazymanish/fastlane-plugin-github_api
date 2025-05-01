require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_UPDATE_PULL_STATUS_CODE = :GITHUB_UPDATE_PULL_STATUS_CODE
      GITHUB_UPDATE_PULL_RESPONSE = :GITHUB_UPDATE_PULL_RESPONSE
      GITHUB_UPDATE_PULL_JSON = :GITHUB_UPDATE_PULL_JSON
    end

    class GithubUpdatePullAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          pull_number = params[:pull_number]
          
          # Build the body for the update request
          body = {}
          body[:title] = params[:title] if params[:title]
          body[:body] = params[:body] if params[:body]
          body[:state] = params[:state] if params[:state]
          body[:base] = params[:base] if params[:base]
          body[:maintainer_can_modify] = params[:maintainer_can_modify] unless params[:maintainer_can_modify].nil?
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/pulls/#{pull_number}"
          
          UI.message("Updating pull request ##{pull_number} from #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: body,
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
            UI.success("Successfully updated pull request ##{pull_number} from #{repo_owner}/#{repo_name}")
          else
            UI.error("Error updating pull request: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_UPDATE_PULL_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_UPDATE_PULL_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_UPDATE_PULL_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Updates a pull request in a GitHub repository"
        end
        
        def details
          [
            "Updates a specific pull request by its number.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/pulls/pulls#update-a-pull-request"
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
                                 env_name: "GITHUB_PULL_NUMBER",
                              description: "The number of the pull request",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :title,
                                 env_name: "GITHUB_PULL_TITLE",
                              description: "The title of the pull request",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :body,
                                 env_name: "GITHUB_PULL_BODY",
                              description: "The contents of the pull request",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :state,
                                 env_name: "GITHUB_PULL_STATE",
                              description: "State of the pull request (open, closed)",
                                 optional: true,
                                     type: String,
                             verify_block: proc do |value|
                               UI.user_error!("State must be either 'open' or 'closed'") unless ['open', 'closed'].include?(value)
                             end),
            FastlaneCore::ConfigItem.new(key: :base,
                                 env_name: "GITHUB_PULL_BASE",
                              description: "The name of the branch to which changes should be pulled",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :maintainer_can_modify,
                                 env_name: "GITHUB_PULL_MAINTAINER_CAN_MODIFY",
                              description: "Indicates whether maintainers can modify the pull request",
                                 optional: true,
                                     type: Boolean)
          ]
        end

        def output
          [
            ['GITHUB_UPDATE_PULL_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_UPDATE_PULL_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_UPDATE_PULL_JSON', 'The parsed JSON response returned by the GitHub API']
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
            'github_update_pull(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              title: "New pull request title",
              body: "Updated description",
              state: "open"
            )',
            'updated_pull = github_update_pull(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              pull_number: 42,
              title: "Updated title",
              state: "closed"
            )
            
            title = updated_pull[:json]["title"]
            puts "Updated Pull Request Title: #{title}"'
          ]
        end
      end
    end
  end
end
