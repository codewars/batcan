# Batcan

## Usage Example

```ruby
# simple example user. You can use PORO if you want.

User = Struct.new(:role) do
  include Batcan::Canable

  # the default ability if a more specific one is not defined
  def default_can?(action, target, options = {})
    !!role # by default if a user has any role than they are permitted
  end
end

class Team
  include Batcan::Permissible

  def members
    @members ||= []
  end

  permission :join do |team, user|
    # returning a string is like returning false (not allowed) but with a reason
    "guest role is not allowed to join" if user.role == :guest
    # if nil is returned then default_can? value will be used
  end

  permission :delete do |team, user|
    # only admins are allowed, everyone else will be dissollowed
    user.role == :admin
  end

  # field level permissions
  permission :add, :members do |team, user|
    # allow members to be added if the user is a member
    team.members.include? user
  end
end

user = User.new(:admin)
team = Team.new

user.can?(:join, team) # returns true
user.role = :guest
user.can!(:join, team) # raises an error

```


## Installation

Add this line to your application's Gemfile:

    gem 'batcan'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install batcan

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/batcan/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
