module FlagOptions
  extend ActiveSupport::Concern

  included do
    extend ClassMethods
    include InstanceMethods

    scope :with_flag, -> (flag) { where("? = ANY (#{table_name}.flags)", flag) }
  end

  module ClassMethods
    def flag(key)
      skey = key.to_s
      define_method(key) { flags.include? skey }
      alias_method "#{skey}?".to_sym, key
      define_method("#{skey}!") do
        return if flags.include? skey
        if new_record?
          flags.push skey
        else
          with_lock do
            update flags: flags + [skey]
          end
        end
        flags
      end
      define_method("remove_#{skey}!") do
        return unless flags.include? skey
        if new_record?
          flags.delete skey
        else
          with_lock do
            update flags: flags - [skey]
          end
        end
        flags
      end
      alias_method "unset_#{skey}!".to_sym, "remove_#{skey}!"
    end
  end

  module InstanceMethods
    def flag!(key)
      return if flags.include? key.to_s
      if new_record?
        flags.push key.to_s
      else
        with_lock do
          update flags: flags + [key.to_s]
        end
      end
      flags
    end

    def unflag!(key)
      return unless flags.include? key.to_s
      if new_record?
        flags.delete key.to_s
      else
        with_lock do
          update flags: flags - [key.to_s]
        end
      end
      flags
    end

    def flags
      self[:flags]
    end
  end
end
