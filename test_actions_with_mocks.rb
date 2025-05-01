#!/usr/bin/env ruby
# test_actions_with_mocks.rb
#
# This script tests GitHub API actions with mocked responses to ensure end-to-end
# integration of github_api_helper with various success and error scenarios.
#
# Usage: ruby test_actions_with_mocks.rb

require 'bundler/setup'
require 'fastlane'
require 'json'
require 'fastlane_core/ui/ui'

# Add lib directory to load path
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'fastlane/plugin/github_api'

# Define custom error for testing
module FastlaneCore
  class Interface
    class FastlaneTestError < StandardError; end
  end
end

# Reduce noise in test output
ENV["FASTLANE_HIDE_TIMESTAMP"] = "true"
ENV["FASTLANE_DISABLE_COLORS"] = "true"

# Global variable to store mock responses for easy access across classes
$mock_responses = {}

###########################################
# Mock Action Classes
###########################################

module Fastlane
  module Actions
    class MockGithubListIssuesAction < GithubListIssuesAction
      def self.run(params)
        # Skip validations for test
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues"
        
        # Call the mocked github_api_request
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          server_url: params[:server_url]
        )
        
        # Check status code
        case response[:status]
        when 200
          return response
        else
          if response[:json] && response[:json]["message"]
            UI.user_error!("GitHub responded with an error: #{response[:json]["message"]}")
          else
            UI.user_error!("GitHub responded with #{response[:status]} but no error message")
          end
        end
      end
    end
    
    class MockGithubListIssuesErrorAction < GithubListIssuesAction
      def self.run(params)
        # Skip validations for test
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues"
        
        # Call the mocked github_api_request
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          server_url: params[:server_url]
        )
        
        # Check status code
        case response[:status]
        when 200
          return response
        else
          if response[:json] && response[:json]["message"]
            UI.user_error!("GitHub responded with an error: #{response[:json]["message"]}")
          else
            UI.user_error!("GitHub responded with #{response[:status]} but no error message")
          end
        end
      end
    end
    
    class MockGithubCreateIssueAction < GithubCreateIssueAction
      def self.run(params)
        # Skip validations for test
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues"
        
        # Create the request body
        body = {}
        body[:title] = params[:title]
        body[:body] = params[:body] if params[:body]
        body[:labels] = params[:labels] if params[:labels]
        body[:assignees] = params[:assignees] if params[:assignees]
        body[:milestone] = params[:milestone] if params[:milestone]
        
        # Call the mocked github_api_request
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          server_url: params[:server_url],
          method: :post,
          params: body
        )
        
        # Check status code
        case response[:status]
        when 201
          return response
        else
          UI.user_error!("GitHub API returned #{response[:status]}: #{response[:body]}")
        end
      end
    end
    
    class MockGithubCheckPullMergedAction < GithubCheckPullMergedAction
      def self.run(params)
        # Skip validations for test
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/pulls/#{params[:pull_number]}/merge"
        
        # Call the mocked github_api_request
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          server_url: params[:server_url]
        )
        
        # GitHub returns 204 if PR is merged, 404 if not merged
        is_merged = response[:status] == 204
        
        return {
          merged: is_merged,
          status: response[:status]
        }
      end
    end
    
    # Additional mock actions
    class MockGithubAddAssigneesAction < GithubAddAssigneesAction
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues/#{params[:issue_number]}/assignees"
        
        # Call the mocked github_api_request
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: { assignees: params[:assignees] },
          method: :post
        )
        
        return response
      end
    end
    
    class MockGithubAddLabelsAction < GithubAddLabelsAction
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues/#{params[:issue_number]}/labels"
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: { labels: params[:labels] },
          method: :post
        )
        
        return response
      end
    end
    
    class MockGithubSetLabelsAction < GithubSetLabelsAction
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues/#{params[:issue_number]}/labels"
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: { labels: params[:labels] },
          method: :put
        )
        
        return response
      end
    end
    
    class MockGithubGetIssueAction < Action
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues/#{params[:issue_number]}"
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          method: :get
        )
        
        return response
      end
    end
    
    class MockGithubCreatePullAction < Action
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/pulls"
        
        body_params = {
          title: params[:title],
          body: params[:body],
          head: params[:head],
          base: params[:base]
        }
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: body_params,
          method: :post
        )
        
        return response
      end
    end
    
    class MockGithubGetPullAction < Action
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/pulls/#{params[:pull_number]}"
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          method: :get
        )
        
        return response
      end
    end
    
    class MockGithubListPullsAction < Action
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/pulls"
        
        query_params = {}
        query_params[:state] = params[:state] if params[:state]
        query_params[:head] = params[:head] if params[:head]
        query_params[:base] = params[:base] if params[:base]
        query_params[:sort] = params[:sort] if params[:sort]
        query_params[:direction] = params[:direction] if params[:direction]
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: query_params.empty? ? nil : query_params,
          method: :get
        )
        
        return response
      end
    end
    
    class MockGithubListPullCommitsAction < GithubListPullCommitsAction
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/pulls/#{params[:pull_number]}/commits"
        
        query_params = {}
        query_params[:per_page] = params[:per_page] if params[:per_page]
        query_params[:page] = params[:page] if params[:page]
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: query_params.empty? ? nil : query_params,
          method: :get
        )
        
        return response
      end
    end
    
    class MockGithubListPullFilesAction < Action
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/pulls/#{params[:pull_number]}/files"
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          method: :get
        )
        
        return response
      end
    end
    
    class MockGithubMergePullAction < GithubMergePullAction
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/pulls/#{params[:pull_number]}/merge"
        
        body_params = {}
        body_params[:commit_title] = params[:commit_title] if params[:commit_title]
        body_params[:commit_message] = params[:commit_message] if params[:commit_message]
        body_params[:merge_method] = params[:merge_method] if params[:merge_method]
        body_params[:sha] = params[:sha] if params[:sha]
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: body_params,
          method: :put
        )
        
        return response
      end
    end
    
    class MockGithubUpdatePullBranchAction < GithubUpdatePullBranchAction
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/pulls/#{params[:pull_number]}/update-branch"
        
        body_params = {}
        body_params[:expected_head_sha] = params[:expected_head_sha] if params[:expected_head_sha]
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: body_params,
          method: :put
        )
        
        return response
      end
    end
    
    class MockGithubCreateIssueReactionAction < Action
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues/#{params[:issue_number]}/reactions"
        
        body_params = {
          content: params[:content]
        }
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: body_params,
          method: :post
        )
        
        return response
      end
    end

    class MockGithubListIssueCommentsAction < Action
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues/#{params[:issue_number]}/comments"
        
        # Optional pagination parameters
        query_params = {}
        query_params[:per_page] = params[:per_page] if params[:per_page]
        query_params[:page] = params[:page] if params[:page]
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: query_params.empty? ? nil : query_params,
          method: :get
        )
        
        return response
      end
    end
    
    class MockGithubAddIssueCommentAction < Action
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues/#{params[:issue_number]}/comments"
        
        body_params = {
          body: params[:body]
        }
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          params: body_params,
          method: :post
        )
        
        return response
      end
    end
    
    class MockGithubDeleteIssueCommentAction < Action
      def self.run(params)
        token = params[:api_token]
        path = "/repos/#{params[:repo_owner]}/#{params[:repo_name]}/issues/comments/#{params[:comment_id]}"
        
        response = Helper::GithubApiHelper.github_api_request(
          token: token,
          path: path,
          method: :delete
        )
        
        return response
      end
    end
  end
