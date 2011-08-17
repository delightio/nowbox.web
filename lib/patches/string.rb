class String
  def self.random length = 10
    letters = ('a'..'z').to_a
    (0...length).map { letters[rand 26] }.join
  end
end
