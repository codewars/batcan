module Batcan
  module Permissible
    extend ActiveSupport::Concern

    # method for supporting custom permissions. By default this method returns nil
    # if a specific permission is not defined. In this case the default permissions will be applied
    #
    # actions can be checked on the record itself or on a field/relation.
    # If no field is provided then it is assumed the permit is being requested for the
    # record itself. If a field is provided than the permit is being requested for the field
    # itself. The types of actions are similar but slightly different based off of a field
    # permit being requested.
    #
    # typical record actions:
    #   view
    #   create
    #   update
    #   save (create + update)
    #   delete
    #
    # typical field actions:
    #   view/get
    #   save/set
    #   add
    #   remove
    #   clear
    #

    def permissible?(user, action, options = {})

      # handle case where multiple fields are being checked. Return the first one that has issues
      # if a field is provided then ignore since that should mean its already within the loop
      if options[:fields] && !options[:field]
        options[:fields].each do |field|
          options[:field] = field

          permitted = permissible?(user, action, options)
          return permitted unless permitted == true
        end

        return true
      end

      action = self.class.normalize_action_name(action)

      if respond_to?(:new_record?)
        # naturally you cant delete something that doesnt exist
        return false if action == :delete and new_record?

        # also you can't create something that already exists
        return false if action == :create and not new_record?

        # save actions get mapped to either create or update depending on the state of the object
        if action == :save
          action = new_record? ? :create : :update
        end
      end

      permission = permission_for(action, options)
      permitted = nil

      # get the permit if the permission block exists
      permitted = permission.call(self, user, action, options) if permission

      # if the specific field permit returned default (or doesnt exist) then use the
      # record level view/create/update permits (if available). Ignore if field_only is true
      # because this means we are in a field specific check
      if options[:field] and permitted.nil? and !options[:field_only]
        case action
          when :view
            options[:field_only] = !!options[:fields]
            permission = permission_for(:view)
            permitted = permission.call(self, user, options) if permission

          when :create, :update, :add, :remove, :clear
            if respond_to?(:new_record?)
              options[:field_only] = !!options[:fields]
              permission = permission_for(new_record? ? :create : :update)
              permitted = permission.call(self, user, options) if permission
            end
        end
      end

      permitted
    end

    def permission_for(action, options = {})

      # traverses up the ancestor chain trying to find a class that has the permission defined.
      def recursive_find(klass, action, options)
        config = klass.permissions[action]
        permission = config[options[:field] || '_'] if config
        if !permission && self.class.superclass.respond_to?(:permissions)
          recursive_find(klass.superclass, action, options)
        else
          permission
        end
      end

      recursive_find(self.class, action, options)
    end

    module ClassMethods
      def permissions
        @permissions ||= {has_field_permissions: false}
      end

      # returns true if any field permissions have been defined the model
      def has_field_permissions?
        permissions[:has_field_permissions]
      end

      def normalize_action_name(action)
        case action
          when :set
            :save

          when :get
            :view

          when :delete
            :destroy
          else
            action
        end
      end

      protected

      def permission(action, field = nil, &block)
        action = normalize_action_name(action)

        if action.is_a? Array
          action.each do |a|
            permission(a, field, &block)
          end
        elsif field and field.is_a? Array
          field.each do |f|
            permission(action, f, &block)
          end
        elsif action == :save and method_defined?(:respond_to?)
          permission([:create, :update], field, &block)
        else
          config = permissions[action] ||= {}
          raise RuntimeError, 'permission already defined' if config[field || '_']
          config[field || '_'] = block

          # flag that the class has field level permissions so other code can optimally check for them if needed
          permissions[:has_field_permissions] = true if field
        end
      end
    end
  end
end