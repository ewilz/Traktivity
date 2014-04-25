class Log < ActiveRecord::Base
  validates :activity, presence: true
  validates :time_clocked_in, presence: true

  belongs_to :activity
  has_many :categories, through: :activity

  before_save :set_duration, if: Proc.new { |log| log.time_clocked_out.present? }

  def set_duration
    self.duration = calculate_duration
  end

  def calculate_duration
    hours   = (time_clocked_out.hour - time_clocked_in.hour)
    minutes = (time_clocked_out.min - time_clocked_in.min)
    (hours*60) + minutes
  end

  class << self
    def sort_by_week(date)
      Log.where(time_clocked_in: date.beginning_of_week..date.end_of_week)
    end

    def list_categories
      categories = Hash.new(0)
      logs = self.includes(:categories)
      logs.each do |log|
        log.categories.each do |category|
          categories[category.name] += (log.duration/60.0).round(2) if log.duration
        end
      end
      categories
    end

    def total_productivity
      productivity = {time_clocked_in: 0, time_clocked_out: 112}
      Log.all.each do |log|
        productivity[:time_clocked_in] += (log.duration/60.0)
        productivity[:time_clocked_out] -= (log.duration/60.0)
      end
      productivity.each do |key, value|
        productivity[value] = value.round(2)
      end
      productivity
    end

  end
end

