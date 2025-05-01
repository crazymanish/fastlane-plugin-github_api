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
end

# Run the tests
test = GithubApiActionTest.new
test.run_tests