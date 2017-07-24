class ApplicationSerializer < Goby::Serializer
  def credentials
    object.credentials.reject { |k, _v| k[/\Aencrypted_/] }
  end

  def settings
    object.settings.reject { |k, _v| k[/\Aencrypted_/] }
  end

  def details
    object.details.reject { |k, _v| k[/\Aencrypted_/] }
  end

  def tag_list
    object.cached_tag_list.split(/,\s?/)
  end
end
