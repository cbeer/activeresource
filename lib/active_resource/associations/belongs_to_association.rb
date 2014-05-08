module ActiveResource
  # = Active Record Belongs To Association
  module Associations
    class BelongsToAssociation < SingularAssociation #:nodoc:

      def find_target(opts = {})
        if owner.attributes.include?(reflection.name)
          owner.attributes[reflection.name]
        elsif owner.attributes.include?(reflection.foreign_key)
          klass.find(owner.attributes[reflection.foreign_key])
        end
      end

      def handle_dependency
        target.send(options[:dependent]) if load_target
      end

      def replace(record)
        if record
          raise_on_type_mismatch!(record)
          replace_keys(record)
          set_inverse_instance(record)
          @updated = true
        else
          remove_keys
        end

        self.target = record
      end

      def reset
        super
        @updated = false
      end

      def updated?
        @updated
      end

      private

        def find_target?
          !loaded? && foreign_key_present? && klass
        end

        # Checks whether record is different to the current target, without loading it
        def different_target?(record)
          record.id != owner.attributes[reflection.foreign_key]
        end

        def replace_keys(record)
          owner.attributes[reflection.foreign_key] = record.attributes[reflection.association_primary_key(record.class)]
        end

        def remove_keys
          owner.attributes[reflection.foreign_key] = nil
        end

        def foreign_key_present?
          owner.attributes[reflection.foreign_key]
        end

        # NOTE - for now, we're only supporting inverse setting from belongs_to back onto
        # has_one associations.
        def invertible_for?(record)
          inverse = inverse_reflection_for(record)
          inverse && inverse.macro == :has_one
        end

        def target_id
          if options[:primary_key]
            owner.send(reflection.name).try(:id)
          else
            owner.attributes[reflection.foreign_key]
          end
        end

        def stale_state
          owner.attributes[reflection.foreign_key] && owner.attributes[reflection.foreign_key].to_s
        end
    end
  end
end
