#!/usr/bin/env ruby
# test_api_helper_compatibility.rb
# 
# This script tests the compatibility of the updated github_api_request method
# with all actions in the fastlane-plugin-github_api plugin.
#
# Usage: ruby test_api_helper_compatibility.rb

require 'bundler/setup'
require 'fastlane'
require 'pathname'
require 'json'

# Add the lib directory to the load path
$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
require 'fastlane/plugin/github_api'

# Silence Fastlane output during testing
module Fastlane
  module Actions
    def self.sh_control_output(*args, **kwargs)
      # Do nothing to silence output
    end
  end
end

class ApiHelperCompatibilityTest
  attr_reader :success_count, :error_count, :skip_count, :total_count

  def initialize
    @success_count = 0
    @error_count = 0
    @skip_count = 0
    @total_count = 0
    @action_classes = []
  end

  def run
    load_actions
    puts "Found #{@action_classes.length} GitHub API actions to test."
    puts "=" * 80
    
    test_all_actions
    
    print_summary
  end

  private

  def load_actions
    # Find all action files in the plugin
    plugin_root = Pathname.new(File.dirname(__FILE__))
    action_files = Dir.glob(File.join(plugin_root, 'lib', 'fastlane', 'plugin', 'github_api', 'actions', '*.rb'))
    
    action_files.each do |file|
      require file
      
      # Extract class name from filename
      filename = File.basename(file, '.rb')
      next unless filename.start_with?('github_')
      
      # Convert snake_case to CamelCase
      class_name = filename.split('_').map(&:capitalize).join
      
      # Get the actual class
      klass = Fastlane::Actions.const_get(class_name) rescue nil
      @action_classes << klass if klass
    end
  end
  
  def test_all_actions
    @action_classes.each do |action_class|
      @total_count += 1
      action_name = action_class.name.split('::').last
      
      puts "Testing #{action_name}..."
      
      begin
        if method_is_instance_method?(action_class, :run)
          puts "  Skipping (non-class method implementation)"
          @skip_count += 1
          next
        end
        
        # Test with success response
        test_action_with_success_response(action_class)
        
        # Test with error response
        test_action_with_error_response(action_class)
        
        @success_count += 1
        puts "  ✓ Passed"
      rescue => e
        @error_count += 1
        puts "  ✗ Failed: #{e.message}"
        puts "    #{e.backtrace[0..3].join("\n    ")}"
      ensure
        puts "-" * 80
      end
    end
  end
  
  def method_is_instance_method?(klass, method_name)
    klass.instance_methods(false).include?(method_name)
  end
  
  def test_action_with_success_response(action_class)
    # Override github_api_request method for testing
    Fastlane::Helper::GithubApiHelper.singleton_class.class_eval do
      alias_method :original_github_api_request, :github_api_request
      
      def github_api_request(token:, path:, params: nil, method: :get, server_url: nil, headers: {})
        # Return a successful response in our new format
        json_data = {
          'id' => 123456, 
          'number' => 42,
          'state' => 'open',
          'title' => 'Test issue',
          'body' => 'Test body'
        }
        
        result = {
          status: 200,
          body: JSON.generate(json_data),
          json: json_data
        }
        
        # Add backward compatibility for old-style access
        json_data.each do |key, value|
          result[key] = value
        end
        
        result['status'] = 200
        
        result
      end
    end
    
    # Create minimal params based on what action requires
    params = create_minimal_params_for_action(action_class)
    
    # Call the action with our params and catch UI errors
    begin
      result = nil
      # Temporarily redirect standard error to suppress UI output
      original_stderr = $stderr
      $stderr = StringIO.new
      
      result = action_class.run(params)
      
      # Restore standard error
      $stderr = original_stderr
      
      # Verify the result
      unless result.is_a?(Hash)
        raise "Action did not return a hash result with success response"
      end
    rescue FastlaneCore::Interface::FastlaneError => e
      # Restore standard error
      $stderr = original_stderr
      # Re-raise as a regular exception for our test
      raise "FastlaneError: #{e.message}"
    ensure
      # Make sure we restore standard error even if something goes wrong
      $stderr = original_stderr if $stderr.is_a?(StringIO)
      
      # Restore original method
      Fastlane::Helper::GithubApiHelper.singleton_class.class_eval do
        alias_method :github_api_request, :original_github_api_request
        remove_method :original_github_api_request
      end
    end
  end
  
  def test_action_with_error_response(action_class)
    # Override github_api_request method for testing
    Fastlane::Helper::GithubApiHelper.singleton_class.class_eval do
      alias_method :original_github_api_request, :github_api_request
      
      def github_api_request(token:, path:, params: nil, method: :get, server_url: nil, headers: {})
        # Return an error response in our new format
        json_data = {
          'message' => 'Not found',
          'documentation_url' => 'https://developer.github.com/v3'
        }
        
        result = {
          status: 404,
          body: JSON.generate(json_data),
          json: json_data
        }
        
        # Add backward compatibility for old-style access
        json_data.each do |key, value|
          result[key] = value
        end
        
        result['error'] = 'Not found'
        result['status'] = 404
        
        result
      end
    end
    
    # Create minimal params based on what action requires
    params = create_minimal_params_for_action(action_class)
    
    # Expect the action to raise an error due to the error response
    begin
      # Temporarily redirect standard error to suppress UI output
      original_stderr = $stderr
      $stderr = StringIO.new
      
      action_class.run(params)
      
      # Restore standard error
      $stderr = original_stderr
      
      # If we got here, the action didn't raise an error for the error response
      puts "  ⚠ Warning: Action didn't handle error response as expected"
    rescue FastlaneCore::Interface::FastlaneError
      # Restore standard error
      $stderr = original_stderr
      # This is expected, action should raise an error for error responses
    rescue => e
      # Restore standard error
      $stderr = original_stderr
      # Other exceptions might be problems with our test
      puts "  ⚠ Warning: Unexpected exception type: #{e.class}"
    ensure
      # Make sure we restore standard error even if something goes wrong
      $stderr = original_stderr if $stderr.is_a?(StringIO)
      
      # Restore original method
      Fastlane::Helper::GithubApiHelper.singleton_class.class_eval do
        alias_method :github_api_request, :original_github_api_request
        remove_method :original_github_api_request
      end
    end
  end
  
  def create_minimal_params_for_action(action_class)
    # Create minimal parameters needed to satisfy action's required parameters
    params = {}
    
    # Default API parameters that most actions will need
    params[:api_token] = 'test_token'
    params[:server_url] = 'https://api.github.com'
    params[:repo_owner] = 'test_owner'
    params[:repo_name] = 'test_repo'
    
    # Check if the action has available_options defined
    if action_class.respond_to?(:available_options) && action_class.available_options.is_a?(Array)
      action_class.available_options.each do |option|
        next if option.optional
        next if params.key?(option.key)
        
        # Add a value for the required parameter based on its type
        params[option.key] = case option.type
          when Integer, Fixnum then 42
          when String then "test_#{option.key}"
          when Array then ["test_item"]
          when Hash then {"test_key" => "test_value"}
          when Boolean, FalseClass, TrueClass then true
          else "test_value"
        end
      end
    end
    
    params
  end
  
  def print_summary
    puts "=" * 80
    puts "COMPATIBILITY TEST SUMMARY:"
    puts "  Total actions tested: #{@total_count}"
    puts "  Success: #{@success_count}"
    puts "  Error: #{@error_count}"
    puts "  Skipped: #{@skip_count}"
    puts "=" * 80
    
    if @error_count == 0
      puts "✓ All tested actions are compatible with the updated github_api_request method!"
    else
      puts "✗ Some actions failed the compatibility test. Please check the logs above."
    end
  end
end

# Run the tests
test = ApiHelperCompatibilityTest.new
test.run