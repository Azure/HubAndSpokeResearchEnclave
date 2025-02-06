@export()
type iaasSchedulePolicyType = {
  schedulePolicyType: schedulePolicyType | 'SimpleSchedulePolicyV2'
  scheduleRunFrequency: scheduleRuleFrequency | 'Weekly'

  hourlySchedule: hourlySchedule?
  dailySchedule: dailySchedule?
  weeklySchedule: weeklySchedule?

  scheduleRunDays: scheduleRunDays?
  scheduleRunTimes: string[]?

  scheduleWeeklyFrequency: int?
}

@export()
type fileShareSchedulePolicyType = {
  schedulePolicyType: schedulePolicyType
  scheduleRunFrequency: scheduleRuleFrequency

  hourlySchedule: hourlySchedule?
  dailySchedule: dailySchedule?

  scheduleRunDays: scheduleRunDays?
  scheduleRunTimes: string[]?
}

type hourlySchedule = {
  interval: int
  scheduleWindowDuration: int
  scheduleWindowStartTime: string
}

type dailySchedule = {
  scheduleRunTimes: string[]
}

type weeklySchedule = {
  scheduleRunDays: scheduleRunDays
  scheduleRunTimes: string[]
}

type scheduleRunDays = ('Sunday' | 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday')[]
type scheduleRuleFrequency = 'Hourly' | 'Daily'
type schedulePolicyType = 'SimpleSchedulePolicy'
