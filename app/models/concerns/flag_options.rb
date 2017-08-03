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
      define_method(key) { self[:flags].include? skey }
      alias_method "#{skey}?".to_sym, key
      define_method("#{skey}!") do
        return if self[:flags].include? skey
        if new_record?
          self[:flags].push skey
        else
          with_lock do
            update flags: self[:flags] + [skey]
          end
        end
        self[:flags]
      end
      define_method("remove_#{skey}!") do
        return unless self[:flags].include? skey
        if new_record?
          self[:flags].delete skey
        else
          with_lock do
            update flags: self[:flags] - [skey]
          end
        end
        self[:flags]
      end
      alias_method "unset_#{skey}!".to_sym, "remove_#{skey}!"
    end
  end

  module InstanceMethods
    def flag!(key)
      return if self[:flags].include? key.to_s
      if new_record?
        self[:flags].push key.to_s
      else
        with_lock do
          update flags: self[:flags] + [key.to_s]
        end
      end
      self[:flags]
    end

    def unflag!(key)
      return unless self[:flags].include? key.to_s
      if new_record?
        self[:flags].delete key.to_s
      else
        with_lock do
          update flags: self[:flags] - [key.to_s]
        end
      end
      self[:flags]
    end
  end
end
