module ActiveResource::Associations::Builder
  class Association #:nodoc:

    class << self
      attr_accessor :extensions
    end
    
    self.extensions = []

    # providing a Class-Variable, which will have a different store of subclasses
    class_attribute :valid_options
    self.valid_options = [:class_name, :validate]

    # would identify subclasses of association
    class_attribute :macro

    attr_reader :model, :name, :options, :klass

    def self.build(model, name, options)      
      builder = create_builder model, name, options
      reflection = builder.build
      define_accessors model, reflection
      define_callbacks model, reflection
      builder.define_extensions model
      reflection
    end
    
    def self.create_builder(model, name, options)
      new(model, name, options)
    end

    def initialize(model, name, options)
      @model, @name, @options = model, name, options
    end
    
    def define_extensions(model)
      # no-op
    end
    
    # Defines the setter and getter methods for the association
    # class Post < ActiveRecord::Base
    #   has_many :comments
    # end
    #
    # Post.first.comments and Post.first.comments= methods are defined by this method...
    def self.define_accessors(model, reflection)
      mixin = model.generated_association_methods
      name = reflection.name
      define_readers(mixin, name)
      define_writers(mixin, name)
    end
    
    def self.define_callbacks(model, reflection)
      add_before_destroy_callbacks(model, reflection) if reflection.options[:dependent]
      Association.extensions.each do |extension|
        extension.build model, reflection
      end
    end

    def self.define_readers(mixin, name)
      silence_warnings do
        mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}(*args)
            association(:#{name}).reader(*args)
          end
        CODE
      end
    end

    def self.define_writers(mixin, name)
      silence_warnings do
        mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}=(value)
            association(:#{name}).writer(value)
          end
        CODE
      end
    end

    def build
      validate_options
      model.create_reflection(self.class.macro, name, options)
    end

    private

    def validate_options
      options.assert_valid_keys(self.class.valid_options)
    end

    def self.add_before_destroy_callbacks(model, reflection)
      unless valid_dependent_options.include? reflection.options[:dependent]
        raise ArgumentError, "The :dependent option must be one of #{valid_dependent_options}, but is :#{reflection.options[:dependent]}"
      end

      name = reflection.name
      model.before_destroy lambda { |o| o.association(name).handle_dependency }
    end
  end
end
