require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_CREATE_MILESTONE_RESPONSE = :GITHUB_CREATE_MILESTONE_RESPONSE
      GITHUB_CREATE_MILESTONE_JSON = :GITHUB_CREATE_MILESTONE_JSON
      GITHUB_CREATE_MILESTONE_STATUS_CODE = :GITHUB_CREATE_MILESTONE_STATUS_CODE
    end

    class GithubCreateMilestoneAction < Action
      class << self
        def run(params)
          token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          
          # Validate parameters (additional validation beyond what's in ConfigItem)
          UI.user_error!("No title provided for milestone, pass using `title: 'My Milestone'`") if params[:title].to_s.empty?
          
          # Prepare request parameters
          path = "/repos/#{repo_owner}/#{repo_name}/milestones"
          
          # Build body parameters
          body_params = {
            title: params[:title]
          }
          
          # Add optional parameters if provided
          body_params[:state] = params[:state] if params[:state]
          body_params[:description] = params[:description] if params[:description]
          body_params[:due_on] = params[:due_on] if params[:due_on]
          
          # Make the request
          UI.message("Creating milestone in #{repo_owner}/#{repo_name}: #{params[:title]}")
          response = Helper::GithubApiHelper.github_api_request(
            token: token,
            path: path,
            params: body_params,
            method: :post
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
          
          milestone_number = response['number']
          UI.success("Successfully created milestone ##{milestone_number} - #{response['title']} in #{repo_owner}/#{repo_name}")
          
          # Set the shared values
          Actions.lane_context[SharedValues::GITHUB_CREATE_MILESTONE_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_CREATE_MILESTONE_RESPONSE] = response
          Actions.lane_context[SharedValues::GITHUB_CREATE_MILESTONE_JSON] = response
          
          return result
        end

        #####################################################
        # @!group Documentation
        #####################################################

        def description
          "Creates a new milestone in a GitHub repository"
        end

        def details
          [
            "This action creates a new milestone in a GitHub repository with the specified title and other optional parameters.",
            "It requires a valid GitHub API token with appropriate permissions.",
            "Documentation: [https://docs.github.com/en/rest/issues/milestones](https://docs.github.com/en/rest/issues/milestones#create-a-milestone)"
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
            FastlaneCore::ConfigItem.new(key: :repo_owner,
                                 description: "Repository owner (organization or username)",
                                    optional: false,
                                        type: String,
                               verify_block: proc do |value|
                                  UI.user_error!("No repository owner provided, pass using `repo_owner: 'owner'`") if value.to_s.empty?
                                end),
            FastlaneCore::ConfigItem.new(key: :repo_name,
                                 description: "Repository name",
                                    optional: false,
                                        type: String,
                               verify_block: proc do |value|
                                  UI.user_error!("No repository name provided, pass using `repo_name: 'name'`") if value.to_s.empty?
                                end),
            FastlaneCore::ConfigItem.new(key: :title,
                                 description: "The title of the milestone",
                                    optional: false,
                                        type: String,
                               verify_block: proc do |value|
                                  UI.user_error!("No title provided, pass using `title: 'v1.0'`") if value.to_s.empty?
                                end),
            FastlaneCore::ConfigItem.new(key: :state,
                                 description: "The state of the milestone (open or closed)",
                                    optional: true,
                               default_value: "open",
                                        type: String,
                                 verify_block: proc do |value|
                                   UI.user_error!("State must be 'open' or 'closed'") unless ['open', 'closed'].include?(value)
                                 end),
            FastlaneCore::ConfigItem.new(key: :description,
                                 description: "A description of the milestone",
                                    optional: true,
                                        type: String),
            FastlaneCore::ConfigItem.new(key: :due_on,
                                 description: "The milestone due date in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)",
                                    optional: true,
                                        type: String)
          ]
        end

        def output
          [
            ['GITHUB_CREATE_MILESTONE_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_CREATE_MILESTONE_RESPONSE', 'The full response from the GitHub API'],
            ['GITHUB_CREATE_MILESTONE_JSON', 'The JSON data returned from the GitHub API']
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
            'github_create_milestone(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              title: "v1.0",
              description: "First stable release",
              due_on: "2023-12-31T23:59:59Z"
            )',
            '# You can also access the response data
            result = github_create_milestone(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              title: "v2.0"
            )
            UI.message("Created milestone number: #{result[:json]["number"]}")'
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