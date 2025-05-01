require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_CREATE_REPOSITORY_STATUS_CODE = :GITHUB_CREATE_REPOSITORY_STATUS_CODE
      GITHUB_CREATE_REPOSITORY_RESPONSE = :GITHUB_CREATE_REPOSITORY_RESPONSE
      GITHUB_CREATE_REPOSITORY_JSON = :GITHUB_CREATE_REPOSITORY_JSON
    end

    class GithubCreateRepositoryAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          name = params[:name]
          
          # Validate parameters
          UI.user_error!("No repository name given, pass using `name: 'repo-name'`") if name.to_s.empty?
          
          # Build the path
          path = "/user/repos"
          
          # Build body parameters
          body_params = {
            name: name
          }
          
          # Add optional parameters if provided
          body_params[:description] = params[:description] if params[:description]
          body_params[:homepage] = params[:homepage] if params[:homepage]
          body_params[:private] = params[:private] unless params[:private].nil?
          body_params[:has_issues] = params[:has_issues] unless params[:has_issues].nil?
          body_params[:has_projects] = params[:has_projects] unless params[:has_projects].nil?
          body_params[:has_wiki] = params[:has_wiki] unless params[:has_wiki].nil?
          body_params[:auto_init] = params[:auto_init] unless params[:auto_init].nil?
          body_params[:license_template] = params[:license_template] if params[:license_template]
          body_params[:allow_squash_merge] = params[:allow_squash_merge] unless params[:allow_squash_merge].nil?
          body_params[:allow_merge_commit] = params[:allow_merge_commit] unless params[:allow_merge_commit].nil?
          body_params[:allow_rebase_merge] = params[:allow_rebase_merge] unless params[:allow_rebase_merge].nil?
          
          # If organization is provided, use the org repos endpoint
          if params[:organization]
            path = "/orgs/#{params[:organization]}/repos"
          end
          
          UI.message("Creating repository: #{name}")
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
            UI.success("Successfully created repository: #{json_response['full_name']}")
          else
            UI.error("Error creating repository: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_CREATE_REPOSITORY_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_CREATE_REPOSITORY_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_CREATE_REPOSITORY_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Creates a new GitHub repository"
        end
        
        def details
          [
            "Creates a new repository on GitHub for the authenticated user or specified organization.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/repos/repos#create-a-repository-for-the-authenticated-user"
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
            FastlaneCore::ConfigItem.new(key: :name,
                              description: "The name of the new repository",
                                 optional: false,
                                     type: String,
                              verify_block: proc do |value|
                                UI.user_error!("No repository name provided, pass using `name: 'repo-name'`") if value.to_s.empty?
                              end),
            FastlaneCore::ConfigItem.new(key: :organization,
                              description: "The organization name (if creating a repository for an organization)",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :description,
                              description: "A short description of the repository",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :homepage,
                              description: "A URL with more information about the repository",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :private,
                              description: "Whether the repository is private (true) or public (false)",
                                 optional: true,
                               is_string: false),
            FastlaneCore::ConfigItem.new(key: :has_issues,
                              description: "Whether to enable issues for this repository",
                                 optional: true,
                               is_string: false),
            FastlaneCore::ConfigItem.new(key: :has_projects,
                              description: "Whether to enable projects for this repository",
                                 optional: true,
                               is_string: false),
            FastlaneCore::ConfigItem.new(key: :has_wiki,
                              description: "Whether to enable the wiki for this repository",
                                 optional: true,
                               is_string: false),
            FastlaneCore::ConfigItem.new(key: :auto_init,
                              description: "Whether to create an initial commit with README",
                                 optional: true,
                               is_string: false),
            FastlaneCore::ConfigItem.new(key: :license_template,
                              description: "License template to include (e.g., 'mit', 'apache-2.0')",
                                 optional: true,
                                     type: String),
            FastlaneCore::ConfigItem.new(key: :allow_squash_merge,
                              description: "Whether to allow squash merges for pull requests",
                                 optional: true,
                               is_string: false),
            FastlaneCore::ConfigItem.new(key: :allow_merge_commit,
                              description: "Whether to allow merge commits for pull requests",
                                 optional: true,
                               is_string: false),
            FastlaneCore::ConfigItem.new(key: :allow_rebase_merge,
                              description: "Whether to allow rebase merges for pull requests",
                                 optional: true,
                               is_string: false)
          ]
        end
        
        def output
          [
            ['GITHUB_CREATE_REPOSITORY_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_CREATE_REPOSITORY_RESPONSE', 'The full response body from the GitHub API'],
            ['GITHUB_CREATE_REPOSITORY_JSON', 'The parsed JSON returned from the GitHub API']
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
            'github_create_repository(
              api_token: ENV["GITHUB_API_TOKEN"],
              name: "my-new-repo",
              description: "My awesome new repo",
              private: true,
              auto_init: true,
              license_template: "mit"
            )',
            '# Create repository in an organization',
            'github_create_repository(
              api_token: ENV["GITHUB_API_TOKEN"],
              name: "org-repo",
              organization: "my-org",
              private: false,
              has_issues: true,
              has_wiki: false
            )',
            '# You can also access the response data',
            'result = github_create_repository(
              api_token: ENV["GITHUB_API_TOKEN"],
              name: "my-new-repo"
            )
            UI.message("Created repository URL: #{result[:json]["html_url"]}")'
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