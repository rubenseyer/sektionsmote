require 'rails_helper'

RSpec.describe User, type: :model do
  it 'has a valid factory' do
    build_stubbed(:user).should be_valid
  end

  let(:user) { build_stubbed(:user) }

  describe 'validations' do
    new_user = User.new
    it { new_user.should validate_presence_of(:email) }
    it { new_user.should validate_presence_of(:firstname) }
    it { new_user.should validate_presence_of(:lastname) }

    describe 'validate email as stilid@student.lu.se' do
      it 'should be valid' do
        user = build(:user, email: 'tfy16hal@student.lu.se')

        user.should be_valid
      end

      it 'should be invalid' do
        user = build(:user, email: 'hilbert.alg.237@student.lu.se')

        user.should be_invalid
      end

      it 'should be invalid' do
        user = build(:user, email: 'tfy16hal@google.lu.se')

        user.should be_invalid
      end
    end
  end

  describe 'public instance methods' do
    context 'printing' do
      it 'print_id' do
        user.print_id.should eq(%(#{user.firstname} #{user.lastname} - #{user.id}))
      end

      it 'print_email' do
        user.print_email.should eq(%(#{user.firstname} #{user.lastname} <#{user.email}>))
      end

      it 'to_s full name' do
        user.to_s.should eq(%(#{user.firstname} #{user.lastname}))
      end

      it 'to_s firstname' do
        user.lastname = nil
        user.to_s.should eq(%(#{user.firstname}))
      end

      it 'to_s email' do
        user.firstname = nil
        user.lastname = nil
        user.to_s.should eq(%(#{user.email}))
      end
    end
  end
end
