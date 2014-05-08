module ActiveResource::Associations::Builder 
  class HasOne < SingularAssociation
    self.macro = :has_one
  end
end
