module Batcan
  # this module is meant to be included within an active model. It provides the ability
  # to call save or destroy with special store and trash varients, which take into account
  # user security.
  # A thread level User.current value must also be defined in order for this module to function
  # correctly. The SentientUser gem can be used to easily provide this functionality.
  module Storable
    extend ActiveSupport::Concern

    included do
      define_callbacks :store, :trash
    end

    # raises an CurrentUserNotSetError if user is not set
    def assert_current_user
      raise CurrentUserNotSetError unless User.current
    end

    def assert_user_can(raise_error, action, options)
      raise_error ? user_can!(action, options) : user_can?(action, options)
    end

    # checks that the current user is able to perform the action on this object. Will add a permission_issue
    # value into the errors collection if user is unable to perform the action.
    # Usage: foo.user_can?(:save)
    def user_can?(action, options = {})
      options = {field: options} if options.is_a? Symbol
      result = user_can(action, options)

      unless result.ok?
        errors.add(:permission_issue, result.message || 'User does not have permission to perform this action')
      end

      result.ok?
    end

    # checks that the current user is able to perform the action on this object. Will raise
    # an PermitError if user is unable to perform the action.
    # Usage: foo.user_can!(:save)
    def user_can!(action, options = {})
      assert_current_user
      User.current.can!(action, self, options)
      true
    end

    def user_can(action, options = {})
      assert_current_user
      User.current.can(action, self, options)
    end

    # wraps save method with policy security. Ensures that the acting user is assigned and can
    # save the object
    def store
      assert_current_user
      if user_can?(:save)
        run_callbacks :store do
          save
        end
      else
        false
      end
    end

    # wraps save! method with policy security. Ensures that the acting user is assigned and can
    # save the object
    def store!
      assert_current_user
      user_can!(:save)
      run_callbacks :store do
        save!
      end
    end

    def store_attributes(attrs)
      assert_current_user
      if user_can?(:update, :fields => attrs.keys)
        run_callbacks :store do
          update_attributes(attrs)
        end
      else
        false
      end
    end

    def store_attributes!(attrs)
      assert_current_user
      user_can!(:update, :fields => attrs.keys)
      run_callbacks :store do
        update_attributes!(attrs)
      end
    end

    # wraps destroy with policy security. Ensures that the acting user is assigned and can
    # save the object
    def trash
      assert_current_user
      if user_can?(:delete)
        destroy
      else
        false
      end
    end

    # wraps destroy! with asserted policy security. Ensures that the acting user is assigned and can
    # save the object
    def trash!
      assert_current_user
      user_can!(:delete)
      destroy!
    end
  end
end