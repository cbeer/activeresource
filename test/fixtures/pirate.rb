class Pirate < ActiveResource::Base
  self.site = 'http://37s.sunrise.i:3000'
  has_one :ship
  has_many :birds
end
