# encoding: UTF-8

require 'active_support/concern'
require 'cassette/authentication/user'

module Cassette::Authentication::Filter
  extend ActiveSupport::Concern

  included do |controller|
    controller.before_filter(:validate_authentication_ticket)
    controller.send(:attr_accessor, :current_user)
  end

  module ClassMethods
    def skip_authentication(*options)
      skip_before_filter :validate_authentication_ticket, *options
    end
  end

  def validate_authentication_ticket(service = Cassette.config.service)
    ticket = request.headers['Service-Ticket'] || params[:ticket]

    if ENV['NOAUTH']
      Cassette.logger.debug 'NOAUTH set and no Service Ticket, skipping authentication'
      self.current_user = Cassette::Authentication::User.new
      return
    end

    self.current_user = Cassette::Authentication.validate_ticket(ticket, service)
  end

  def validate_role!(role)
    return if ENV['NOAUTH']
    fail Cassette::Errors::Forbidden unless current_user.has_role?(role)
  end

  def validate_raw_role!(role)
    return if ENV['NOAUTH']
    fail Cassette::Errors::Forbidden unless current_user.has_raw_role?(role)
  end
end
