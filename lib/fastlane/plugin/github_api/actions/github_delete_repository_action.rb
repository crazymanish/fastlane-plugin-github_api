require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_DELETE_REPOSITORY_STATUS_CODE = :GITHUB_DELETE_REPOSITORY_STATUS_CODE
      GITHUB_DELETE_REPOSITORY_RESPONSE = :GITHUB_DELETE_REPOSITORY_RESPONSE
      GITHUB_DELETE_REPOSITORY_JSON = :GITHUB_DELETE_REPOSITORY_JSON
    end

    class GithubDeleteRepositoryAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          
          # Validate parameters
          UI.user_error!("No repository owner provided, pass using `repo_owner: 'owner'`") if repo_owner.to_s.empty?
          UI.user_error!("No repository name provided, pass using `repo_name: 'name'`") if repo_name.to_s.empty?
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}"
          
          # Add confirmation
          if !params[:confirm]
            UI.important("⚠️ Are you sure you want to delete the repository '#{repo_owner}/#{repo_name}'?")
            UI.important("This action is irreversible and will delete all repository data!")
            UI.important("To confirm, pass `confirm: true` to this action.")
            UI.user_error!("Repository deletion was not confirmed")
            return nil
          end
          
          UI.message("Deleting repository: #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            method: :delete,
            server_url: server_url
          )
          
          status_code = response[:status]
          result = {
            status: status_code,
            body: response[:body],
            json: response[:json]
          }
          
          if status_code.between?(200, 299) || status_code == 204
            UI.success("Successfully deleted repository: #{repo_owner}/#{repo_name}")
          else
            UI.error("Error deleting repository: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_DELETE_REPOSITORY_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_DELETE_REPOSITORY_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_DELETE_REPOSITORY_JSON] = response[:json]
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Deletes a GitHub repository"
        end
        
        def details
          [
            "Deletes a repository on GitHub.",
            "WARNING: This action is irreversible and will delete all repository data, issues, pull requests, and releases!",
            "You must provide your GitHub Personal token with delete repository permissions (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/repos/repos#delete-a-repository"
          ].join("\n")
        end
        
        def available_options
          [
            FastlaneCore::ConfigItem.new(key: :api_token,
                                 env_name: "GITHUB_API_TOKEN",
                              description: "GitHub API token with delete repo permissions",
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
            FastlaneCore::ConfigItem.new(key: :confirm,
                              description: "Confirm repository deletion. Must be set to true to delete the repository",
                                 optional: false,
                               is_string: false,
                            default_value: false)
          ]
        end
        
        def output
          [
            ['GITHUB_DELETE_REPOSITORY_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_DELETE_REPOSITORY_RESPONSE', 'The full response body from the GitHub API'],
            ['GITHUB_DELETE_REPOSITORY_JSON', 'The parsed JSON returned from the GitHub API']
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
            'github_delete_repository(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "username",
              repo_name: "repo-to-delete",
              confirm: true
            )'
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