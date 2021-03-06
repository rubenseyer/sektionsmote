# frozen_string_literal: true

require 'rails_helper'
RSpec.describe VoteService do
  describe 'user_vote' do
    it 'votes' do
      user = create(:user, presence: true, votecode: 'abcd123')
      sub_item = create(:sub_item, status: :current)
      vote = create(:vote, :with_options, status: :open,
                                          choices: 1,
                                          sub_item: sub_item)
      vote_option = vote.vote_options.first

      vote_post = VotePost.new(user: user, vote: vote, votecode: 'abcd123')
      vote_post.vote_option_ids = [vote_option.id]

      expect(vote_post).to be_valid
      result = false

      expect do
        result = VoteService.user_vote(vote_post)
        vote_option.reload
      end.to change(vote_option, :count).by(1)

      expect(result).to be_truthy
      vote_post.reload
      expect(vote_post.selected).to eq(1)
    end

    # ftek: 'votes and trims votecode' not relevant since votecodes are
    # not used in our fork

    it 'votes multiple' do
      user = create(:user, presence: true, votecode: 'abcd123')
      sub_item = create(:sub_item, status: :current)
      vote = create(:vote, :with_options, status: :open,
                                          choices: 2,
                                          sub_item: sub_item)
      first_option = vote.vote_options.first
      second_option = vote.vote_options.second

      vote_post = VotePost.new(user: user, vote: vote, votecode: 'abcd123')
      vote_post.vote_option_ids = [first_option.id, second_option.id]

      expect(vote_post).to be_valid
      result = false

      expect do
        result = VoteService.user_vote(vote_post)
        first_option.reload
      end.to change(first_option, :count).by(1)

      expect(result).to be_truthy
      vote_post.reload
      expect(vote_post.selected).to eq(2)
    end

    it 'invalid vote' do
      user = create(:user, presence: true, votecode: 'abcd123')
      sub_item = create(:sub_item, status: :current)
      vote = create(:vote, :with_options, status: :open,
                                          choices: 1,
                                          sub_item: sub_item)
      # vote has 3 vote options when using :with_options
      first_option = vote.vote_options.first
      last_option = vote.vote_options.last

      vote_post = VotePost.new(user: user, vote: vote, votecode: 'abcd123')
      vote_post.vote_option_ids = [first_option.id, last_option.id]

      expect(vote_post).to_not be_valid
      result = true

      expect do
        result = VoteService.user_vote(vote_post)
        first_option.reload
      end.to change(first_option, :count).by(0)

      expect(result).to be_falsey
    end

    it 'blank vote' do
      user = create(:user, presence: true, votecode: 'abcd123')
      sub_item = create(:sub_item, status: :current)
      vote = create(:vote, status: :open, choices: 1, sub_item: sub_item)

      opt1 = create(:vote_option, vote: vote, count: 0)
      opt2 = create(:vote_option, vote: vote, count: 0)
      opt3 = create(:vote_option, vote: vote, count: 0)

      vote_post = VotePost.new(user: user, vote: vote, votecode: 'abcd123')
      expect(vote_post).to be_valid

      result = VoteService.user_vote(vote_post)
      opt1.reload
      opt2.reload
      opt3.reload
      vote_post.reload

      expect(result).to be_truthy
      expect(opt1.count).to be(0)
      expect(opt2.count).to be(0)
      expect(opt3.count).to be(0)
      expect(vote_post.selected).to be(0)
    end
  end

  describe 'presence' do
    it 'attends' do
      user = create(:user, presence: false)
      create(:sub_item, status: :current)

      result = VoteService.attends(user)
      user.reload

      expect(result).to be_truthy
      expect(user.presence).to be_truthy
    end

    it 'attends fail if no sub_items' do
      user = create(:user, presence: false)

      result = VoteService.attends(user)
      user.reload

      expect(result).to be_falsey
      expect(user.presence).to be_falsey
    end

    it 'attends fail if no current sub_item' do
      user = create(:user, presence: false)
      create(:sub_item)

      result = VoteService.attends(user)
      expect(user.errors[:base]).to \
        include(t('model.user.errors.attend_no_item'))
      user.reload

      expect(result).to be_falsey
      expect(user.presence).to be_falsey
    end

    it 'attends works if a vote is open' do
      user = create(:user, presence: false)
      sub_item = create(:sub_item, status: :current)
      create(:vote, status: :open, sub_item: sub_item)

      result = VoteService.attends(user)
      user.reload

      expect(result).to be_truthy
      expect(user.presence).to be_truthy
    end

    it 'unattends' do
      user = create(:user, presence: true)
      create(:sub_item, status: :current)

      result = VoteService.unattends(user)
      user.reload

      expect(result).to be_truthy
      expect(user.presence).to be_falsey
    end

    it 'unattends fail if current vote' do
      user = create(:user, presence: true)
      create(:vote, status: :open,
                    sub_item: create(:sub_item, status: :current))

      result = VoteService.unattends(user)
      expect(user.errors[:base]).to \
        include(I18n.t('model.user.errors.unattend_vote_current'))

      user.reload
      expect(result).to be_falsey
      expect(user.presence).to be_truthy
    end

    it 'unattends fail if no current item' do
      user = create(:user, presence: true)
      create(:sub_item, status: :closed)

      result = VoteService.unattends(user)
      expect(user.errors[:base]).to \
        include(I18n.t('model.user.errors.unattend_no_item'))
      user.reload

      expect(result).to be_falsey
      expect(user.presence).to be_truthy
    end

    it 'returns false if no user' do
      user = nil
      create(:sub_item, status: :current)

      present = VoteService.attends(user)
      not_present = VoteService.unattends(user)

      expect(present).to be_falsey
      expect(not_present).to be_falsey
      expect(user.presence).to be_falsey
    end
  end

  describe 'set_votecode' do
    it 'sets new votecode' do
      user = create(:user, votecode: 'abcd123')

      result = VoteService.set_votecode(user)
      user.reload

      expect(result).to be_truthy
      expect(user.votecode).to_not eq('abcd123')
    end

    it 'handles nil user' do
      expect(VoteService.set_votecode(nil)).to be_falsey
    end

    # ftek: 'does not work if user is not confirmed' not applicable
    # since we do not use votecodes (and the falsey return occurs
    # when failing to mail an unconfirmed email --- but this code
    # path is disabled in our fork)
  end

  describe 'votecode generator' do
    it 'creates good format' do
      expect(VoteService.votecode_generator).to match(/\A[a-z0-9]+\z/)
    end
  end

  describe 'unattend_all' do
    it 'works when votes are closed' do
      create(:vote, status: :closed)
      create(:user, presence: true)
      create(:user, presence: true)
      create(:user, presence: false)
      create(:sub_item, status: :current)

      result = VoteService.unattend_all
      expect(result).to be_truthy
      expect(User.where(presence: true).any?).to be_falsey
    end
  end
end
