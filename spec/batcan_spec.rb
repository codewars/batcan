require 'spec_helper'
require './lib/batcan'

User = Struct.new(:role) do
  include Batcan::Canable

  def default_can?(action, target, options = {})
    !!role # by default if a user has any role than they are permitted
  end
end

class Team
  include Batcan::Permissible

  permission :join do |team, user|
    "a role is not allowed to join" if user.role == :a
  end

  permission :invite do |team, user|
    next "a role is not allowed to invite" if user.role == :a
    true
  end

  permission :add, :members do |team, user|
    next 'a role cannot invite members' if user.role == :a
  end
end

describe User do
  let(:a_role) { User.new(:a) }
  let(:b_role) { User.new(:b) }
  let(:no_role) { User.new(nil) }
  let(:team) { Team.new }

  describe '#can!' do
    it 'should raise error when not permitted' do
      expect { a_role.can!(:join, team) }.to raise_error
    end

    it 'should not raise error when not permitted' do
      expect { b_role.can!(:join, team) }.not_to raise_error
    end
  end

  describe '#can?' do
    context 'basic custom permission with fallback' do
      it 'should be false if role :a' do
        expect(a_role.can?(:join, team)).to eq false
      end

      it 'should be true if any other role' do
        expect(b_role.can?(:join, team)).to eq true
      end

      it 'should be false if no role' do
        expect(no_role.can?(:join, team)).to eq false
      end
    end

    context 'basic custom permission with its own default' do
      it 'should be false if role :a' do
        expect(a_role.can?(:invite, team)).to eq false
      end

      it 'should be true if any other role' do
        expect(b_role.can?(:invite, team)).to eq true
      end

      it 'should be false if no role' do
        expect(no_role.can?(:invite, team)).to eq true
      end
    end

    context 'field level permissions' do
      it 'should not allow :a role to add members' do
        expect(a_role.can?(:add, team, field: :members)).to eq false
      end

      it 'should allow :b role to add members' do
        expect(b_role.can?(:add, team, field: :members)).to eq true
      end
    end

  end
end