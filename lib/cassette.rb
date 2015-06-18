# encoding: UTF-8

require 'cassette/errors'
require 'cassette/cache'
require 'cassette/client/cache'
require 'cassette/client'
require 'cassette/authentication'
require 'cassette/authentication/authorities'
require 'cassette/authentication/user'
require 'cassette/authentication/cache'
require 'cassette/authentication/filter'

require 'faraday'
require 'logger'

module Cassette
  extend self

  attr_writer :config, :logger

  DEFAULT_TIMEOUT = 10

  def logger
    @logger ||= begin
                  if defined?(::Rails) && ::Rails.logger
                    ::Rails.logger
                  else
                    Logger.new('/dev/null')
                  end
                end
  end

  def config
    @config if defined?(@config)
  end

  def new_request(uri, timeout)
    Faraday.new(url: uri, ssl: { verify: false, version: 'TLSv1' }) do |builder|
      builder.adapter Faraday.default_adapter
      builder.options.timeout = timeout
    end
  end

  def post(uri, payload, timeout = DEFAULT_TIMEOUT)
    perform(:post, uri, timeout) do |req|
      req.body = URI.encode_www_form(payload)
      logger.debug "Request: #{req.inspect}"
    end
  end

  protected

  def perform(op, uri, timeout = DEFAULT_TIMEOUT, &block)
    request = new_request(uri, timeout)
    res = request.send(op, &block)

    res.tap do |response|
      logger.debug "Got response: #{response.body.inspect} (#{response.status}), #{response.headers.inspect}"
      Cassette::Errors.raise_by_code(response.status) unless response.success?
    end
  end
end
