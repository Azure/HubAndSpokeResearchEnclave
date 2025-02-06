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

@export()
type retentionPolicyType = {
  retentionPolicyType: 'LongTermRetentionPolicy'

  dailySchedule: {
    retentionTimes: string[]
    retentionDuration: {
      count: int
      durationType: 'Days'
    }
  }

  weeklySchedule: {
    daysOfTheWeek: ('Sunday' | 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday')[]
    retentionTimes: string[]
    retentionDuration: {
      count: int
      durationType: 'Weeks'
    }
  }?

  monthlySchedule: {
    retentionScheduleFormatType: 'Daily' | 'Weekly'
    retentionScheduleDaily: {
      daysOfTheMonth: [
        {
          date: int
          isLast: bool
        }
      ]
    }?
    retentionScheduleWeekly: {
      daysOfTheWeek: ('Sunday' | 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday')[]
      weeksOfTheMonth: ('First')[]
    }?

    retentionTimes: string[]
    retentionDuration: {
      count: int
      durationType: 'Months'
    }
  }?

  yearlySchedule: {
    retentionDuration: {
      count: int
      durationType: 'Years'
    }
    retentionTimes: string[]
    retentionScheduleFormatType: 'Weekly'
    monthsOfYear: (
      | 'January'
      | 'February'
      | 'March'
      | 'April'
      | 'May'
      | 'June'
      | 'July'
      | 'August'
      | 'September'
      | 'October'
      | 'November'
      | 'December')[]
    retentionScheduleWeekly: {
      daysOfTheWeek: ('Sunday' | 'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday')[]
      weeksOfTheMonth: ('First')[]
    }?
    retentionScheduleDaily: {
      daysOfTheMonth: [
        {
          date: int
          isLast: bool
        }
      ]
    }?
  }?
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
