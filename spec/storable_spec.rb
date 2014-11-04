require 'spec_helper'
require 'sentient_user'
require 'active_model'

User = Struct.new(:role) do
  include Batcan::Canable
  include SentientUser
end

class Team
  extend ActiveModel::Naming
  include ActiveSupport::Callbacks
  include Batcan::Permissible
  include Batcan::Storable

  attr_reader :errors

  def initialize
    @errors = ActiveModel::Errors.new(self)
  end

  def to_model
    self
  end

  def valid?()      true  end
  def new_record?() true  end
  def destroyed?()  false end
  def save()        true  end
  def save!()             end
  def update_attributes!(h)end
  def destroy()     true  end
  def destroy!()          end

  permission [:save, :destroy] do |team, user|
    user.role == :b
  end
end

describe Batcan::Storable do
  let(:a_user) { User.new(:a) }
  let(:b_user) { User.new(:b) }
  let(:team) { Team.new }

  describe 'store' do
    context 'when :b role' do
      before { b_user.make_current }

      it 'should return true' do
        expect(team.store).to eq true
      end

      it 'should call save' do
        expect(team).to receive :save
        team.store
      end

      it 'should not add to errors' do
        expect(team.errors).not_to receive :add
        team.store
      end
    end

    context 'when :a role' do
      before { a_user.make_current }

      it 'should return false' do
        expect(team.store).to eq false
      end

      it 'should not call save' do
        expect(team).not_to receive :save
        team.store
      end

      it 'should add to errors' do
        expect(team.errors).to receive :add
        team.store
      end
    end
  end

  describe '#store!' do
    context 'when :b role' do
      before { b_user.make_current }

      it 'should not raise error' do
        team.store!
      end

      it 'should call save' do
        expect(team).to receive :save
        team.store
      end
    end

    context 'when :a role' do
      before { a_user.make_current }

      it 'should raise error' do
        expect { team.store! }.to raise_error
      end
    end
  end

  describe '#store_attributes!' do
    context 'when :b role' do
      before { b_user.make_current }

      it 'should not raise error' do
        team.store_attributes!(name: 'a')
      end

      it 'should call update_attributes!' do
        expect(team).to receive :update_attributes!
        team.store_attributes!(name: 'a')
      end
    end

    context 'when :a role' do
      before { a_user.make_current }

      it 'should raise error' do
        expect { team.store_attributes!(name: 'a') }.to raise_error
      end
    end
  end

  describe '#trash' do
    context 'when :b role' do
      before { b_user.make_current }

      it 'should return true' do
        expect(team.trash).to eq true
      end

      it 'should call destroy' do
        expect(team).to receive :destroy
        team.trash
      end
    end

    context 'when :a role' do
      before { a_user.make_current }

      it 'should return false' do
        expect(team.trash).to eq false
      end

      it 'should not call save' do
        expect(team).not_to receive :destroy
        team.store
      end
    end
  end

  describe '#trash!' do
    context 'when :b role' do
      before { b_user.make_current }

      it 'should not raise error' do
        team.trash!
      end

      it 'should call destroy!' do
        expect(team).to receive :destroy!
        team.trash!
      end
    end

    context 'when :a role' do
      before { a_user.make_current }

      it 'should raise error' do
        expect { team.trash! }.to raise_error
      end
    end
  end
end