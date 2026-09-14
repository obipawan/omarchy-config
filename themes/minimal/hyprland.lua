-- Border colors follow osaka-jade's defaults: the active border uses the
-- theme accent (jade green) and the inactive border the default grey, exactly
-- as the standard theme template would generate them.
local active_border_color = { colors = { "rgba(509475ee)" }, angle = 45 }
local inactive_border_color = "rgba(595959aa)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
  decoration = {
    rounding = 6,
    rounding_power = 3,
  },
})