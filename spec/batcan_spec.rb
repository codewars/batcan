require 'spec_helper'
require_relative 'user'

class Group
  include Batcan::Permissible

  # for join, we don't allow :a role, and defer to default_can? for everything else
  permission :join do |group, user|
    "a role is not allowed to join" if user.role == :a
  end

  # for invite we don't allow :a role, but allow anything else
  permission :invite do |group, user|
    user.role == :a ? "a role is not allowed to invite" : true
  end

  permission :add, :members do |group, user|
    'a role cannot invite members' if user.role == :a
  end

  permission :create do |group, user|
    user.role == :b
  end

  def new_record?
    true
  end
end

describe User do
  let(:a_role) { User.new(:a) }
  let(:b_role) { User.new(:b) }
  let(:no_role) { User.new(nil) }
  let(:group) { Group.new }

  describe '#can!' do
    it 'should raise error when not permitted' do
      expect { a_role.can!(:join, group) }.to raise_error
    end

    it 'should not raise error when not permitted' do
      expect { b_role.can!(:join, group) }.not_to raise_error
    end
  end

  describe '#can?' do
    context 'basic custom permission with fallback' do
      it 'should be false if role :a' do
        expect(a_role.can?(:join, group)).to eq false
      end

      it 'should be true if any other role' do
        expect(b_role.can?(:join, group)).to eq true
      end

      it 'should be false if no role' do
        expect(no_role.can?(:join, group)).to eq false
      end
    end

    context 'basic custom permission with its own default' do
      it 'should be false if role :a' do
        expect(a_role.can?(:invite, group)).to eq false
      end

      it 'should be true if any other role' do
        expect(b_role.can?(:invite, group)).to eq true
      end

      it 'should be false if no role' do
        expect(no_role.can?(:invite, group)).to eq true
      end
    end

    context 'field level permissions' do
      it 'should not allow :a role to add members' do
        expect(a_role.can?(:add, group, field: :members)).to eq false
      end

      it 'should allow :b role to add members' do
        expect(b_role.can?(:add, group, field: :members)).to eq true
      end
    end

    context "normalize actions" do
      it 'should normalize save to create' do
        expect(b_role.can?(:save, group)).to eq true
        expect(a_role.can?(:save, group)).to eq false
      end

      it 'should normalize set to create' do
        expect(b_role.can?(:set, group)).to eq true
        expect(a_role.can?(:set, group)).to eq false
      end
    end
  end
end