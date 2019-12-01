module World
  PULSE = 0.25            # frequency at which the world updates in seconds
  HEARTBEAT = PULSE * 12  # 3 seconds; how often regen occurs
  ROUND = PULSE * 30      # 7.5 seconds; how often combat updates
  TICK = PULSE * 300      # 75 seconds; one mud hour
  HOUR = TICK
  DAY = HOUR * 24         # 30 minutes; one mud day
  MONTH = DAY * 35        # 17.5 hours; one mud month
  YEAR = MONTH * 17       # 12.375 days; one mud year

  CARDINAL_DIRECTIONS = %w{ north south east west up down }
end
