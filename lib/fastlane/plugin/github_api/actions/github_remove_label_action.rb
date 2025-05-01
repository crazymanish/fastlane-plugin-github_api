require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_REMOVE_LABEL_RESPONSE = :GITHUB_REMOVE_LABEL_RESPONSE
      GITHUB_REMOVE_LABEL_JSON = :GITHUB_REMOVE_LABEL_JSON
      GITHUB_REMOVE_LABEL_STATUS_CODE = :GITHUB_REMOVE_LABEL_STATUS_CODE
    end

    class GithubRemoveLabelAction < Action
      class << self
        def run(params)
          token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          issue_number = params[:issue_number]
          label_name = params[:label_name]
          server_url = params[:server_url]
          
          # Validate parameters (additional validation beyond what's in ConfigItem)
          UI.user_error!("No GitHub issue number given, pass using `issue_number: 123`") unless issue_number.to_s.length > 0
          UI.user_error!("No label name provided, pass using `label_name: 'bug'`") if label_name.to_s.empty?
          
          # Prepare request parameters
          # URL encode the label name to handle special characters like spaces, etc.
          encoded_label = URI.encode_www_form_component(label_name)
          path = "/repos/#{repo_owner}/#{repo_name}/issues/#{issue_number}/labels/#{encoded_label}"
          
          # Make the request
          UI.message("Removing label '#{label_name}' from issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: token,
            path: path,
            method: :delete,
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
          
          UI.success("Successfully removed label '#{label_name}' from issue ##{issue_number}")
          
          # Set the shared values
          Actions.lane_context[SharedValues::GITHUB_REMOVE_LABEL_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_REMOVE_LABEL_RESPONSE] = response
          Actions.lane_context[SharedValues::GITHUB_REMOVE_LABEL_JSON] = response
          
          return result
        end

        #####################################################
        # @!group Documentation
        #####################################################

        def description
          "Removes a label from a GitHub issue"
        end

        def details
          [
            "This action removes a specific label from an issue in a GitHub repository.",
            "It requires a valid GitHub API token with appropriate permissions.",
            "Documentation: [https://docs.github.com/en/rest/issues/labels](https://docs.github.com/en/rest/issues/labels#remove-a-label-from-an-issue)"
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
            FastlaneCore::ConfigItem.new(key: :issue_number,
                                 env_name: "GITHUB_API_ISSUE_NUMBER",
                                 description: "The issue number to remove the label from",
                                    optional: false,
                                        type: Integer),
            FastlaneCore::ConfigItem.new(key: :label_name,
                                 description: "The name of the label to remove",
                                    optional: false,
                                        type: String,
                               verify_block: proc do |value|
                                  UI.user_error!("No label name provided, pass using `label_name: 'bug'`") if value.to_s.empty?
                                end)
          ]
        end

        def output
          [
            ['GITHUB_REMOVE_LABEL_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_REMOVE_LABEL_RESPONSE', 'The full response from the GitHub API'],
            ['GITHUB_REMOVE_LABEL_JSON', 'The JSON data returned from the GitHub API']
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
            'github_remove_label(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              label_name: "bug"
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