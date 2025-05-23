require 'fastlane/action'
require_relative '../helper/github_api_helper'

module Fastlane
  module Actions
    module SharedValues
      GITHUB_CREATE_ISSUE_REACTION_STATUS_CODE = :GITHUB_CREATE_ISSUE_REACTION_STATUS_CODE
      GITHUB_CREATE_ISSUE_REACTION_RESPONSE = :GITHUB_CREATE_ISSUE_REACTION_RESPONSE
      GITHUB_CREATE_ISSUE_REACTION_JSON = :GITHUB_CREATE_ISSUE_REACTION_JSON
    end

    class GithubCreateIssueReactionAction < Action
      class << self
        def run(params)
          require 'json'
          
          # Prepare API call parameters
          server_url = params[:server_url]
          api_token = params[:api_token]
          repo_owner = params[:repo_owner]
          repo_name = params[:repo_name]
          issue_number = params[:issue_number]
          content = params[:content]
          
          # Build the request body
          body = {
            content: content
          }
          
          # Build the path
          path = "/repos/#{repo_owner}/#{repo_name}/issues/#{issue_number}/reactions"
          
          UI.message("Creating '#{content}' reaction for issue ##{issue_number} in #{repo_owner}/#{repo_name}")
          response = Helper::GithubApiHelper.github_api_request(
            token: api_token,
            path: path,
            params: body,
            method: :post,
            server_url: server_url,
            headers: { 'Accept' => 'application/vnd.github.squirrel-girl-preview+json' }
          )
          
          status_code = response[:status]
          json_response = response[:json]
          result = {
            status: status_code,
            body: response[:body],
            json: json_response
          }
          
          if status_code.between?(200, 299)
            UI.success("Successfully created '#{content}' reaction for issue ##{issue_number}")
          else
            UI.error("Error creating reaction: #{status_code}")
            UI.error(response[:body])
            UI.user_error!("GitHub API returned #{status_code}: #{response[:body]}")
            return nil
          end
          
          # Store the results in shared values
          Actions.lane_context[SharedValues::GITHUB_CREATE_ISSUE_REACTION_STATUS_CODE] = status_code
          Actions.lane_context[SharedValues::GITHUB_CREATE_ISSUE_REACTION_RESPONSE] = response[:body]
          Actions.lane_context[SharedValues::GITHUB_CREATE_ISSUE_REACTION_JSON] = json_response
          
          return result
        end
        
        #####################################################
        # @!group Documentation
        #####################################################
        
        def description
          "Create a reaction for an issue"
        end
        
        def details
          [
            "Creates a reaction for an issue.",
            "You must provide your GitHub Personal token (get one from https://github.com/settings/tokens/new).",
            "API Documentation: https://docs.github.com/en/rest/reactions/reactions#create-reaction-for-an-issue"
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
            FastlaneCore::ConfigItem.new(key: :issue_number,
                                 env_name: "GITHUB_API_ISSUE_NUMBER",
                              description: "The number of the issue",
                                 optional: false,
                                     type: Integer),
            FastlaneCore::ConfigItem.new(key: :content,
                                 env_name: "GITHUB_API_REACTION_CONTENT",
                              description: "The reaction type (+1, -1, laugh, confused, heart, hooray, rocket, eyes)",
                                 optional: false,
                                     type: String,
                             verify_block: proc do |value|
                               valid_reactions = ['+1', '-1', 'laugh', 'confused', 'heart', 'hooray', 'rocket', 'eyes']
                               UI.user_error!("Invalid reaction content: '#{value}'. Must be one of: #{valid_reactions.join(', ')}") unless valid_reactions.include?(value)
                             end)
          ]
        end

        def output
          [
            ['GITHUB_CREATE_ISSUE_REACTION_STATUS_CODE', 'The status code returned by the GitHub API'],
            ['GITHUB_CREATE_ISSUE_REACTION_RESPONSE', 'The full response body returned by the GitHub API'],
            ['GITHUB_CREATE_ISSUE_REACTION_JSON', 'The parsed JSON response returned by the GitHub API']
          ]
        end

        def return_value
          "Returns a hash containing the status code, response body, and parsed JSON response from the GitHub API."
        end

        def authors
          ["crazymanish"]
        end

        def is_supported?(platform)
          true
        end
        
        def example_code
          [
            'github_create_issue_reaction(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              issue_number: 123,
              content: "+1"
            )',
            'reaction = github_create_issue_reaction(
              repo_owner: "octocat",
              repo_name: "Hello-World",
              issue_number: 123,
              content: "heart"
            )
            
            puts "Created reaction: #{reaction[:json]["content"]}"
            puts "Reaction ID: #{reaction[:json]["id"]}"'
          ]
        end
      end
    end
  end
end
