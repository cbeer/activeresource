module ActiveResource::Associations::Builder 
  class SingularAssociation < Association

    def self.define_accessors(model, reflection)
      super
      define_constructors(model.generated_association_methods, reflection.name) if reflection.constructable?
    end

    # Defines the (build|create)_association methods for belongs_to or has_one association
    def self.define_constructors(mixin, name)
      silence_warnings do
        mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def build_#{name}(*args, &block)
            association(:#{name}).build(*args, &block)
          end

          def create_#{name}(*args, &block)
            association(:#{name}).create(*args, &block)
          end

          def create_#{name}!(*args, &block)
            association(:#{name}).create!(*args, &block)
          end
        CODE
      end
    end
  end
end
