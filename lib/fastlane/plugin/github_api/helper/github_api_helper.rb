require 'fastlane_core/ui/ui'
require 'excon'
require 'json'
require 'uri'

module Fastlane
  module Helper
    class GithubApiHelper
      class << self
        # Make a request to the GitHub API
        # @param token [String] GitHub API token
        # @param path [String] API endpoint path
        # @param params [Hash] Query parameters for GET or body parameters for POST/PUT/PATCH
        # @param method [Symbol] HTTP method (:get, :post, :put, :patch, :delete)
        # @param server_url [String] GitHub API server URL
        # @param headers [Hash] Additional headers to include in the request
        # @return [Hash] Response from the GitHub API with :status, :body, and :json keys
        def github_api_request(token: nil, path:, params: nil, method: :get, server_url: nil, headers: {})
          require 'json'
          
          # Validate parameters
          UI.user_error!("No GitHub API token given, pass using `token: 'token'`") if token.to_s.empty?
          UI.user_error!("GitHub API path cannot be empty") if path.to_s.empty?
          UI.user_error!("GitHub API server URL cannot be empty") if server_url.to_s.empty?
          
          # Set up headers
          request_headers = headers.clone || {}
          request_headers['User-Agent'] = 'fastlane-github_api'
          request_headers['Authorization'] = "token #{token}" if token
          request_headers['Accept'] = 'application/vnd.github.v3+json' unless request_headers.key?('Accept')
          
          # Handle query parameters for GET requests
          if method == :get && params && !params.empty?
            query_string = URI.encode_www_form(params)
            path = "#{path}?#{query_string}"
            params = nil
          end
          
          # Prepare the URL
          url = "#{server_url}#{path}"
          
          begin
            UI.verbose("#{method.to_s.upcase} : #{url}")
            
            # Set up Excon options
            options = {
              headers: request_headers,
              middlewares: Excon.defaults[:middlewares] + [Excon::Middleware::RedirectFollower],
              debug_request: FastlaneCore::Globals.verbose?,
              debug_response: FastlaneCore::Globals.verbose?
            }
            
            # Add body for non-GET requests if params are provided
            if method != :get && params
              if params.is_a?(Hash) || params.is_a?(Array)
                options[:body] = params.to_json
                request_headers['Content-Type'] = 'application/json'
              else
                options[:body] = params
              end
            end
            
            # Make the request
            connection = Excon.new(url)
            response = connection.request(
              method: method,
              **options
            )
            
            status_code = response.status
            response_body = response.body.to_s
            
            # Parse JSON response if available
            json_response = nil
            if !response_body.empty? && response.headers['Content-Type'] && response.headers['Content-Type'].include?('application/json')
              json_response = parse_json(response_body) || {}
            end
            
            # Create the response hash with both new format and backward compatibility
            result = {
              status: status_code,
              body: response_body,
              json: json_response
            }
            
            # Add backward compatibility for error handling
            # Copy json values to top level for backwards compatibility
            if json_response.is_a?(Hash)
              json_response.each do |key, value|
                result[key] = value
              end
            end
            
            # Add status code at the top level for backward compatibility
            result['status'] = status_code
            
            return result
          rescue => ex
            error_result = {
              status: 0,
              body: ex.message,
              json: { 'error' => "Network Error: #{ex.message}" }
            }
            
            # Add backward compatibility for error handling
            error_result['error'] = "Network Error: #{ex.message}"
            error_result['status'] = 0
            
            return error_result
          end
        end
        
        private
        
        def parse_json(value)
          JSON.parse(value)
        rescue JSON::ParserError
          nil
        end
      end
    end
  end
end
