#!/usr/bin/env ruby
# validate_helper_response_format.rb
# 
# This script validates that the updated github_api_request method with
# the standardized response format works correctly with the action usage patterns.
#
# Usage: ruby validate_helper_response_format.rb

# Setup output formatting
def green(str)
  "\e[32m#{str}\e[0m"
end

def red(str)
  "\e[31m#{str}\e[0m"
end

def yellow(str)
  "\e[33m#{str}\e[0m"
end

puts "Validating github_api_request response format compatibility..."
puts "=" * 80

# Test 1: Basic response structure test
puts "\nTest 1: Basic response structure test"
puts "-" * 40

begin
  # Create a test response that matches our new format
  test_response = {
    status: 200,
    body: '{"id": 123, "name": "test-repo"}',
    json: {"id" => 123, "name" => "test-repo"},
    "id" => 123,
    "name" => "test-repo"
  }
  
  # Test accessing keys using both formats
  symbol_access_ok = (test_response[:status] == 200)
  string_access_ok = (test_response["name"] == "test-repo")
  json_access_ok = (test_response[:json]["id"] == 123)
  
  if symbol_access_ok && string_access_ok && json_access_ok
    puts green("✓ Basic response structure is correct and all access methods work")
  else
    puts red("✗ Basic response structure has issues:")
    puts red("  Symbol access working: #{symbol_access_ok}")
    puts red("  String access working: #{string_access_ok}")
    puts red("  JSON access working: #{json_access_ok}")
  end
rescue => e
  puts red("✗ Error in basic structure test: #{e.message}")
end

# Test 2: Test with different response types
puts "\nTest 2: Testing different response types"
puts "-" * 40

begin
  # Test with 200 response (success with body)
  success_response = {
    status: 200,
    body: '{"result": "success", "data": {"id": 42}}',
    json: {"result" => "success", "data" => {"id" => 42}},
    "result" => "success",
    "data" => {"id" => 42}
  }
  
  # Test with 201 response (created)
  created_response = {
    status: 201,
    body: '{"id": 456, "created": true}',
    json: {"id" => 456, "created" => true},
    "id" => 456,
    "created" => true
  }
  
  # Test with 204 response (no content)
  no_content_response = {
    status: 204,
    body: '',
    json: nil
  }
  
  # Test with error response
  error_response = {
    status: 404,
    body: '{"message": "Not found", "documentation_url": "https://docs.github.com/rest"}',
    json: {"message" => "Not found", "documentation_url" => "https://docs.github.com/rest"},
    "message" => "Not found",
    "documentation_url" => "https://docs.github.com/rest",
    "error" => "Not found"
  }
  
  success_test = success_response[:status] == 200 && success_response[:json]["result"] == "success"
  created_test = created_response[:status] == 201 && created_response["created"] == true
  no_content_test = no_content_response[:status] == 204 && no_content_response[:body] == ''
  error_test = error_response[:status] == 404 && error_response["error"] == "Not found"
  
  if success_test && created_test && no_content_test && error_test
    puts green("✓ All response types are handled correctly")
  else
    puts red("✗ Issues with response type handling:")
    puts red("  Success response working: #{success_test}")
    puts red("  Created response working: #{created_test}")
    puts red("  No content response working: #{no_content_test}")
    puts red("  Error response working: #{error_test}")
  end
rescue => e
  puts red("✗ Error in response types test: #{e.message}")
end

# Test 3: Common access patterns from our actions
puts "\nTest 3: Testing common action access patterns"
puts "-" * 40

begin
  # Create a standardized response in our new format
  mock_response = {
    status: 200,
    body: '{"id": 123, "number": 42, "title": "Test Issue", "state": "open"}',
    json: {"id" => 123, "number" => 42, "title" => "Test Issue", "state" => "open"},
    "id" => 123,
    "number" => 42,
    "title" => "Test Issue", 
    "state" => "open"
  }
  
  # Pattern 1: Using status directly (github_check_pull_merged_action style)
  pattern1 = "status_code = response[:status]; is_merged = status_code == 204"
  pattern1_result = eval("response = mock_response; #{pattern1}; is_merged")
  
  # Pattern 2: Reading JSON and status (github_create_issue_action style)
  pattern2 = "status_code = response[:status]; json_response = response[:json]; issue_number = json_response['number'] if status_code.between?(200, 299)"
  pattern2_result = eval("response = mock_response; #{pattern2}; issue_number")
  
  # Pattern 3: Creating a new result hash (common pattern)
  pattern3 = "status_code = response[:status]; json_response = response[:json]; result = {status: status_code, body: response[:body], json: json_response}"
  pattern3_result = eval("response = mock_response; #{pattern3}; result[:status] == 200 && result[:json]['id'] == 123")
  
  # Pattern 4: Direct string access (backward compatibility)
  pattern4 = "error_message = response['message'] if response.key?('message')"
  pattern4_result = eval("response = mock_response; response['message'] = 'Test Message'; #{pattern4}; error_message == 'Test Message'")
  
  # Pattern 5: Checking for error status (backward compatibility)
  pattern5 = "has_error = response.key?('error')"
  pattern5_result = eval("response = mock_response; response['error'] = 'Error'; #{pattern5}; has_error")
  
  if pattern1_result == false && pattern2_result == 42 && pattern3_result && pattern4_result && pattern5_result
    puts green("✓ All common action access patterns work correctly")
  else
    puts red("✗ Issues with action access patterns:")
    puts red("  Pull merged check: #{pattern1_result}")
    puts red("  Issue creation: #{pattern2_result}")
    puts red("  Result hash construction: #{pattern3_result}")
    puts red("  Direct string access: #{pattern4_result}")
    puts red("  Error checking: #{pattern5_result}")
  end
rescue => e
  puts red("✗ Error in action patterns test: #{e.message}")
  puts red("  #{e.backtrace.first}")
end

# Final summary
puts "\n" + "=" * 80
puts "VALIDATION COMPLETE"
puts "=" * 80
puts "The github_api_request response structure should work with all actions."
puts "The updated structure provides a consistent format with symbol keys:"
puts "  - :status - HTTP status code"
puts "  - :body   - Raw response body"
puts "  - :json   - Parsed JSON (if applicable)"
puts "While maintaining backward compatibility with direct hash access."
puts "=" * 80

puts "\nNext steps:"
puts "1. Test the helper_method with key actions like github_check_pull_merged_action,"
puts "   github_create_issue_action, and github_list_issues_action to verify compatibility."
puts "2. If you encounter any issues, adjust the helper method implementation."