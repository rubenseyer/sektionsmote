# frozen_string_literal: true

# Represent a specific voting round
class Vote < ApplicationRecord
  acts_as_paranoid
  acts_as_list(scope: :sub_item)

  belongs_to :sub_item
  has_many :audits, as: :auditable
  has_many :vote_options, dependent: :destroy
  has_many :vote_posts, dependent: :destroy

  validates :title, :status, presence: true
  validates :choices, presence: true,
                      numericality: { greater_than_or_equal_to: 1 }
  validate :only_one_open
  validate :open_on_sub_item
  accepts_nested_attributes_for :vote_options, reject_if: :all_blank,
                                               allow_destroy: true

  attr_accessor :reset
  # Only open needs to be < 0 to work with database constraint
  enum(status: { future: 0, open: -10, closed: 10 })
  scope(:position, -> { order(position: :asc) })

  before_update :update_present_users

  after_create :log_create
  after_update :log_update
  after_destroy :log_destroy

  def self.current
    Vote.where(status: :open).first
  end

  def to_s
    %(#{title} (Id: #{id}))
  end

  private

  def update_present_users
    return unless status_changed?(from: 'open', to: 'closed')
    self.present_users = User.present.count
  end

  def updater
    User.current.id if User.current && !destroyed?
  end

  def log_create
    log('create')
  end

  def log_update
    log('update') if log_changes.present?
  end

  def log_destroy
    log('destroy')
  end

  def log(action)
    Audit.create!(auditable: self, vote_id: id, audited_changes: log_changes,
                  action: action, updater_id: updater)
  end

  def log_changes
    diff = saved_changes.except(:created_at, :updated_at,
                                :deleted_at, :id,
                                :vote_options)
    diff[:reset] = '' if reset.present? && reset
    diff
  end

  def only_one_open
    return unless open? && Vote.current.present? && Vote.current != self
    errors.add(:status, I18n.t('model.vote.already_one_open'))
  end

  def open_on_sub_item
    return unless open?
    return if sub_item.present? && sub_item.current?
    errors.add(:status, I18n.t('model.vote.wrong_sub_item'))
  end
end
