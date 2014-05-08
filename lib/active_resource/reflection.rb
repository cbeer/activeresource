require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/module/deprecation'

module ActiveResource
  # = Active Resource reflection
  #
  # Associations in ActiveResource would be used to resolve nested attributes
  # in a response with correct classes.
  # Now they could be specified over Associations with the options :class_name
  module Reflection # :nodoc:
    extend ActiveSupport::Concern

    included do
      class_attribute :reflections
      self.reflections = {}
    end

    module ClassMethods
      def create_reflection(macro, name, options)
        reflection = AssociationReflection.new(macro, name, options)
        self.reflections = self.reflections.merge(name => reflection)
        reflection
      end

      # Returns the AssociationReflection object for the +association+ (use the symbol).
      #
      #   Account.reflect_on_association(:owner)             # returns the owner AssociationReflection
      #   Invoice.reflect_on_association(:line_items).macro  # returns :has_many
      #
      def reflect_on_association(association)
        reflections[association]
      end
    end

    class AssociationReflection

      def initialize(macro, name, options)
        @macro, @name, @options = macro, name, options
        @constructable = calculate_constructable(macro, options)
        @collection = :has_many == macro
      end

      # Returns the name of the macro.
      #
      # <tt>has_many :clients</tt> returns <tt>:clients</tt>
      attr_reader :name

      # Returns the macro type.
      #
      # <tt>has_many :clients</tt> returns <tt>:has_many</tt>
      attr_reader :macro

      # Returns the hash of options used for the macro.
      #
      # <tt>has_many :clients</tt> returns +{}+
      attr_reader :options


      def association_class
        case macro
        when :belongs_to
          if options[:polymorphic]
            Associations::BelongsToPolymorphicAssociation
          else
            Associations::BelongsToAssociation
          end
        when :has_many
          if options[:through]
            Associations::HasManyThroughAssociation
          else
            Associations::HasManyAssociation
          end
        when :has_one
          if options[:through]
            Associations::HasOneThroughAssociation
          else
            Associations::HasOneAssociation
          end
        end
      end
      
      # Returns a new, unsaved instance of the associated class. +attributes+ will
      # be passed to the class's constructor.
      def build_association(attributes, &block)
        klass.new(attributes, &block)
      end
      
      # Returns the class for the macro.
      #
      # <tt>has_many :clients</tt> returns the Client class
      def klass
        @klass ||= class_name.constantize
      end

      # Returns the class name for the macro.
      #
      # <tt>has_many :clients</tt> returns <tt>'Client'</tt>
      def class_name
        @class_name ||= derive_class_name
      end

      # Returns the foreign_key for the macro.
      def foreign_key
        @foreign_key ||= self.options[:foreign_key] || "#{self.name.to_s.downcase}_id"
      end
      
      def association_primary_key klass
        klass.primary_key
      end
      
      # Returns whether or not this association reflection is for a collection
      # association. Returns +true+ if the +macro+ is either +has_many+ or
      # +has_and_belongs_to_many+, +false+ otherwise.
      def collection?
        @collection
      end
      # Returns whether or not the association should be validated as part of
      # the parent's validation.
      #
      # Unless you explicitly disable validation with
      # <tt>validate: false</tt>, validation will take place when:
      #
      # * you explicitly enable validation; <tt>validate: true</tt>
      # * you use autosave; <tt>autosave: true</tt>
      # * the association is a +has_many+ association
      def validate?
        !options[:validate].nil? ? options[:validate] : (options[:autosave] == true || macro == :has_many)
      end
      
      def check_validity!
        check_validity_of_inverse!
      end

      def check_validity_of_inverse!
        unless options[:polymorphic]
          if has_inverse? && inverse_of.nil?
            raise InverseOfAssociationNotFoundError.new(self)
          end
        end
      end
      
      def has_inverse?
        inverse_name
      end

      def inverse_of
        return unless inverse_name

        @inverse_of ||= klass.reflect_on_association inverse_name
      end

      def constructable? # :nodoc:
        @constructable
      end
      private
      def calculate_constructable(macro, options)
        case macro
        when :belongs_to
          !options[:polymorphic]
        when :has_one
          !options[:through]
        else
          true
        end
      end
      def derive_class_name
        return (options[:class_name] ? options[:class_name].to_s : name.to_s).classify
      end

      def derive_foreign_key
        return options[:foreign_key] ? options[:foreign_key].to_s : "#{name.to_s.downcase}_id"
      end
              # Attempts to find the inverse association name automatically.
              # If it cannot find a suitable inverse association name, it returns
              # nil.
              def inverse_name
                options.fetch(:inverse_of) do
                  if @automatic_inverse_of == false
                    nil
                  else
                    @automatic_inverse_of ||= automatic_inverse_of
                  end
                end
              end
              
        # returns either nil or the inverse association name that it finds.
        def automatic_inverse_of
          if can_find_inverse_of_automatically?(self)
            inverse_name = ActiveSupport::Inflector.underscore(derive_class_name).to_sym

            begin
              reflection = klass.reflect_on_association(inverse_name)
            rescue NameError
              # Give up: we couldn't compute the klass type so we won't be able
              # to find any associations either.
              reflection = false
            end

            if valid_inverse_reflection?(reflection)
              return inverse_name
            end
          end

          false
        end
        
        # Checks if the inverse reflection that is returned from the
        # +automatic_inverse_of+ method is a valid reflection. We must
        # make sure that the reflection's active_record name matches up
        # with the current reflection's klass name.
        #
        # Note: klass will always be valid because when there's a NameError
        # from calling +klass+, +reflection+ will already be set to false.
        def valid_inverse_reflection?(reflection)
          reflection &&
            klass.name == reflection.derive_class_name &&
            can_find_inverse_of_automatically?(reflection)
        end
              VALID_AUTOMATIC_INVERSE_MACROS = [:has_many, :has_one, :belongs_to]
      INVALID_AUTOMATIC_INVERSE_OPTIONS = [:conditions, :through, :polymorphic, :foreign_key]


        # Checks to see if the reflection doesn't have any options that prevent
        # us from being able to guess the inverse automatically. First, the
        # <tt>inverse_of</tt> option cannot be set to false. Second, we must
        # have <tt>has_many</tt>, <tt>has_one</tt>, <tt>belongs_to</tt> associations.
        # Third, we must not have options such as <tt>:polymorphic</tt> or
        # <tt>:foreign_key</tt> which prevent us from correctly guessing the
        # inverse association.
        #
        # Anything with a scope can additionally ruin our attempt at finding an
        # inverse, so we exclude reflections with scopes.
        def can_find_inverse_of_automatically?(reflection)
          reflection.options[:inverse_of] != false &&
            VALID_AUTOMATIC_INVERSE_MACROS.include?(reflection.macro) &&
            !INVALID_AUTOMATIC_INVERSE_OPTIONS.any? { |opt| reflection.options[opt] }
        end
    end
  end
end
