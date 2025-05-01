require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_UPDATE_LABEL_RESPONSE = :GITHUB_UPDATE_LABEL_RESPONSE
      GITHUB_UPDATE_LABEL_JSON = :GITHUB_UPDATE_LABEL_JSON
      GITHUB_UPDATE_LABEL_STATUS_CODE = :GITHUB_UPDATE_LABEL_STATUS_CODE
    end

    class GithubUpdateLabelAction < Action
      class << self
        def run(params)
          token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          label_name = params[:name]
          
          # Validate parameters (additional validation beyond what's in ConfigItem)
          UI.user_error!("No label name provided, pass using `name: 'bug'`") if label_name.to_s.empty?
          
          # Prepare request parameters
          # URL encode the label name to handle special characters like spaces, etc.
          encoded_label = URI.encode_www_form_component(label_name)
          path = "/repos/#{repo_owner}/#{repo_name}/labels/#{encoded_label}"
          
          # Build body parameters
          body_params = {}
          body_params[:new_name] = params[:new_name] if params[:new_name]
          
          if params[:color]
            body_params[:color] = params[:color].start_with?('#') ? params[:color][1..-1] : params[:color]
          end
          
          body_params[:description] = params[:description] if params[:description]
          
          # Make the request
          UI.message("Updating label '#{label_name}' in #{repo_owner}/#{repo_name}")
          server_url = params[:server_url]
          response = Helper::GithubApiHelper.github_api_request(
            token: token,
            server_url: server_url,
            path: path,
            params: body_params,
            method: :patch
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
          
          new_name = params[:new_name] || label_name
          UI.success("Successfully updated label '#{new_name}' in #{repo_owner}/#{repo_name}")
          
          # Set the shared values
          Actions.lane_context[SharedValues::GITHUB_UPDATE_LABEL_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_UPDATE_LABEL_RESPONSE] = response
          Actions.lane_context[SharedValues::GITHUB_UPDATE_LABEL_JSON] = response
          
          return result
        end

        #####################################################
        # @!group Documentation
        #####################################################

        def description
          "Updates a label in a GitHub repository"
        end

        def details
          [
            "This action updates an existing label in a GitHub repository, allowing changes to its name, color, and description.",
            "It requires a valid GitHub API token with appropriate permissions.",
            "Documentation: [https://docs.github.com/en/rest/issues/labels](https://docs.github.com/en/rest/issues/labels#update-a-label)"
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
            FastlaneCore::ConfigItem.new(key: :name,
                                 description: "The current name of the label",
                                    optional: false,
                                        type: String,
                               verify_block: proc do |value|
                                  UI.user_error!("No label name provided, pass using `name: 'bug'`") if value.to_s.empty?
                                end),
            FastlaneCore::ConfigItem.new(key: :new_name,
                                 description: "The new name for the label",
                                    optional: true,
                                        type: String),
            FastlaneCore::ConfigItem.new(key: :color,
                                 description: "The color of the label in hexadecimal format (with or without leading #)",
                                    optional: true,
                                        type: String,
                                 verify_block: proc do |value|
                                   value = value[1..-1] if value.start_with?('#')
                                   UI.user_error!("Color must be a valid 6 character hex code") unless value.match?(/^[0-9A-Fa-f]{6}$/)
                                 end),
            FastlaneCore::ConfigItem.new(key: :description,
                                 description: "A short description of the label",
                                    optional: true,
                                        type: String)
          ]
        end

        def output
          [
            ['GITHUB_UPDATE_LABEL_STATUS_CODE', 'The status code returned from the GitHub API'],
            ['GITHUB_UPDATE_LABEL_RESPONSE', 'The full response from the GitHub API'],
            ['GITHUB_UPDATE_LABEL_JSON', 'The JSON data returned from the GitHub API']
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
            'github_update_label(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              name: "bug",
              new_name: "confirmed-bug",
              color: "b60205",
              description: "Confirmed bugs that need to be fixed"
            )',
            '# You can also access the response data
            result = github_update_label(
              api_token: ENV["GITHUB_API_TOKEN"],
              repo_owner: "fastlane",
              repo_name: "fastlane",
              name: "enhancement",
              color: "a2eeef"
            )
            UI.message("Updated label color: #{result[:json]["color"]}")'
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