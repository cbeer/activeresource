module ActiveResource::Associations
  class Relation
    
    include Delegation

    attr_reader :klass, :loaded
    alias :model :klass
    alias :loaded? :loaded

    def initialize(klass, values = {})
      @klass  = klass
      @values = values
      @offsets = {}
      @loaded = false
    end

  end
end
