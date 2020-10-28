require 'active_support/concern'
require "batcan/version"
require 'batcan/permissible'
require 'batcan/canable'
require 'batcan/can_result'
require 'batcan/storable'

module Batcan

  class PolicyError < RuntimeError
  end

  class CurrentUserNotSetError < PolicyError
  end

  class PermitError < PolicyError
    attr_reader :details, :action

    def initialize(result, action = nil, target = nil)
      @details = result
      @action = action
      @target = target
      
      msg = "User is not permitted to #{action ? action : 'perform this action'}"
      if target
        msg += " on #{target.class.name}"
      end
      msg += ": #{result.message}" if result.message
      super(msg)
    end
  end
end
