module ActiveResource
  module Core
    extend ActiveSupport::Concern
    
    module ClassMethods
      def initialize_generated_modules
        super

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
