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
        # @return [Hash] Response from the GitHub API
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
            
            if status_code.between?(200, 299)
              # Parse JSON response if available
              if response.body && !response.body.empty? && response.headers['Content-Type'] && response.headers['Content-Type'].include?('application/json')
                return JSON.parse(response.body)
              else
                return response.body || true
              end
            else
              # Handle error with informative error message
              error_body = response.body ? parse_json(response.body) : {}
              error_message = error_body['message'] || response.body || 'Unknown error'
              return {
                'error' => "HTTP Error #{status_code}: #{error_message}",
                'status_code' => status_code,
                'body' => response.body
              }
            end
          rescue => ex
            return {
              'error' => "Network Error: #{ex.message}"
            }
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
