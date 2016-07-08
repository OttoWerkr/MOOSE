--- This module contains the SCHEDULER class.
--
-- 1) @{Scheduler#SCHEDULER} class, extends @{Base#BASE}
-- =====================================================
-- The @{Scheduler#SCHEDULER} class models time events calling given event handling functions.
--
-- 1.1) SCHEDULER constructor
-- --------------------------
-- The SCHEDULER class is quite easy to use:
--
--  * @{Scheduler#SCHEDULER.New}: Setup a new scheduler and start it with the specified parameters.
--
-- 1.2) SCHEDULER timer stop and start
-- -----------------------------------
-- The SCHEDULER can be stopped and restarted with the following methods:
--
--  * @{Scheduler#SCHEDULER.Start}: (Re-)Start the scheduler.
--  * @{Scheduler#SCHEDULER.Stop}: Stop the scheduler.
--
-- @module Scheduler
-- @author FlightControl


--- The SCHEDULER class
-- @type SCHEDULER
-- @field #number ScheduleID the ID of the scheduler.
-- @extends Base#BASE
SCHEDULER = {
  ClassName = "SCHEDULER",
}

--- SCHEDULER constructor.
-- @param #SCHEDULER self
-- @param #table TimeEventObject Specified for which Moose object the timer is setup. If a value of nil is provided, a scheduler will be setup without an object reference.
-- @param #function TimeEventFunction The event function to be called when a timer event occurs. The event function needs to accept the parameters specified in TimeEventFunctionArguments.
-- @param #table TimeEventFunctionArguments Optional arguments that can be given as part of scheduler. The arguments need to be given as a table { param1, param 2, ... }.
-- @param #number StartSeconds Specifies the amount of seconds that will be waited before the scheduling is started, and the event function is called.
-- @param #number RepeatSecondsInterval Specifies the interval in seconds when the scheduler will call the event function.
-- @param #number RandomizationFactor Specifies a randomization factor between 0 and 1 to randomize the RepeatSecondsInterval.
-- @param #number StopSeconds Specifies the amount of seconds when the scheduler will be stopped.
-- @return #SCHEDULER self
function SCHEDULER:New( TimeEventObject, TimeEventFunction, TimeEventFunctionArguments, StartSeconds, RepeatSecondsInterval, RandomizationFactor, StopSeconds )
  local self = BASE:Inherit( self, BASE:New() )
  self:F2( { TimeEventObject, TimeEventFunction, TimeEventFunctionArguments, StartSeconds, RepeatSecondsInterval, RandomizationFactor, StopSeconds } )

  self.TimeEventObject = TimeEventObject
  self.TimeEventFunction = TimeEventFunction
  self.TimeEventFunctionArguments = TimeEventFunctionArguments
  self.StartSeconds = StartSeconds
  self.Repeat = false

  if RepeatSecondsInterval then
    self.RepeatSecondsInterval = RepeatSecondsInterval
  else
    self.RepeatSecondsInterval = 0
  end

  if RandomizationFactor then
    self.RandomizationFactor = RandomizationFactor
  else
    self.RandomizationFactor = 0
  end

  if StopSeconds then
    self.StopSeconds = StopSeconds
  end


  self.StartTime = timer.getTime()

  self:Start()

  return self
end

--- (Re-)Starts the scheduler.
-- @param #SCHEDULER self
-- @return #SCHEDULER self
function SCHEDULER:Start()
  self:F2( self.TimeEventObject )

  if self.RepeatSecondsInterval ~= 0 then
    self.Repeat = true
  end
  self.ScheduleID = timer.scheduleFunction( self._Scheduler, self, timer.getTime() + self.StartSeconds + .01 )

  return self
end

--- Stops the scheduler.
-- @param #SCHEDULER self
-- @return #SCHEDULER self
function SCHEDULER:Stop()
  self:F2( self.TimeEventObject )

  self.Repeat = false
  if self.ScheduleID then
    timer.removeFunction( self.ScheduleID )
  end
  self.ScheduleID = nil

  return self
end

-- Private Functions

--- @param #SCHEDULER self
function SCHEDULER:_Scheduler()
  self:F2( self.TimeEventFunctionArguments )

  local ErrorHandler = function( errmsg )

    env.info( "Error in SCHEDULER function:" .. errmsg )
    if debug ~= nil then
      env.info( debug.traceback() )
    end
    
    return errmsg
  end

  local Status, Result
  if self.TimeEventObject then
    Status, Result = xpcall( function() return self.TimeEventFunction( self.TimeEventObject, unpack( self.TimeEventFunctionArguments ) ) end, ErrorHandler )
  else
    Status, Result = xpcall( function() return self.TimeEventFunction( unpack( self.TimeEventFunctionArguments ) ) end, ErrorHandler )
  end

  self:T( { self.TimeEventFunctionArguments, Status, Result, self.StartTime, self.RepeatSecondsInterval, self.RandomizationFactor, self.StopSeconds } )

  if Status and ( ( Result == nil ) or ( Result and Result ~= false ) ) then
    if self.Repeat and ( not self.StopSeconds or ( self.StopSeconds and timer.getTime() <= self.StartTime + self.StopSeconds ) ) then
      local ScheduleTime =
        timer.getTime() +
        self.RepeatSecondsInterval +
        math.random(
          - ( self.RandomizationFactor * self.RepeatSecondsInterval / 2 ),
          ( self.RandomizationFactor * self.RepeatSecondsInterval  / 2 )
        ) +
        0.01
      self:T( { self.TimeEventFunctionArguments, "Repeat:", timer.getTime(), ScheduleTime } )
      return ScheduleTime -- returns the next time the function needs to be called.
    else
      timer.removeFunction( self.ScheduleID )
      self.ScheduleID = nil
    end
  else
    timer.removeFunction( self.ScheduleID )
    self.ScheduleID = nil
  end

  return nil
end















