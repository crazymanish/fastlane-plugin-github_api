require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_ADD_LABELS_RESPONSE = :GITHUB_ADD_LABELS_RESPONSE
      GITHUB_ADD_LABELS_JSON = :GITHUB_ADD_LABELS_JSON
      GITHUB_ADD_LABELS_STATUS_CODE = :GITHUB_ADD_LABELS_STATUS_CODE
    end

    class GithubAddLabelsAction < Action
      class << self
        def run(params)
          token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          issue_number = params[:issue_number]
          labels = params[:labels]
          
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
          UI.message("Adding labels to issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          server_url = params[:server_url]
          response = Helper::GithubApiHelper.github_api_request(
            token: token,
            server_url: server_url,
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
          
          # Print labels for confirmation
          if response.is_a?(Array) && !response.empty?
            label_names = response.map { |label| label['name'] }.join(', ')
            UI.success("Successfully added labels to issue ##{issue_number}: #{label_names}")
          else
            UI.success("Successfully updated issue ##{issue_number}")
          end
          
          # Set the shared values
          Actions.lane_context[SharedValues::GITHUB_ADD_LABELS_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_ADD_LABELS_RESPONSE] = response
          Actions.lane_context[SharedValues::GITHUB_ADD_LABELS_JSON] = response
          
          return result
        end

        #####################################################
        # @!group Documentation
        #####################################################

        def description
          "Adds labels to a GitHub issue"
        end

        def details
          [
            "This action adds one or more labels to a specific issue in a GitHub repository.",
            "It requires a valid GitHub API token with appropriate permissions.",
            "Documentation: [https://docs.github.com/en/rest/issues/labels](https://docs.github.com/en/rest/issues/labels#add-labels-to-an-issue)"
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
            FastlaneCore::ConfigItem.new(key: :issue_number,
                                 description: "The issue number to add labels to",
                                    optional: false,
                                        type: Integer),
            FastlaneCore::ConfigItem.new(key: :labels,
                                 description: "Array of label names to add to the issue",
                                    optional: false,
                                        type: Array,
                               verify_block: proc do |value|
                                  UI.user_error!("No labels provided, pass using `labels: ['bug']`") if value.nil? || value.empty?
                                end)
          ]
        end

        def output
          [
            ['GITHUB_ADD_LABELS_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_ADD_LABELS_RESPONSE', 'The full response from the GitHub API'],
            ['GITHUB_ADD_LABELS_JSON', 'The JSON data returned from the GitHub API']
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
            'github_add_labels(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              labels: ["bug", "enhancement"]
            )',
            '# You can also access the response data
            result = github_add_labels(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              issue_number: 123,
              labels: ["bug", "critical"]
            )
            UI.message("Labels added: #{result[:json].map { |label| label["name"] }.join(", ")}")'
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