module Aji
  class Decay
    # Exponential decay
    # Rel' = Rel * exp(-k*time_diff/half_life)
    # When time_diff = half_life and Rel' = 0.5*Rel => -k = log(0.5) = -0.69314718
    def self.exponentially time_diffs, half_life=1.hour, value_at_t0=10000
      time_diffs.inject(0) do | sum, time_diff |
        next 0 unless time_diff.integer?
        sum + (value_at_t0 * Math.exp(-0.69314718*time_diff/half_life))
      end
    end
  end
end