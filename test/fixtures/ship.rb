class Ship < ActiveResource::Base
  self.site = 'http://37s.sunrise.i:3000'
  belongs_to :pirate
end
