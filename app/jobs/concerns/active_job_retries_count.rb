module ActiveJobRetriesCount
  extend ActiveSupport::Concern

  included do
    attr_reader :retries_count
  end

  @retries_count ||= 0

  def deserialize(job_data)
    super
    @retries_count = job_data['retries_count'] || 0
  end

  def serialize
    super.merge('retries_count' => retries_count || 0)
  end

  def retry_job(options)
    @retries_count = (retries_count || 0) + 1
    super(options)
  end
end
