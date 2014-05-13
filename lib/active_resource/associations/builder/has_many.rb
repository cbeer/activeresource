module ActiveResource::Associations::Builder 
  class HasMany < CollectionAssociation
    self.macro = :has_many
  end
end
