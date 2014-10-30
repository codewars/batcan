module Batcan
  module Canable
    include Batcan::Permissible
    extend ActiveSupport::Concern

    def can!(action, target = self, options = {})
      result = can(action, target, options)
      raise PermitError.new(result, action) unless result.ok?
      true
    end

    def can?(action, target = self, options = {})
      can(action, target, options).ok?
    end

    def can(action, target = self, options = {})
      action = self.class.normalize_action_name(action)

      # if the target is a class than create an instance of it so that it can be evaluated using default values
      target = target.new if target.is_a? Class

      # get the custom permissions from the target itself
      result = target.permissible?(self, action, options)

      # if the target returned nil then we are to fall back onto the default permissions
      result = default_can?(action, target, options) if result.nil?

      # check field permissions on dirty fields for top level actions if field permissions are defined for the target class
      if result == true and !options[:field] and target.respond_to? :changed and target.class.has_field_permissions?
        target.changed.each do |f|
          f = f.to_sym
          options[:field] = f
          options[:field_only] = true
          field_result = target.permissible?(self, action, options)

          # if the field is ok then reset it in the options so that it isnt sent to CanResult
          if field_result == true or field_result.nil?
            options[:field] = nil
          else
            result = field_result
            break
          end
        end
      end

      CanResult.new(action, target, options, result)
    end

    # override to provide default permissions
    def default_can?(action, target, options = {})
      true
    end
  end
end