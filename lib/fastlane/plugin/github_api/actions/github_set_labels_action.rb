require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_SET_LABELS_RESPONSE = :GITHUB_SET_LABELS_RESPONSE
      GITHUB_SET_LABELS_JSON = :GITHUB_SET_LABELS_JSON
      GITHUB_SET_LABELS_STATUS_CODE = :GITHUB_SET_LABELS_STATUS_CODE
    end

    class GithubSetLabelsAction < Action
      class << self
        def run(params)
          token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          issue_number = params[:issue_number]
          labels = params[:labels]
          server_url = params[:server_url]
          
          # Validate parameters (additional validation beyond what's in ConfigItem)
          UI.user_error!("No GitHub issue number given, pass using `issue_number: 123`") unless issue_number.to_s.length > 0
          UI.user_error!("No labels provided, pass using `labels: ['bug', 'feature']`") if labels.nil? || labels.empty?
          
          # Prepare request parameters
          path = "/repos/#{repo_owner}/#{repo_name}/issues/#{issue_number}/labels"
          
          # Build body parameters
          body_params = {
            labels: labels
          }
          
          # Make the request
          UI.message("Setting labels on issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: token,
            path: path,
            params: body_params,
            method: :put,
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
          
          if response['message'] && status_code && status_code >= 400
            UI.error("GitHub API error: #{response['message']}")
            UI.user_error!("GitHub API error: #{response['message']} (Status code: #{status_code})")
            return nil
          end
          
          # Print labels for confirmation
          if response.is_a?(Array) && !response.empty?
            label_names = response.map { |label| label['name'] }.join(', ')
            UI.success("Successfully set labels on issue ##{issue_number}: #{label_names}")
          else
            UI.success("Successfully updated labels on issue ##{issue_number}")
          end
          
          # Set the shared values
          Actions.lane_context[SharedValues::GITHUB_SET_LABELS_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_SET_LABELS_RESPONSE] = response
          Actions.lane_context[SharedValues::GITHUB_SET_LABELS_JSON] = response
          
          return result
        end

        #####################################################
        # @!group Documentation
        #####################################################

        def description
          "Replaces all labels on a GitHub issue"
        end

        def details
          [
            "This action replaces all existing labels on an issue with the specified list of labels.",
            "It requires a valid GitHub API token with appropriate permissions.",
            "Documentation: [https://docs.github.com/en/rest/issues/labels](https://docs.github.com/en/rest/issues/labels)"
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
                                 description: "The issue number to set labels on",
                                    optional: false,
                                        type: Integer),
            FastlaneCore::ConfigItem.new(key: :labels,
                                 description: "Array of label names to set on the issue",
                                    optional: false,
                                        type: Array,
                               verify_block: proc do |value|
                                  UI.user_error!("No labels provided, pass using `labels: ['bug']`") if value.nil? || value.empty?
                                end)
          ]
        end

        def output
          [
            ['GITHUB_SET_LABELS_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_SET_LABELS_RESPONSE', 'The full response from the GitHub API'],
            ['GITHUB_SET_LABELS_JSON', 'The JSON data returned from the GitHub API']
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
            'github_set_labels(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              labels: ["feature", "reviewed"]
            )',
            '# You can also access the response data
            result = github_set_labels(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              labels: ["bug", "critical"]
            )
            UI.message("Labels set: #{result[:json].map { |label| label["name"] }.join(", ")}")'
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