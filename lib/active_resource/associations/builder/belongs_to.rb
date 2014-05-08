module ActiveResource::Associations::Builder 
  class BelongsTo < SingularAssociation
    self.valid_options += [:foreign_key]

    self.macro = :belongs_to

  end
end
