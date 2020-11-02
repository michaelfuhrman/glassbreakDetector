classdef DETECT_PERFORMANCE
  properties
    T_total
    T_Noise_LabeledNoise
    T_Noise_LabeledEvent
    T_Event_LabeledNoise
    T_Event_LabeledEvent
    FalseTriggers
    Events_Total
    Events_Missed
    Events_Latency
  end
  methods
    function obj = DETECT_PERFORMANCE()
      obj.T_total                = 0;
      obj.T_Noise_LabeledNoise   = 0;
      obj.T_Noise_LabeledEvent  = 0;
      obj.T_Event_LabeledNoise  = 0;
      obj.T_Event_LabeledEvent = 0;
      obj.FalseTriggers          = 0;
      obj.Events_Total           = 0;
      obj.Events_Missed          = 0;
      obj.Events_Latency         = [];
    end

    function obj = plus(obj1, obj2)
      obj=DETECT_PERFORMANCE();

      obj.T_total              = obj1.T_total              + obj2.T_total;
      obj.T_Noise_LabeledNoise = obj1.T_Noise_LabeledNoise + obj2.T_Noise_LabeledNoise;
      obj.T_Noise_LabeledEvent = obj1.T_Noise_LabeledEvent + obj2.T_Noise_LabeledEvent;
      obj.T_Event_LabeledNoise = obj1.T_Event_LabeledNoise + obj2.T_Event_LabeledNoise;
      obj.T_Event_LabeledEvent = obj1.T_Event_LabeledEvent + obj2.T_Event_LabeledEvent;

      obj.FalseTriggers = obj1.FalseTriggers + obj2.FalseTriggers;

      obj.Events_Total   = obj1.Events_Total  + obj2.Events_Total;
      obj.Events_Missed  = obj1.Events_Missed + obj2.Events_Missed;
      obj.Events_Latency = [obj1.Events_Latency; obj2.Events_Latency];
    end

    function FAR = FAR(obj)
      FAR = obj.T_Noise_LabeledEvent / (obj.T_Noise_LabeledEvent + obj.T_Noise_LabeledNoise);
    end

    function FRR = FRR(obj)
      FRR = obj.T_Event_LabeledNoise / (obj.T_Event_LabeledNoise + obj.T_Event_LabeledEvent);
    end

    function eventMissPercentage = EventMissPercentage(obj)
      eventMissPercentage = 100 * obj.Events_Missed / obj.Events_Total;
    end

    function MeanLatency = MeanLatency(obj)
      MeanLatency = nanmean(obj.Events_Latency);
    end

    function disp(obj)
      disp(['FAR (%): ' num2str(obj.FAR*100) '; FRR (%): ' num2str(obj.FRR*100)]);
      disp( ['# of false triggers: ' num2str(obj.FalseTriggers) ...
                                     '; Events missed (%): ' num2str(obj.EventMissPercentage)] );
      disp(['Average event latency (s): ' num2str(obj.MeanLatency)]);
    end
  end
end
