require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_LIST_REPO_ISSUE_EVENTS_RESPONSE = :GITHUB_LIST_REPO_ISSUE_EVENTS_RESPONSE
      GITHUB_LIST_REPO_ISSUE_EVENTS_JSON = :GITHUB_LIST_REPO_ISSUE_EVENTS_JSON
      GITHUB_LIST_REPO_ISSUE_EVENTS_STATUS_CODE = :GITHUB_LIST_REPO_ISSUE_EVENTS_STATUS_CODE
    end

    class GithubListRepoIssueEventsAction < Action
      class << self
        def run(params)
          token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          server_url = params[:server_url]
          
          # Validate parameters (additional validation beyond what's in ConfigItem)
          UI.user_error!("No repository owner provided, pass using `repo_owner: 'owner'`") if repo_owner.to_s.empty?
          UI.user_error!("No repository name provided, pass using `repo_name: 'name'`") if repo_name.to_s.empty?
          
          # Prepare request parameters
          path = "/repos/#{repo_owner}/#{repo_name}/issues/events"
          
          # Build query parameters
          query_params = {}
          query_params[:per_page] = params[:per_page] if params[:per_page]
          query_params[:page] = params[:page] if params[:page]
          
          # Make the request
          UI.message("Fetching issue events for repository #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: token,
            path: path,
            params: query_params,
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
          
          if response.is_a?(Hash) && response['message'] && status_code && status_code >= 400
            UI.error("GitHub API error: #{response['message']}")
            UI.user_error!("GitHub API error: #{response['message']} (Status code: #{status_code})")
            return nil
          end
          
          # Print event count
          if response.is_a?(Array)
            UI.success("Successfully fetched #{response.count} issue events from #{repo_owner}/#{repo_name}")
          else
            UI.success("Successfully fetched repository issue events from #{repo_owner}/#{repo_name}")
          end
          
          # Set the shared values
          Actions.lane_context[SharedValues::GITHUB_LIST_REPO_ISSUE_EVENTS_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_LIST_REPO_ISSUE_EVENTS_RESPONSE] = response
          Actions.lane_context[SharedValues::GITHUB_LIST_REPO_ISSUE_EVENTS_JSON] = response
          
          return result
        end

        #####################################################
        # @!group Documentation
        #####################################################

        def description
          "Lists issue events for a GitHub repository"
        end

        def details
          [
            "This action fetches a list of issue events for an entire GitHub repository.",
            "It requires a valid GitHub API token with appropriate permissions.",
            "Documentation: [https://docs.github.com/en/rest/issues/events](https://docs.github.com/en/rest/issues/events#list-issue-events-for-a-repository)"
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
            FastlaneCore::ConfigItem.new(key: :per_page,
                                 description: "Results per page (max 100)",
                                    optional: true,
                               default_value: 30,
                                        type: Integer),
            FastlaneCore::ConfigItem.new(key: :page,
                                 description: "Page number of the results",
                                    optional: true,
                               default_value: 1,
                                        type: Integer)
          ]
        end

        def output
          [
            ['GITHUB_LIST_REPO_ISSUE_EVENTS_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_LIST_REPO_ISSUE_EVENTS_RESPONSE', 'The full response from the GitHub API'],
            ['GITHUB_LIST_REPO_ISSUE_EVENTS_JSON', 'The JSON data returned from the GitHub API']
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
            'github_list_repo_issue_events(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane"
            )',
            '# You can also access the response data
            result = github_list_repo_issue_events(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              per_page: 100
            )
            result[:json].each do |event|
              UI.message("Event: #{event["event"]}, issue: ##{event["issue"]["number"]}")
            end'
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