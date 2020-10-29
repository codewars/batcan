require 'sentient_user'

User = Struct.new(:role) do
  include Batcan::Canable
  include SentientUser
  def default_can?(action, target, options = {})
    !!role # by default if a user has any role than they are permitted
  end
end