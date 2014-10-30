module Batcan
  class CanResult
    attr_reader :action, :target, :field, :message, :result, :inner_can, :options

    def ok?
      @result == true
    end

    def initialize(action, target, options, result)
      @action = action
      @target = target

      # support alternative signature of using options instead of a field name
      @options = options
      @field = @options.delete(:field)

      if result.is_a? CanResult
        @inner_can = result
        @result = @inner_can.result
      else
        @result = result
      end
      @message = @result if @result.is_a? String
    end
  end
end