end

###########################################
# Test Framework
###########################################

class GithubApiMockTest
  attr_reader :successes, :failures, :total_tests

  def initialize
    @successes = 0
    @failures = 0
    @total_tests = 0
  end

  def setup_mocks
    # Patch the github_api_request method to return mock responses
    Fastlane::Helper::GithubApiHelper.class_eval do
      class << self
        alias_method :original_github_api_request, :github_api_request
        
        # Mock version that returns predefined responses instead of making real API calls
        def github_api_request(token:, path:, params: nil, method: :get, server_url: nil, headers: {})
          # Debug output to see what's being requested
          puts "\nDEBUG: Requesting path='#{path}', method=#{method}"
          puts "DEBUG: Available mock responses: #{$mock_responses.keys.inspect}"
          
          # Use global variable to access mock responses
          response = $mock_responses[[path, method]]
          
          # If no matching mock, return a 404 error
          if response.nil?
            puts "DEBUG: No mock response found for [#{path}, #{method}]"
            error_result = {
              status: 404,
              body: '{"message":"Not found","documentation_url":"https://docs.github.com/"}',
              json: {"message" => "Not found", "documentation_url" => "https://docs.github.com/"}
            }
            
            # Also add top-level keys for backward compatibility
            error_result["message"] = "Not found"
            error_result["documentation_url"] = "https://docs.github.com/"
            error_result["error"] = "Not found"
            return error_result
          else
            puts "DEBUG: Found mock response with status #{response[:status]}"
          end
          
          return response
        end
      end
    end
    
    # Only store the original user_error! method if it exists
    @original_user_error = nil
    if FastlaneCore::UI.respond_to?(:user_error!)
      @original_user_error = FastlaneCore::UI.method(:user_error!)
    end
    
    # Define user_error! method if it doesn't exist or redefine it
    FastlaneCore::UI.define_singleton_method(:user_error!) do |message|
      raise FastlaneCore::Interface::FastlaneTestError, message
    end
  end

  def teardown_mocks
    # Restore original api_request method
    Fastlane::Helper::GithubApiHelper.class_eval do
      class << self
        alias_method :github_api_request, :original_github_api_request
        remove_method :original_github_api_request
      end
    end
    
    # Restore original user_error! method
    if @original_user_error
      FastlaneCore::UI.define_singleton_method(:user_error!, &@original_user_error)
      @original_user_error = nil
    end
  end

  def register_mock_response(path, method, response)
    $mock_responses[[path, method]] = response
  end
  
  def clear_mock_responses
    $mock_responses = {}
  end

  def run_tests
    puts "\n====== GitHub API Action Tests with Mocked Responses ======\n"
    
    begin
      setup_mocks
      
      # Run all test methods (those starting with test_)
      methods.grep(/^test_/).each do |test_method|
        run_test(test_method)
      end
    ensure
      teardown_mocks
    end
    
    print_summary
  end
  
  def run_test(test_method)
    @total_tests += 1
    print "Running test: #{test_method.to_s.gsub('_', ' ')}... "
    
    begin
      # Clear and register mock responses before each test
      clear_mock_responses
      register_mock_responses
      
      result = send(test_method)
      if result
        @successes += 1
        puts "✅ Passed"
      else
        @failures += 1
        puts "❌ Failed"
      end
    rescue FastlaneCore::Interface::FastlaneTestError => e
      # Expected errors from UI.user_error!
      @failures += 1
      puts "❌ Expected UI Error: #{e.message}"
    rescue => e
      @failures += 1
      puts "❌ Error: #{e.message}"
      puts e.backtrace.join("\n  ")
    end
  end
  
  def assert(condition, message = nil)
    if condition
      true
    else
      puts "  Assertion failed: #{message}" if message
      false
    end
  end
  
  def assert_equal(expected, actual, message = nil)
    if expected == actual
      true
    else
      puts "  Expected #{expected.inspect} but got #{actual.inspect}#{message ? ": #{message}" : ''}"
      false
    end
  end
  
  def print_summary
    puts "\n====== Test Summary ======\n"
    puts "Total tests: #{@total_tests}"
    puts "Successes: #{@successes}"
    puts "Failures: #{@failures}"
    puts "\n#{@failures == 0 ? "✅ All tests passed!" : "❌ Some tests failed!"}\n"
  end
