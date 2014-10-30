require 'active_support/concern'
require "batcan/version"
require 'batcan/permissible'
require 'batcan/canable'
require 'batcan/can_result'

module Batcan
  class PolicyError < RuntimeError
  end

  class PermitError < PolicyError
    attr_reader :details, :action

    def initialize(result, action = nil)
      @details = result
      @action = action
      msg = "User is not permitted to #{action ? action : 'perform this action'}"
      msg += ": #{result.message}" if result.message
      super(msg)
    end
  end
end
