module ActiveResource
  module Core
    extend ActiveSupport::Concern
    
    included do
      initialize_generated_modules
    end
    
    module ClassMethods
      
      def inherited(child_class) #:nodoc:
        child_class.initialize_generated_modules
        super
      end
      
      def initialize_generated_modules
        generated_association_methods
      end

      def generated_association_methods
        @generated_association_methods ||= begin
          mod = const_set(:GeneratedAssociationMethods, Module.new)
          include mod
          mod
        end
      end
    end
      
  end
end