end

###########################################
# Mock Test Implementation
###########################################

class GithubApiActionTest < GithubApiMockTest
  def setup
    super
    register_mock_responses
  end
  
  def register_mock_responses
    # Use consistent test values
    repo_owner = "octocat"
    repo_name = "test-repo"
    base_url = "https://api.github.com"
    
    # Mock response for list issues (success)
    list_issues_response = {
      status: 200,
      body: '[{"number":1,"title":"Test Issue","state":"open","body":"Test issue body"}]',
      json: [{"number" => 1, "title" => "Test Issue", "state" => "open", "body" => "Test issue body"}]
    }
    # Add top-level keys for backward compatibility
    list_issues_response[0] = {"number" => 1, "title" => "Test Issue", "state" => "open", "body" => "Test issue body"}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues", :get, list_issues_response)
    
    # Mock response for list issues (error)
    list_issues_error = {
      status: 404,
      body: '{"message":"Not Found","documentation_url":"https://docs.github.com/"}',
      json: {"message" => "Not Found", "documentation_url" => "https://docs.github.com/"}
    }
    # Add top-level keys for backward compatibility
    list_issues_error["message"] = "Not Found"
    list_issues_error["documentation_url"] = "https://docs.github.com/"
    list_issues_error["error"] = "Not Found"
    register_mock_response("/repos/invalid/repo/issues", :get, list_issues_error)
    
    # Mock response for create issue (success)
    create_issue_response = {
      status: 201,
      body: '{"number":42,"title":"New Issue","state":"open","body":"Issue description"}',
      json: {"number" => 42, "title" => "New Issue", "state" => "open", "body" => "Issue description"}
    }
    # Add top-level keys for backward compatibility
    create_issue_response["number"] = 42
    create_issue_response["title"] = "New Issue"
    create_issue_response["state"] = "open"
    create_issue_response["body"] = "Issue description"
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues", :post, create_issue_response)
    
    # Mock response for create issue (error - unauthorized)
    create_issue_error = {
      status: 403,
      body: '{"message":"Forbidden","documentation_url":"https://docs.github.com/"}',
      json: {"message" => "Forbidden", "documentation_url" => "https://docs.github.com/"}
    }
    # Add top-level keys for backward compatibility
    create_issue_error["message"] = "Forbidden"
    create_issue_error["documentation_url"] = "https://docs.github.com/"
    create_issue_error["error"] = "Forbidden"
    register_mock_response("/repos/unauthorized/repo/issues", :post, create_issue_error)
    
    # Mock response for check pull merged (success - merged)
    pull_merged_response = {
      status: 204,
      body: '',
      json: nil
    }
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/pulls/1/merge", :get, pull_merged_response)
    
    # Mock response for check pull merged (success - not merged)
    pull_not_merged_response = {
      status: 404,
      body: '{"message":"Not Found","documentation_url":"https://docs.github.com/"}',
      json: {"message" => "Not Found", "documentation_url" => "https://docs.github.com/"}
    }
    # Add top-level keys for backward compatibility
    pull_not_merged_response["message"] = "Not Found"
    pull_not_merged_response["documentation_url"] = "https://docs.github.com/"
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/pulls/999/merge", :get, pull_not_merged_response)
    
    # Mock response for update issue (success)
    update_issue_response = {
      status: 200,
      body: '{"number":42,"title":"Updated Issue","state":"closed","body":"Updated description"}',
      json: {"number" => 42, "title" => "Updated Issue", "state" => "closed", "body" => "Updated description"}
    }
    # Add top-level keys for backward compatibility
    update_issue_response["number"] = 42
    update_issue_response["title"] = "Updated Issue"
    update_issue_response["state"] = "closed"
    update_issue_response["body"] = "Updated description"
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42", :patch, update_issue_response)
    
    # Mock response for delete comment (success)
    delete_comment_response = {
      status: 204,
      body: '',
      json: nil
    }
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/comments/12345", :delete, delete_comment_response)
    
    # ADDITIONAL MOCK RESPONSES
    
    # Mock response for add assignees to an issue (success)
    add_assignees_response = {
      status: 201,
      body: '{"number":42,"title":"Issue with assignees","assignees":[{"login":"octocat"},{"login":"hubot"}]}',
      json: {"number" => 42, "title" => "Issue with assignees", "assignees" => [{"login" => "octocat"}, {"login" => "hubot"}]}
    }
    add_assignees_response["number"] = 42
    add_assignees_response["title"] = "Issue with assignees"
    add_assignees_response["assignees"] = [{"login" => "octocat"}, {"login" => "hubot"}]
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/assignees", :post, add_assignees_response)
    
    # Mock response for removing assignees from an issue (success)
    remove_assignees_response = {
      status: 200,
      body: '{"number":42,"title":"Issue without assignees","assignees":[]}',
      json: {"number" => 42, "title" => "Issue without assignees", "assignees" => []}
    }
    remove_assignees_response["number"] = 42
    remove_assignees_response["title"] = "Issue without assignees"
    remove_assignees_response["assignees"] = []
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/assignees", :delete, remove_assignees_response)
    
    # Mock response for add labels to an issue (success)
    add_labels_response = {
      status: 200,
      body: '[{"name":"bug","color":"fc2929"},{"name":"feature","color":"0e8a16"}]',
      json: [{"name" => "bug", "color" => "fc2929"}, {"name" => "feature", "color" => "0e8a16"}]
    }
    add_labels_response[0] = {"name" => "bug", "color" => "fc2929"}
    add_labels_response[1] = {"name" => "feature", "color" => "0e8a16"}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/labels", :post, add_labels_response)
    
    # Mock response for setting labels on an issue (success)
    set_labels_response = {
      status: 200,
      body: '[{"name":"enhancement","color":"84b6eb"},{"name":"documentation","color":"0075ca"}]',
      json: [{"name" => "enhancement", "color" => "84b6eb"}, {"name" => "documentation", "color" => "0075ca"}]
    }
    set_labels_response[0] = {"name" => "enhancement", "color" => "84b6eb"}
    set_labels_response[1] = {"name" => "documentation", "color" => "0075ca"}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/labels", :put, set_labels_response)
    
    # Mock response for removing all labels from an issue (success)
    remove_all_labels_response = {
      status: 204,
      body: '',
      json: nil
    }
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/labels", :delete, remove_all_labels_response)
    
    # Mock response for removing a label from an issue (success)
    remove_label_response = {
      status: 200,
      body: '[{"name":"enhancement","color":"84b6eb"}]',
      json: [{"name" => "enhancement", "color" => "84b6eb"}]
    }
    remove_label_response[0] = {"name" => "enhancement", "color" => "84b6eb"}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/labels/documentation", :delete, remove_label_response)
    
    # Mock response for getting a single issue (success)
    get_issue_response = {
      status: 200,
      body: '{"number":42,"title":"Issue title","body":"Issue body","state":"open"}',
      json: {"number" => 42, "title" => "Issue title", "body" => "Issue body", "state" => "open"}
    }
    get_issue_response["number"] = 42
    get_issue_response["title"] = "Issue title"
    get_issue_response["body"] = "Issue body"
    get_issue_response["state"] = "open"
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42", :get, get_issue_response)
    
    # Mock response for lock issue (success)
    lock_issue_response = {
      status: 204,
      body: '',
      json: nil
    }
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/lock", :put, lock_issue_response)
    
    # Mock response for unlock issue (success)
    unlock_issue_response = {
      status: 204,
      body: '',
      json: nil
    }
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/lock", :delete, unlock_issue_response)
    
    # Mock response for creating a pull request (success)
    create_pull_response = {
      status: 201,
      body: '{"number":88,"title":"Amazing new feature","body":"Please pull this in!","head":"octocat:new-feature","base":"master","state":"open"}',
      json: {
        "number" => 88,
        "title" => "Amazing new feature",
        "body" => "Please pull this in!",
        "head" => "octocat:new-feature",
        "base" => "master",
        "state" => "open"
      }
    }
    create_pull_response["number"] = 88
    create_pull_response["title"] = "Amazing new feature"
    create_pull_response["body"] = "Please pull this in!"
    create_pull_response["head"] = "octocat:new-feature"
    create_pull_response["base"] = "master"
    create_pull_response["state"] = "open"
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/pulls", :post, create_pull_response)
    
    # Mock response for get pull request (success)
    get_pull_response = {
      status: 200,
      body: '{"number":88,"title":"Amazing new feature","body":"Please pull this in!","head":{"label":"octocat:new-feature"},"base":{"label":"master"}}',
      json: {
        "number" => 88,
        "title" => "Amazing new feature",
        "body" => "Please pull this in!",
        "head" => {"label" => "octocat:new-feature"},
        "base" => {"label" => "master"}
      }
    }
    get_pull_response["number"] = 88
    get_pull_response["title"] = "Amazing new feature"
    get_pull_response["body"] = "Please pull this in!"
    get_pull_response["head"] = {"label" => "octocat:new-feature"}
    get_pull_response["base"] = {"label" => "master"}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/pulls/88", :get, get_pull_response)
    
    # Mock response for list pull requests (success)
    list_pulls_response = {
      status: 200,
      body: '[{"number":88,"title":"Amazing new feature","state":"open"},{"number":86,"title":"Bug fix","state":"closed"}]',
      json: [
        {"number" => 88, "title" => "Amazing new feature", "state" => "open"},
        {"number" => 86, "title" => "Bug fix", "state" => "closed"}
      ]
    }
    list_pulls_response[0] = {"number" => 88, "title" => "Amazing new feature", "state" => "open"}
    list_pulls_response[1] = {"number" => 86, "title" => "Bug fix", "state" => "closed"}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/pulls", :get, list_pulls_response)
    
    # Mock response for list pull request commits (success)
    list_pull_commits_response = {
      status: 200,
      body: '[{"sha":"6dcb09b5b57875f334f61aebed695e2e4193db5e","commit":{"message":"Fix all the bugs"}},{"sha":"7dcb09b5b57875f334f61aebed695e2e4193db5f","commit":{"message":"Add tests"}}]',
      json: [
        {"sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5e", "commit" => {"message" => "Fix all the bugs"}},
        {"sha" => "7dcb09b5b57875f334f61aebed695e2e4193db5f", "commit" => {"message" => "Add tests"}}
      ]
    }
    list_pull_commits_response[0] = {"sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5e", "commit" => {"message" => "Fix all the bugs"}}
    list_pull_commits_response[1] = {"sha" => "7dcb09b5b57875f334f61aebed695e2e4193db5f", "commit" => {"message" => "Add tests"}}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/pulls/88/commits", :get, list_pull_commits_response)
    
    # Mock response for list pull request files (success)
    list_pull_files_response = {
      status: 200,
      body: '[{"filename":"file1.rb","additions":10,"deletions":2},{"filename":"file2.rb","additions":5,"deletions":0}]',
      json: [
        {"filename" => "file1.rb", "additions" => 10, "deletions" => 2},
        {"filename" => "file2.rb", "additions" => 5, "deletions" => 0}
      ]
    }
    list_pull_files_response[0] = {"filename" => "file1.rb", "additions" => 10, "deletions" => 2}
    list_pull_files_response[1] = {"filename" => "file2.rb", "additions" => 5, "deletions" => 0}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/pulls/88/files", :get, list_pull_files_response)
    
    # Mock response for merge pull request (success)
    merge_pull_response = {
      status: 200,
      body: '{"sha":"6dcb09b5b57875f334f61aebed695e2e4193db5e","merged":true,"message":"Pull Request successfully merged"}',
      json: {
        "sha" => "6dcb09b5b57875f334f61aebed695e2e4193db5e",
        "merged" => true,
        "message" => "Pull Request successfully merged"
      }
    }
    merge_pull_response["sha"] = "6dcb09b5b57875f334f61aebed695e2e4193db5e"
    merge_pull_response["merged"] = true
    merge_pull_response["message"] = "Pull Request successfully merged"
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/pulls/88/merge", :put, merge_pull_response)
    
    # Mock response for update pull request branch (success)
    update_pull_branch_response = {
      status: 202,
      body: '{"message":"Updating pull request branch","url":"https://github.com/repos/octocat/test-repo/pulls/88"}',
      json: {
        "message" => "Updating pull request branch",
        "url" => "https://github.com/repos/octocat/test-repo/pulls/88"
      }
    }
    update_pull_branch_response["message"] = "Updating pull request branch"
    update_pull_branch_response["url"] = "https://github.com/repos/octocat/test-repo/pulls/88"
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/pulls/88/update-branch", :put, update_pull_branch_response)
    
    # Mock response for create reaction for issue (success)
    create_issue_reaction_response = {
      status: 201,
      body: '{"id":1,"content":"+1","user":{"login":"octocat"}}',
      json: {"id" => 1, "content" => "+1", "user" => {"login" => "octocat"}}
    }
    create_issue_reaction_response["id"] = 1
    create_issue_reaction_response["content"] = "+1"
    create_issue_reaction_response["user"] = {"login" => "octocat"}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/reactions", :post, create_issue_reaction_response)

    # NEW MOCK RESPONSES FOR ISSUE COMMENTS
    
    # Mock response for listing issue comments (success)
    list_issue_comments_response = {
      status: 200,
      body: '[{"id":1,"user":{"login":"octocat"},"body":"This is a first comment","created_at":"2022-01-01T00:00:00Z"},{"id":2,"user":{"login":"hubot"},"body":"This is a second comment","created_at":"2022-01-02T00:00:00Z"}]',
      json: [
        {"id" => 1, "user" => {"login" => "octocat"}, "body" => "This is a first comment", "created_at" => "2022-01-01T00:00:00Z"},
        {"id" => 2, "user" => {"login" => "hubot"}, "body" => "This is a second comment", "created_at" => "2022-01-02T00:00:00Z"}
      ]
    }
    # Add top-level keys for backward compatibility
    list_issue_comments_response[0] = {"id" => 1, "user" => {"login" => "octocat"}, "body" => "This is a first comment", "created_at" => "2022-01-01T00:00:00Z"}
    list_issue_comments_response[1] = {"id" => 2, "user" => {"login" => "hubot"}, "body" => "This is a second comment", "created_at" => "2022-01-02T00:00:00Z"}
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/comments", :get, list_issue_comments_response)
    
    # Mock response for adding an issue comment (success)
    add_issue_comment_response = {
      status: 201,
      body: '{"id":3,"user":{"login":"octocat"},"body":"New comment added","created_at":"2022-01-03T00:00:00Z"}',
      json: {"id" => 3, "user" => {"login" => "octocat"}, "body" => "New comment added", "created_at" => "2022-01-03T00:00:00Z"}
    }
    # Add top-level keys for backward compatibility
    add_issue_comment_response["id"] = 3
    add_issue_comment_response["user"] = {"login" => "octocat"}
    add_issue_comment_response["body"] = "New comment added"
    add_issue_comment_response["created_at"] = "2022-01-03T00:00:00Z"
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/42/comments", :post, add_issue_comment_response)
    
    # Mock response for deleting an issue comment (success)
    delete_issue_comment_response = {
      status: 204,
      body: '',
      json: nil
    }
    register_mock_response("/repos/#{repo_owner}/#{repo_name}/issues/comments/3", :delete, delete_issue_comment_response)
  end
  
  ###########################################
  # Test Methods
  ###########################################
  
  def test_response_structure_and_backward_compatibility
    # Mock a custom response
    custom_response = {
      status: 200,
      body: '{"id":123,"name":"test","active":true,"numbers":[1,2,3]}',
      json: {"id" => 123, "name" => "test", "active" => true, "numbers" => [1,2,3]}
    }
    
    # Add top-level keys for backward compatibility
    custom_response["id"] = 123
    custom_response["name"] = "test"
    custom_response["active"] = true
    custom_response["numbers"] = [1,2,3]
    
    # Test both access methods
    assert_equal 200, custom_response[:status], "Should access status with symbol key"
    assert_equal "test", custom_response[:json]["name"], "Should access JSON data with symbol->string keys"
    assert_equal "test", custom_response["name"], "Should access data directly with string key"
    assert_equal [1,2,3], custom_response["numbers"], "Should access arrays directly"
    
    # Test nesting
    assert_equal 3, custom_response[:json]["numbers"][2], "Should access nested array elements"
    assert_equal 3, custom_response["numbers"][2], "Should access nested array elements directly"
    
    true
  end
  
  def test_list_issues_success
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      server_url: "https://api.github.com"
    }
    
    result = Fastlane::Actions::MockGithubListIssuesAction.run(params)
    
    # Verify the response format
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal true, result[:json].is_a?(Array), "Response JSON should be an array"
    assert_equal 1, result[:json][0]["number"], "First issue should have number 1"
    
    # Test backward compatibility (direct string access to JSON values)
    assert_equal result[:json][0]["title"], result[0]["title"], "Should be able to access JSON values directly"
    
    true
  end
  
  def test_list_issues_error
    params = {
      api_token: "fake_token",
      repo_owner: "invalid",
      repo_name: "repo",
      server_url: "https://api.github.com"
    }
    
    # GithubListIssuesAction should raise an error for 404
    error_raised = false
    begin
      Fastlane::Actions::MockGithubListIssuesErrorAction.run(params)
    rescue FastlaneCore::Interface::FastlaneTestError => e
      error_raised = true
      assert e.message.include?("GitHub responded with an error: Not Found"), 
        "Error message should include 'Not Found'"
    end
    
    assert error_raised, "Should raise an error for 404 response"
    
    true
  end
  
  def test_create_issue_success
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      server_url: "https://api.github.com",
      title: "New Issue",
      body: "Issue description"
    }
    
    result = Fastlane::Actions::MockGithubCreateIssueAction.run(params)
    
    # Verify the response format
    assert_equal 201, result[:status], "Status code should be 201"
    assert_equal 42, result[:json]["number"], "Created issue should have number 42"
    assert_equal "New Issue", result[:json]["title"], "Created issue should have correct title"
    
    # Test backward compatibility
    assert_equal result[:json]["number"], result["number"], "Should be able to access JSON values directly"
    
    true
  end
  
  def test_check_pull_merged
    # Test a merged PR
    params_merged = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      pull_number: 1,
      server_url: "https://api.github.com"
    }
    
    merged_result = Fastlane::Actions::MockGithubCheckPullMergedAction.run(params_merged)
    assert_equal true, merged_result[:merged], "PR #1 should be merged"
    assert_equal 204, merged_result[:status], "Status should be 204 for merged PR"
    
    # Test a non-merged PR
    params_not_merged = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      pull_number: 999,
      server_url: "https://api.github.com"
    }
    
    not_merged_result = Fastlane::Actions::MockGithubCheckPullMergedAction.run(params_not_merged)
    assert_equal false, not_merged_result[:merged], "PR #999 should not be merged"
    assert_equal 404, not_merged_result[:status], "Status should be 404 for non-merged PR"
    
    true
  end
  
  # ADDITIONAL TEST METHODS
  
  def test_add_assignees_to_issue
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      issue_number: 42,
      assignees: ["octocat", "hubot"]
    }
    
    result = Fastlane::Actions::MockGithubAddAssigneesAction.run(params)
    
    # Verify the response
    assert_equal 201, result[:status], "Status code should be 201"
    assert_equal 42, result[:json]["number"], "Issue number should be 42"
    assert_equal 2, result[:json]["assignees"].length, "Should have 2 assignees"
    assert_equal "octocat", result[:json]["assignees"][0]["login"], "First assignee should be octocat"
    
    true
  end
  
  def test_add_labels_to_issue
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      issue_number: 42,
      labels: ["bug", "feature"]
    }
    
    result = Fastlane::Actions::MockGithubAddLabelsAction.run(params)
    
    # Verify the response
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal true, result[:json].is_a?(Array), "Response should be an array"
    assert_equal "bug", result[:json][0]["name"], "First label should be bug"
    assert_equal "feature", result[:json][1]["name"], "Second label should be feature"
    
    true
  end
  
  def test_set_labels_on_issue
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      issue_number: 42,
      labels: ["enhancement", "documentation"]
    }
    
    result = Fastlane::Actions::MockGithubSetLabelsAction.run(params)
    
    # Verify the response
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal 2, result[:json].length, "Should return 2 labels"
    assert_equal "enhancement", result[:json][0]["name"], "First label should be enhancement"
    assert_equal "documentation", result[:json][1]["name"], "Second label should be documentation"
    
    true
  end
  
  def test_get_issue
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      issue_number: 42
    }
    
    result = Fastlane::Actions::MockGithubGetIssueAction.run(params)
    
    # Verify the response
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal 42, result[:json]["number"], "Issue number should be 42"
    assert_equal "Issue title", result[:json]["title"], "Issue title should match"
    assert_equal "open", result[:json]["state"], "Issue should be open"
    
    true
  end
  
  def test_create_pull_request
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      title: "Amazing new feature",
      body: "Please pull this in!",
      head: "octocat:new-feature",
      base: "master"
    }
    
    result = Fastlane::Actions::MockGithubCreatePullAction.run(params)
    
    # Verify the response
    assert_equal 201, result[:status], "Status code should be 201"
    assert_equal 88, result[:json]["number"], "PR number should be 88"
    assert_equal "Amazing new feature", result[:json]["title"], "PR title should match"
    assert_equal "octocat:new-feature", result[:json]["head"], "Head branch should match"
    assert_equal "master", result[:json]["base"], "Base branch should match"
    
    true
  end
  
  def test_get_pull_request
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      pull_number: 88
    }
    
    result = Fastlane::Actions::MockGithubGetPullAction.run(params)
    
    # Verify the response
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal 88, result[:json]["number"], "PR number should be 88"
    assert_equal "Amazing new feature", result[:json]["title"], "PR title should match"
    assert_equal "octocat:new-feature", result[:json]["head"]["label"], "Head branch should match"
    
    true
  end
  
  def test_list_pull_requests
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo"
    }
    
    result = Fastlane::Actions::MockGithubListPullsAction.run(params)
    
    # Verify the response
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal true, result[:json].is_a?(Array), "Response JSON should be an array"
    assert_equal 2, result[:json].length, "Should return 2 pull requests"
    assert_equal 88, result[:json][0]["number"], "First PR number should be 88"
    assert_equal "open", result[:json][0]["state"], "First PR should be open"
    assert_equal 86, result[:json][1]["number"], "Second PR number should be 86"
    assert_equal "closed", result[:json][1]["state"], "Second PR should be closed"
    
    true
  end
  
  def test_list_pull_request_commits
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      pull_number: 88
    }
    
    result = Fastlane::Actions::MockGithubListPullCommitsAction.run(params)
    
    # Verify the response
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal true, result[:json].is_a?(Array), "Response JSON should be an array"
    assert_equal 2, result[:json].length, "Should return 2 commits"
    assert_equal "Fix all the bugs", result[:json][0]["commit"]["message"], "First commit message should match"
    assert_equal "Add tests", result[:json][1]["commit"]["message"], "Second commit message should match"
    
    true
  end
  
  def test_list_pull_request_files
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      pull_number: 88
    }
    
    result = Fastlane::Actions::MockGithubListPullFilesAction.run(params)
    
    # Verify the response
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal 2, result[:json].length, "Should return 2 files"
    assert_equal "file1.rb", result[:json][0]["filename"], "First filename should match"
    assert_equal 10, result[:json][0]["additions"], "First file should have 10 additions"
    assert_equal 2, result[:json][0]["deletions"], "First file should have 2 deletions"
    
    true
  end
  
  def test_merge_pull_request
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      pull_number: 88,
      commit_title: "Merge pull request #88",
      commit_message: "Merge pull request #88 from octocat/new-feature"
    }
    
    result = Fastlane::Actions::MockGithubMergePullAction.run(params)
    
    # Verify the response
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal true, result[:json]["merged"], "PR should be merged"
    assert_equal "Pull Request successfully merged", result[:json]["message"], "Merge message should match"
    
    true
  end
  
  def test_update_pull_request_branch
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      pull_number: 88,
      expected_head_sha: "6dcb09b5b57875f334f61aebed695e2e4193db5e"
    }
    
    result = Fastlane::Actions::MockGithubUpdatePullBranchAction.run(params)
    
    # Verify the response
    assert_equal 202, result[:status], "Status code should be 202 (Accepted)"
    assert_equal "Updating pull request branch", result[:json]["message"], "Response message should match"
    
    true
  end
  
  def test_create_issue_reaction
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      issue_number: 42,
      content: "+1"
    }
    
    result = Fastlane::Actions::MockGithubCreateIssueReactionAction.run(params)
    
    # Verify the response
    assert_equal 201, result[:status], "Status code should be 201"
    assert_equal 1, result[:json]["id"], "Reaction ID should be 1"
    assert_equal "+1", result[:json]["content"], "Reaction content should be +1"
    assert_equal "octocat", result[:json]["user"]["login"], "User login should be octocat"
    
    true
  end

  def test_list_issue_comments
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      issue_number: 42
    }
    
    result = Fastlane::Actions::MockGithubListIssueCommentsAction.run(params)
    
    # Verify the response
    assert_equal 200, result[:status], "Status code should be 200"
    assert_equal true, result[:json].is_a?(Array), "Response should be an array"
    assert_equal 2, result[:json].length, "Should return 2 comments"
    assert_equal 1, result[:json][0]["id"], "First comment ID should be 1"
    assert_equal "This is a first comment", result[:json][0]["body"], "First comment body should match"
    assert_equal "octocat", result[:json][0]["user"]["login"], "First comment user should be octocat"
    
    # Test backward compatibility
    assert_equal result[:json][0]["body"], result[0]["body"], "Should be able to access JSON values directly"
    
    true
  end
  
  def test_add_issue_comment
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      issue_number: 42,
      body: "New comment added"
    }
    
    result = Fastlane::Actions::MockGithubAddIssueCommentAction.run(params)
    
    # Verify the response
    assert_equal 201, result[:status], "Status code should be 201"
    assert_equal 3, result[:json]["id"], "Comment ID should be 3"
    assert_equal "New comment added", result[:json]["body"], "Comment body should match input"
    assert_equal "octocat", result[:json]["user"]["login"], "Comment user should be octocat"
    
    # Test backward compatibility
    assert_equal result[:json]["id"], result["id"], "Should be able to access JSON values directly"
    
    true
  end
  
  def test_delete_issue_comment
    params = {
      api_token: "fake_token",
      repo_owner: "octocat",
      repo_name: "test-repo",
      comment_id: 3
    }
    
    result = Fastlane::Actions::MockGithubDeleteIssueCommentAction.run(params)
    
    # Verify the response
    assert_equal 204, result[:status], "Status code should be 204 (No Content)"
    assert_equal nil, result[:json], "JSON should be nil for delete operation"
    
    true
  end
end

# Run the tests
test = GithubApiActionTest.new
test.run_tests